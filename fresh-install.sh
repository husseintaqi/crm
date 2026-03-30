#!/bin/bash

# Complete fresh installation of Twenty CRM
cd /opt/twenty-crm

echo "========================================="
echo "   Twenty CRM - Complete Fresh Install"
echo "========================================="
echo ""

# Generate new password
NEW_DB_PASS=$(openssl rand -base64 20 | tr -d "=+/" | cut -c1-25)
APP_SECRET=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

echo "Generated new credentials..."
echo "Database Password: $NEW_DB_PASS"
echo "App Secret: $APP_SECRET"
echo ""

# Stop and remove everything
echo "Removing all existing containers and volumes..."
docker-compose -f docker-compose-custom.yml down -v 2>/dev/null || true
docker-compose -f packages/twenty-docker/docker-compose.yml down -v 2>/dev/null || true

# Remove volumes explicitly
docker volume rm twenty_db-data 2>/dev/null || true
docker volume rm twenty_server-local-data 2>/dev/null || true

# Create fresh environment file
echo "Creating fresh configuration..."
cat > .env << ENVEOF
# Server Configuration
SERVER_URL=http://edu.automatespot.com:8080
FRONT_BASE_URL=http://edu.automatespot.com:8080

# Database Configuration
PG_DATABASE_NAME=default
PG_DATABASE_USER=postgres
PG_DATABASE_PASSWORD=$NEW_DB_PASS
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
ENVEOF

# Create custom docker-compose file
echo "Creating custom docker-compose for port 8080..."
cp packages/twenty-docker/docker-compose.yml docker-compose-custom.yml
sed -i 's/"3000:3000"/"8080:3000"/g' docker-compose-custom.yml

# Start services
echo ""
echo "Starting services..."
docker-compose -f docker-compose-custom.yml up -d

# Wait for initialization
echo "Waiting for services to initialize (45 seconds)..."
for i in {1..45}; do
  printf "."
  sleep 1
done
echo ""

# Check status
echo ""
echo "Service Status:"
docker-compose -f docker-compose-custom.yml ps

echo ""
echo "Last 60 lines of server logs:"
docker-compose -f docker-compose-custom.yml logs --tail=60 server

echo ""
echo "========================================="
echo "        Deployment Complete!"
echo "========================================="
echo ""
echo "🌐 Access your CRM at:"
echo "   http://edu.automatespot.com:8080"
echo "   http://46.62.138.89:8080"
echo ""
echo "🔐 Database Password: $NEW_DB_PASS"
echo "🔐 App Secret: $APP_SECRET"
echo ""
echo "ℹ️  If the server is still starting, wait 1-2 minutes then visit the URL"
echo ""
echo "📋 Useful Commands:"
echo "   View logs:    cd /opt/twenty-crm && docker-compose -f docker-compose-custom.yml logs -f"
echo "   Restart all:  cd /opt/twenty-crm && docker-compose -f docker-compose-custom.yml restart"
echo "   Stop all:     cd /opt/twenty-crm && docker-compose -f docker-compose-custom.yml down"
echo ""
