#!/bin/bash

# Check Docker Compose version (optional)
if ! docker-compose version | grep -q "v2.24.0"; then
  echo "Warning: Docker Compose version is below 2.24.0. Some features may not work as expected."
  echo "Consider upgrading Docker Compose for optimal results."
fi

# Generate keys and account ID
if [ ! -f "./keygen-init" ]; then
  echo "Keygen-init script not found. Building..."
else
  echo "Keygen-init script found. Skipping build."
fi
docker compose run --rm init
# Set environment variables (replace with your actual values)

# Get user input
echo "====================================="

echo "Choose an option:"
echo "1. New connection"
echo "2. Seed database"
echo "3. Reset database"
echo "====================================="
read option

# Run the corresponding Docker Compose command based on the user's choice
case $option in
  1)
    echo "Setting up new connection..."
    docker compose run --rm setup 
    ;;
  2)
    echo "Seeding database..."
    docker compose run --rm db-migrate
    ;;
  3)
    echo "Resetting database..."
    docker compose run --rm setup
    ;;
  *)
    echo "Invalid option. Please choose 1, 2, or 3."
    exit 1
    ;;
esac


export KEYGEN_ADMIN_USER="test@test.com"
export KEYGEN_ADMIN_PASS="123456"

# Start keygen.sh server (excluding setup and init services)
docker compose up --scale setup=0 --scale init=0 --scale db-migrate=0

# Copy certificates (assuming certificates are stored in /data/caddy/pki)
docker cp keygen-docker-compose-caddy-1:/data/caddy/pki ./certificates

# Import certificates to your system (manual step)
echo "Please import the certificates in the 'certificates' folder to your system to avoid browser security warnings."

# (Optional) Test the API using VS Code or your preferred method
echo "You can now test the API using VS Code or other tools."