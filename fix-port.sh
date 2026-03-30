#!/bin/bash

# Fix port conflict - switch to port 8080
cd /opt/twenty-crm

echo "Fixing port conflict - switching to port 8080..."

# Stop any existing containers
docker-compose -f packages/twenty-docker/docker-compose.yml down 2>/dev/null || true

# Update environment file to use port 8080
sed -i 's/:3000/:8080/g' .env

# Create custom docker-compose override
cat > docker-compose.override.yml << 'EOF'
version: '3.8'

services:
  server:
    ports:
      - "8080:3000"  # Map host port 8080 to container port 3000
EOF

# Start services with override
echo "Starting services on port 8080..."
docker-compose -f packages/twenty-docker/docker-compose.yml -f docker-compose.override.yml up -d

# Wait for services
sleep 15

echo ""
echo "Service Status:"
docker-compose -f packages/twenty-docker/docker-compose.yml ps

echo ""
echo "Deployment fixed!"
echo "Your CRM is now available at: http://edu.automatespot.com:8080"
echo "Or directly at: http://46.62.138.89:8080"
