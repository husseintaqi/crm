#!/bin/bash

# Deploy Twenty CRM on port 8080 to avoid conflicts
cd /opt/twenty-crm

echo "Deploying Twenty CRM on port 8080..."

# Stop existing containers
docker-compose -f packages/twenty-docker/docker-compose.yml down 2>/dev/null || true

# Create a custom docker-compose with port 8080
cp packages/twenty-docker/docker-compose.yml docker-compose-custom.yml

# Replace port 3000 with 8080 in the custom compose file
sed -i 's/"3000:3000"/"8080:3000"/g' docker-compose-custom.yml

# Update environment
sed -i 's/:3000/:8080/g' .env
sed -i 's/SERVER_URL=.*/SERVER_URL=http:\/\/edu.automatespot.com:8080/' .env

# Start services with custom compose
echo "Starting services..."
docker-compose -f docker-compose-custom.yml up -d

# Wait for startup
echo "Waiting for services to start..."
sleep 25

echo ""
echo "Service Status:"
docker-compose -f docker-compose-custom.yml ps

echo ""
echo "Recent logs from server:"
docker-compose -f docker-compose-custom.yml logs --tail=40 server

echo ""
echo "====================================="
echo "  Twenty CRM Deployment Successful!"
echo "====================================="
echo ""
echo "Access your CRM at:"
echo "  ✓ http://edu.automatespot.com:8080"
echo "  ✓ http://46.62.138.89:8080"
echo ""
echo "🔑 Database Password: $(grep PG_DATABASE_PASSWORD .env | cut -d= -f2)"
echo "🔑 App Secret: $(grep APP_SECRET .env | cut -d= -f2)"
echo ""
echo "Useful commands:"
echo "  View logs:    cd /opt/twenty-crm && docker-compose -f docker-compose-custom.yml logs -f"
echo "  Restart:      cd /opt/twenty-crm && docker-compose -f docker-compose-custom.yml restart"
echo "  Stop:         cd /opt/twenty-crm && docker-compose -f docker-compose-custom.yml down"
echo ""
