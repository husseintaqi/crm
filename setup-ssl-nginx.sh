#!/bin/bash

# Setup SSL and Nginx Reverse Proxy for Twenty CRM
# This will make the CRM accessible at https://edu.automatespot.com

DOMAIN="edu.automatespot.com"
EMAIL="admin@$DOMAIN"
APP_PORT="8080"

echo "========================================="
echo "   SSL & Nginx Setup for Twenty CRM"
echo "========================================="
echo ""
echo "Domain: $DOMAIN"
echo "Email: $EMAIL"
echo ""

# Check if nginx is installed
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    apt-get update
    apt-get install -y nginx
else
    echo "✓ Nginx already installed"
fi

# Stop nginx temporarily
systemctl stop nginx

# Install Certbot if not present
if ! command -v certbot &> /dev/null; then
    echo "Installing Certbot..."
    apt-get install -y certbot python3-certbot-nginx
else
    echo "✓ Certbot already installed"
fi

# Create Nginx configuration for Twenty CRM
echo "Creating Nginx configuration..."
cat > /etc/nginx/sites-available/twenty-crm << 'NGINXCONF'
server {
    listen 80;
    listen [::]:80;
    server_name edu.automatespot.com;

    # Redirect all HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name edu.automatespot.com;

    # SSL certificates (will be added by certbot)
    # ssl_certificate /etc/letsencrypt/live/edu.automatespot.com/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/edu.automatespot.com/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 10m;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Increase client body size for file uploads
    client_max_body_size 100M;

    # Proxy settings
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        
        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint
    location /healthz {
        proxy_pass http://localhost:8080/healthz;
        access_log off;
    }
}
NGINXCONF

# Enable the site
ln -sf /etc/nginx/sites-available/twenty-crm /etc/nginx/sites-enabled/twenty-crm

# Remove default nginx site if it exists
rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
echo "Testing Nginx configuration..."
nginx -t

if [ $? -ne 0 ]; then
    echo "❌ Nginx configuration test failed!"
    exit 1
fi

# Start Nginx
echo "Starting Nginx..."
systemctl start nginx
systemctl enable nginx

# Wait a moment for Nginx to start
sleep 3

# Obtain SSL certificate
echo ""
echo "Obtaining SSL certificate from Let's Encrypt..."
echo "This may take a minute..."
echo ""

certbot --nginx -d $DOMAIN \
    --non-interactive \
    --agree-tos \
    --email $EMAIL \
    --redirect

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ SSL certificate obtained successfully!"
    
    # Setup automatic renewal
    systemctl enable certbot.timer
    systemctl start certbot.timer
    
    # Update Twenty CRM environment to use HTTPS
    echo ""
    echo "Updating Twenty CRM configuration for HTTPS..."
    cd /opt/twenty-crm
    sed -i "s|SERVER_URL=.*|SERVER_URL=https://$DOMAIN|g" .env
    sed -i "s|FRONT_BASE_URL=.*|FRONT_BASE_URL=https://$DOMAIN|g" .env
    
    # Restart Twenty CRM to apply changes
    echo "Restarting Twenty CRM..."
    docker-compose -f docker-compose-custom.yml restart server worker
    
    echo ""
    echo "========================================="
    echo "     SSL Setup Complete! 🎉"
    echo "========================================="
    echo ""
    echo "✓ Nginx is running and configured"
    echo "✓ SSL certificate installed"
    echo "✓ Auto-renewal enabled"
    echo "✓ HTTP → HTTPS redirect enabled"
    echo ""
    echo "🌐 Your CRM is now accessible at:"
    echo "   https://$DOMAIN"
    echo ""
    echo "📋 SSL Certificate Info:"
    certbot certificates
    echo ""
    echo "💡 Useful commands:"
    echo "   Check Nginx status:        systemctl status nginx"
    echo "   Reload Nginx:              systemctl reload nginx"
    echo "   Test SSL renewal:          certbot renew --dry-run"
    echo "   View SSL certificates:     certbot certificates"
    echo "   Nginx access log:          tail -f /var/log/nginx/access.log"
    echo "   Nginx error log:           tail -f /var/log/nginx/error.log"
    echo ""
else
    echo ""
    echo "❌ Failed to obtain SSL certificate"
    echo ""
    echo "This might be because:"
    echo "  1. DNS is not properly configured (check that $DOMAIN points to this server)"
    echo "  2. Port 80 is blocked by firewall"
    echo "  3. The domain is already in use by another certificate"
    echo ""
    echo "You can still access your CRM via HTTP at:"
    echo "   http://$DOMAIN"
    echo ""
    echo "To retry SSL setup later, run:"
    echo "   certbot --nginx -d $DOMAIN"
    echo ""
fi
