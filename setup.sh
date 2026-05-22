#!/usr/bin/env bash
set -e

echo "=== Athena + Apex — Docker Setup ==="

# ── 1. Detect LAN IP ─────────────────────────────────────────────────────────
HOST_IP=$(ipconfig getifaddr en0 2>/dev/null \
  || ipconfig getifaddr en1 2>/dev/null \
  || ip route get 1 2>/dev/null | awk '{print $7; exit}' \
  || echo "")

if [ -z "$HOST_IP" ]; then
  echo "No se pudo detectar la IP automáticamente."
  read -p "Ingresa tu IP de red local (ej. 192.168.1.42): " HOST_IP
fi

echo "IP detectada: $HOST_IP"

# ── 2. Root .env (HOST_IP para docker-compose) ───────────────────────────────
if [ ! -f ".env" ]; then
  cp .env.example .env
fi
# Update HOST_IP whether or not the file existed
sed -i.bak "s|^HOST_IP=.*|HOST_IP=$HOST_IP|" .env && rm -f .env.bak
echo "✓ .env actualizado (HOST_IP=$HOST_IP)"

# ── 3. Athena .env (credenciales del backend) ─────────────────────────────────
if [ ! -f "athena/.env" ]; then
  cp athena/.env.example athena/.env
  echo ""
  echo "Necesitas completar las credenciales en athena/.env:"
  echo ""
  read -p "  NOTION_TOKEN (secret_...): " NOTION_TOKEN
  read -p "  GROQ_API_KEY (gsk_...):    " GROQ_API_KEY
  read -p "  NOTION_PARENT_PAGE_ID:     " NOTION_PARENT_PAGE_ID
  sed -i.bak \
    -e "s|^NOTION_TOKEN=.*|NOTION_TOKEN=$NOTION_TOKEN|" \
    -e "s|^GROQ_API_KEY=.*|GROQ_API_KEY=$GROQ_API_KEY|" \
    -e "s|^NOTION_PARENT_PAGE_ID=.*|NOTION_PARENT_PAGE_ID=$NOTION_PARENT_PAGE_ID|" \
    athena/.env && rm -f athena/.env.bak
  echo "✓ athena/.env configurado"
else
  echo "✓ athena/.env ya existe — no se sobreescribió"
fi

# ── 4. Apex .env (para desarrollo local sin Docker) ──────────────────────────
if [ ! -f "apex_app/.env" ]; then
  cp apex_app/.env.example apex_app/.env
fi
# Siempre actualizar la URL — cambia con cada red Wi-Fi/hotspot
sed -i.bak "s|^EXPO_PUBLIC_API_URL=.*|EXPO_PUBLIC_API_URL=http://$HOST_IP:8000|" apex_app/.env && rm -f apex_app/.env.bak
echo "✓ apex_app/.env actualizado (EXPO_PUBLIC_API_URL=http://$HOST_IP:8000)"

# ── 5. Limpiar volumen de node_modules si existe (evita versiones obsoletas) ──
if docker volume inspect school_apex_node_modules &>/dev/null; then
  echo "Eliminando volumen obsoleto de node_modules..."
  docker volume rm school_apex_node_modules 2>/dev/null || true
fi

echo ""
echo "=== Setup completo. Ejecuta: docker compose up --build ==="
