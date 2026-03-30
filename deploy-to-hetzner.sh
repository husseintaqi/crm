#!/bin/bash

# Twenty CRM Deployment Script for Hetzner Server
# Server: 46.62.138.89 (edu.automatespot.com)

set -e  # Exit on error

DOMAIN="edu.automatespot.com"
APP_DIR="/opt/twenty-crm"
EMAIL="admin@${DOMAIN}"

echo "🚀 Twenty CRM Deployment Starting..."
echo "=================================="
echo "Domain: $DOMAIN"
echo "Installation Directory: $APP_DIR"
echo ""

# Update system
echo "📦 Updating system packages..."
apt-get update -y
apt-get install -y curl git ufw certbot

# Configure firewall
echo "🔒 Configuring firewall..."
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "🐳 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
else
    echo "✓ Docker already installed"
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "🐳 Installing Docker Compose..."
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    echo "✓ Docker Compose already installed"
fi

# Create application directory
echo "📁 Setting up application directory..."
mkdir -p $APP_DIR
cd $APP_DIR

# Clone or update repository
echo "📥 Getting application code..."
if [ -d ".git" ]; then
    echo "Updating existing repository..."
    git fetch --all
    git reset --hard origin/main
    git pull origin main
else
    echo "Cloning repository..."
    git clone https://github.com/husseintaqi/crm.git .
fi

# Generate secure secrets
echo "🔐 Generating secure secrets..."
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
APP_SECRET=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

# Create environment file
echo "⚙️  Creating environment configuration..."
cat > .env << EOF
# Server Configuration
SERVER_URL=http://$DOMAIN:3000
FRONT_BASE_URL=http://$DOMAIN:3000

# Database Configuration
PG_DATABASE_NAME=default
PG_DATABASE_USER=twenty
PG_DATABASE_PASSWORD=$DB_PASSWORD
PG_DATABASE_HOST=db
PG_DATABASE_PORT=5432

# Application Secret
APP_SECRET=$APP_SECRET

# Redis
REDIS_URL=redis://redis:6379

# Storage
STORAGE_TYPE=local

# Production mode
NODE_ENV=production

# Disable certain features in production
DISABLE_DB_MIGRATIONS=false
DISABLE_CRON_JOBS_REGISTRATION=false

# Email Configuration (optional - configure later)
# EMAIL_FROM_ADDRESS=noreply@$DOMAIN
# EMAIL_FROM_NAME=Twenty CRM
# EMAIL_DRIVER=smtp
# EMAIL_SMTP_HOST=smtp.gmail.com
# EMAIL_SMTP_PORT=587
EOF

echo "✓ Environment file created"
echo ""
echo "🔑 Database Password: $DB_PASSWORD"
echo "🔑 App Secret: $APP_SECRET"
echo "⚠️  Save these credentials securely!"
echo ""

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose -f packages/twenty-docker/docker-compose.yml down 2>/dev/null || true

# Pull latest images
echo "📥 Pulling Docker images..."
docker-compose -f packages/twenty-docker/docker-compose.yml pull

# Start services
echo "🚀 Starting Twenty CRM services..."
docker-compose -f packages/twenty-docker/docker-compose.yml up -d

# Wait for services
echo "⏳ Waiting for services to be ready (this may take 2-3 minutes)..."
sleep 10

# Show service status
echo ""
echo "✅ Service Status:"
docker-compose -f packages/twenty-docker/docker-compose.yml ps

# Show logs
echo ""
echo "📋 Recent logs:"
docker-compose -f packages/twenty-docker/docker-compose.yml logs --tail=20

echo ""
echo "🎉 Deployment Complete!"
echo "=================================="
echo "📍 Your CRM is accessible at: http://$DOMAIN:3000"
echo "📧 Configure your domain DNS to point to this server's IP"
echo ""
echo "📚 Useful commands:"
echo "  View logs:     cd $APP_DIR && docker-compose -f packages/twenty-docker/docker-compose.yml logs -f"
echo "  Restart:       cd $APP_DIR && docker-compose -f packages/twenty-docker/docker-compose.yml restart"
echo "  Stop:          cd $APP_DIR && docker-compose -f packages/twenty-docker/docker-compose.yml down"
echo "  Update:        cd $APP_DIR && git pull && docker-compose -f packages/twenty-docker/docker-compose.yml up -d"
echo ""
echo "⚠️  Next steps:"
echo "  1. Point your domain DNS A record to: 46.62.138.89"
echo "  2. Wait for DNS propagation (5-30 minutes)"
echo "  3. Access your CRM at http://$DOMAIN:3000"
echo "  4. (Optional) Set up SSL with: certbot --nginx -d $DOMAIN"
echo ""
