#!/usr/bin/env bash
# ==============================================================================
# OpenShorts Production One-Click Deployment Script for Ubuntu / Debian / OCI VM
# ==============================================================================
set -euo pipefail

echo "=========================================="
echo "🚀 OpenShorts Production Deployment"
echo "=========================================="

# 1. Check and install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "📦 Installing Docker and Docker Compose plugin..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm -f get-docker.sh
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER" || true
    echo "✅ Docker installed successfully."
fi

# 2. Check for docker compose support
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "📦 Installing docker-compose-plugin..."
    sudo apt-get update && sudo apt-get install -y docker-compose-plugin
    COMPOSE_CMD="docker compose"
fi

# 3. Ensure .env exists
if [ ! -f .env ]; then
    if [ -f .env.production.example ]; then
        echo "⚠️ .env not found. Copying .env.production.example to .env..."
        cp .env.production.example .env
        echo "📝 Please review and update .env with your domain and API keys."
    else
        touch .env
    fi
fi

# 4. Create required persistent data directories
mkdir -p output uploads
chmod 777 output uploads

# 5. Build and start containers
echo "🔨 Building and launching OpenShorts production containers..."
$COMPOSE_CMD -f docker-compose.prod.yml up --build -d

# 6. Wait for health checks
echo "⏳ Waiting for services to become healthy..."
sleep 10

echo "🔍 Verifying backend health..."
for i in {1..12}; do
    if curl -sf http://127.0.0.1:8000/health/ready > /dev/null; then
        echo "✅ Backend is healthy and ready!"
        break
    fi
    echo "Waiting for backend ($i/12)..."
    sleep 5
done

echo "🔍 Verifying Remotion renderer health..."
for i in {1..12}; do
    if curl -sf http://127.0.0.1:3100/health > /dev/null; then
        echo "✅ Remotion renderer is healthy!"
        break
    fi
    echo "Waiting for renderer ($i/12)..."
    sleep 5
done

echo "=========================================="
echo "🎉 OpenShorts services are running!"
echo "Check container status with: $COMPOSE_CMD -f docker-compose.prod.yml ps"
echo "Check live logs with:       $COMPOSE_CMD -f docker-compose.prod.yml logs -f"
echo "=========================================="
