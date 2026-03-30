#!/bin/bash

# Setup SSL and Nginx Reverse Proxy for Twenty CRM
DOMAIN="edu.automatespot.com"
EMAIL="admin@$DOMAIN"

echo "========================================="
echo "   SSL & Nginx Setup for Twenty CRM"
echo "========================================="
echo ""

# Install packages
apt-get update
apt-get install -y nginx certbot python3-certbot-nginx

# Stop nginx and any service using port 80
systemctl stop nginx
fuser -k 80/tcp 2>/dev/null || true

# Get SSL certificate using standalone mode
echo "Obtaining SSL certificate..."
certbot certonly --standalone -d $DOMAIN \
    --non-interactive \
    --agree-tos \
    --email $EMAIL

if [ $? -ne 0 ]; then
    echo "❌ Failed to obtain SSL certificate"
    echo "Make sure DNS points to this server and port 80 is accessible"
    exit 1
fi

# Now create Nginx config with SSL
echo "Creating Nginx configuration with SSL..."
cat > /etc/nginx/sites-available/twenty-crm << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name edu.automatespot.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name edu.automatespot.com;

    ssl_certificate /etc/letsencrypt/live/edu.automatespot.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/edu.automatespot.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    client_max_body_size 100M;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/twenty-crm /etc/nginx/sites-enabled/twenty-crm
rm -f /etc/nginx/sites-enabled/default

# Test and start Nginx
nginx -t && systemctl start nginx && systemctl enable nginx

# Setup auto-renewal
systemctl enable certbot.timer && systemctl start certbot.timer

# Update Twenty CRM config
cd /opt/twenty-crm
sed -i "s|SERVER_URL=.*|SERVER_URL=https://$DOMAIN|g" .env
sed -i "s|FRONT_BASE_URL=.*|FRONT_BASE_URL=https://$DOMAIN|g" .env
docker-compose -f docker-compose-custom.yml restart server worker

echo ""
echo "========================================="
echo "         Setup Complete! ✓"
echo "========================================="
echo ""
echo "Your CRM is now accessible at:"
echo "  https://$DOMAIN"
echo ""

