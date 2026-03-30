#!/bin/bash

# Fix database authentication
cd /opt/twenty-crm

echo "Fixing database authentication..."

# Stop containers
docker-compose -f docker-compose-custom.yml down

# Fix the environment file
cat > .env << 'ENVEOF'
# Server Configuration
SERVER_URL=http://edu.automatespot.com:8080
FRONT_BASE_URL=http://edu.automatespot.com:8080

# Database Configuration - MUST match postgres service settings
PG_DATABASE_NAME=default
PG_DATABASE_USER=postgres
PG_DATABASE_PASSWORD=WFQ7cTIbLTFGoHNZI2oallPg3
PG_DATABASE_HOST=db
PG_DATABASE_PORT=5432

# Application Secret
APP_SECRET=u4hjMWT5wInqQduLdQPphOkf2SsBoZCu

# Redis
REDIS_URL=redis://redis:6379

# Storage
STORAGE_TYPE=local

# Production mode
NODE_ENV=production
ENVEOF

# Recreate custom docker-compose
cp packages/twenty-docker/docker-compose.yml docker-compose-custom.yml
sed -i 's/"3000:3000"/"8080:3000"/g' docker-compose-custom.yml

echo "Starting services with correct configuration..."
docker-compose -f docker-compose-custom.yml up -d

echo "Waiting for startup (30 seconds)..."
sleep 30

echo ""
echo "Service Status:"
docker-compose -f docker-compose-custom.yml ps

echo ""
echo "Server logs (last 50 lines):"
docker-compose -f docker-compose-custom.yml logs --tail=50 server

echo ""
echo "========================================="
echo "   Twenty CRM Deployment Complete!"
echo "========================================="
echo ""
echo "🌐 Access URLs:"
echo "   http://edu.automatespot.com:8080"
echo "   http://46.62.138.89:8080"
echo ""
echo "🔐 Credentials saved in: /opt/twenty-crm/.env"
echo ""
echo "📋 Management Commands:"
echo "   Logs:    docker-compose -f /opt/twenty-crm/docker-compose-custom.yml logs -f"
echo "   Restart: docker-compose -f /opt/twenty-crm/docker-compose-custom.yml restart"
echo "   Stop:    docker-compose -f /opt/twenty-crm/docker-compose-custom.yml down"
echo ""
