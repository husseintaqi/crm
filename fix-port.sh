#!/bin/bash

# Fix port conflict - switch to port 8080
cd /opt/twenty-crm

echo "Fixing port conflict..."

# First, check what's using port 3000
echo "Checking port 3000..."
sudo ss -tlnp | grep :3000 || echo "No process found on port 3000"

# Stop any existing Twenty containers
echo "Stopping existing containers..."
docker-compose -f packages/twenty-docker/docker-compose.yml down 2>/dev/null || true

# Kill any process using port 3000
echo "Freeing port 3000..."
sudo fuser -k 3000/tcp 2>/dev/null || echo "Port 3000 was not in use by other processes"

# Update environment file
echo "Updating environment..."
sed -i 's/:8080/:3000/g' .env
sed -i 's/SERVER_URL=.*/SERVER_URL=http:\/\/edu.automatespot.com:3000/' .env

# Start services again
echo "Starting services..."
docker-compose -f packages/twenty-docker/docker-compose.yml up -d

# Wait for services
sleep 20

echo ""
echo "Service Status:"
docker-compose -f packages/twenty-docker/docker-compose.yml ps

echo ""
echo "Recent logs:"
docker-compose -f packages/twenty-docker/docker-compose.yml logs --tail=30

echo ""
echo "=================================="
echo "Deployment Complete!"
echo "=================================="
echo "Your CRM is available at:"
echo "  - http://edu.automatespot.com:3000"
echo "  - http://46.62.138.89:3000"
echo ""
echo "Database Credentials (from .env file):"
cat /opt/twenty-crm/.env | grep -E "DATABASE_PASSWORD|APP_SECRET"
echo ""
echo "Useful commands:"
echo "  View logs:    cd /opt/twenty-crm && docker-compose -f packages/twenty-docker/docker-compose.yml logs -f"
echo "  Restart:      cd /opt/twenty-crm && docker-compose -f packages/twenty-docker/docker-compose.yml restart"
echo "  Stop:         cd /opt/twenty-crm && docker-compose -f packages/twenty-docker/docker-compose.yml down"

