Set-Location "D:\projetos\ia\n8n\scripts"

$VOLUME_PATH = Resolve-Path "..\arquivos_docker\n8n_data"
$BACKUP_DIR = "D:\backup\docker\n8n"
$BACKUP_FILE_VOLUME = "$BACKUP_DIR\n8n_data.tar"

# Cria diretório de backup se não existir
if (-not (Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Force -Path $BACKUP_DIR | Out-Null
}

# Remove container antigo e limpa ambiente
Write-Host "🧹 Limpando ambiente anterior..." -ForegroundColor Gray
docker-compose down 2>$null
$oldContainer = docker ps -a -q -f "name=^n8n$"
if ($oldContainer) { docker rm -f n8n | Out-Null }
docker builder prune -f

# Garante que o diretório de dados exista
if (-not (Test-Path $VOLUME_PATH)) {
    New-Item -ItemType Directory -Force -Path $VOLUME_PATH | Out-Null
}

$BACKUP_EXISTS_VOLUME = (Test-Path $BACKUP_FILE_VOLUME)
$HAS_DATA = (Get-ChildItem $VOLUME_PATH | Measure-Object).Count -gt 0

# --- LÓGICA AUTOMÁTICA DE DADOS (n8n) ---
if ($HAS_DATA) {
    if ($BACKUP_EXISTS_VOLUME) {
        Write-Host "♻️ Dados locais existem e backup existe → restaurando backup (sobrescrevendo)..." -ForegroundColor Cyan
        # Monta diretório local e restaura
        docker run --rm -v "${VOLUME_PATH}:/volume" -v "${BACKUP_DIR}:/backup" busybox sh -c "rm -rf /volume/* && tar -xf /backup/n8n_data.tar -C /volume && chown -R 1000:1000 /volume"
    } else {
        Write-Host "💾 Dados locais existem e backup não existe → criando backup..." -ForegroundColor Green
        docker run --rm -v "${VOLUME_PATH}:/volume" -v "${BACKUP_DIR}:/backup" busybox sh -c "tar -cf /backup/n8n_data.tar -C /volume ."
    }
} else {
    if ($BACKUP_EXISTS_VOLUME) {
        Write-Host "📥 Dados locais vazios e backup existe → restaurando backup..." -ForegroundColor Cyan
        docker run --rm -v "${VOLUME_PATH}:/volume" -v "${BACKUP_DIR}:/backup" busybox sh -c "tar -xf /backup/n8n_data.tar -C /volume && chown -R 1000:1000 /volume"
    } else {
        Write-Host "📂 Sem dados e sem backup → iniciando limpo..." -ForegroundColor Gray
    }
}

# --- GPU CHECK ---
Write-Host "`n🖥️ Verificando GPU NVIDIA..." -ForegroundColor Magenta
nvidia-smi

# --- INICIALIZAÇÃO ---
Write-Host "🚀 Iniciando stack via Docker Compose..." -ForegroundColor Cyan
docker-compose up -d --build --force-recreate

Start-Sleep -Seconds 10

# Ajustes de permissão internos
Write-Host "🔧 Ajustando permissões internas do n8n..." -ForegroundColor Gray
docker exec -u 0 n8n sh -c "mkdir -p /files/requisitos/raw && chown -R node:node /files && chmod -R 777 /files"

Write-Host "✅ Ambiente pronto e GPU ativa!" -ForegroundColor Green