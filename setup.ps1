# Athena + Apex - Docker Setup (Windows PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "=== Athena + Apex - Docker Setup ===" -ForegroundColor Cyan

# 1. Detectar IP LAN
$HOST_IP = (
    Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.InterfaceAlias -notmatch 'Loopback|Virtual|WSL|vEthernet' -and $_.IPAddress -notmatch '^169' } |
    Select-Object -First 1
).IPAddress

if (-not $HOST_IP) {
    $HOST_IP = Read-Host "No se pudo detectar la IP. Ingresala manualmente (ej. 192.168.1.42)"
}

Write-Host "IP detectada: $HOST_IP" -ForegroundColor Green

# 2. Root .env
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
}
(Get-Content ".env") -replace "^HOST_IP=.*", "HOST_IP=$HOST_IP" | Set-Content ".env"
Write-Host "OK .env actualizado (HOST_IP=$HOST_IP)" -ForegroundColor Green

# 3. Athena .env (credenciales)
if (-not (Test-Path "athena\.env")) {
    Copy-Item "athena\.env.example" "athena\.env"
    Write-Host ""
    Write-Host "Necesitas completar las credenciales de Athena:" -ForegroundColor Yellow
    Write-Host ""
    $NOTION_TOKEN          = Read-Host "  NOTION_TOKEN (secret_...)"
    $GROQ_API_KEY          = Read-Host "  GROQ_API_KEY (gsk_...)"
    $NOTION_PARENT_PAGE_ID = Read-Host "  NOTION_PARENT_PAGE_ID"

    $athenaEnv = Get-Content "athena\.env"
    $athenaEnv = $athenaEnv -replace "^NOTION_TOKEN=.*",          "NOTION_TOKEN=$NOTION_TOKEN"
    $athenaEnv = $athenaEnv -replace "^GROQ_API_KEY=.*",          "GROQ_API_KEY=$GROQ_API_KEY"
    $athenaEnv = $athenaEnv -replace "^NOTION_PARENT_PAGE_ID=.*", "NOTION_PARENT_PAGE_ID=$NOTION_PARENT_PAGE_ID"
    $athenaEnv | Set-Content "athena\.env"
    Write-Host "OK athena\.env configurado" -ForegroundColor Green
} else {
    Write-Host "OK athena\.env ya existe - no se sobreescribio" -ForegroundColor Green
}

# 4. Apex .env
if (-not (Test-Path "apex_app\.env")) {
    Copy-Item "apex_app\.env.example" "apex_app\.env"
}
(Get-Content "apex_app\.env") -replace "^EXPO_PUBLIC_API_URL=.*", "EXPO_PUBLIC_API_URL=http://${HOST_IP}:8000" | Set-Content "apex_app\.env"
Write-Host "OK apex_app\.env actualizado (EXPO_PUBLIC_API_URL=http://${HOST_IP}:8000)" -ForegroundColor Green

# 5. Limpiar volumen obsoleto de node_modules
# El nombre del volumen depende del nombre de la carpeta del proyecto
$projectName = (Get-Item .).Name.ToLower() -replace '[^a-z0-9]', ''
$volumeName  = "${projectName}_apex_node_modules"

docker volume inspect $volumeName 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Deteniendo contenedores para liberar el volumen..."
    try { docker compose down *>$null } catch {}
    Write-Host "Eliminando volumen obsoleto de node_modules ($volumeName)..."
    try { docker volume rm $volumeName *>$null } catch {}
}

Write-Host ""
Write-Host "=== Setup completo. Ejecuta: docker compose up --build ===" -ForegroundColor Cyan
