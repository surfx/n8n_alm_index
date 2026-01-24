Set-Location "D:\projetos\ia\n8n\scripts"

$VOLUME_NAME = "n8n_data"
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

# Verifica se volume e backup existem
docker volume inspect $VOLUME_NAME > $null 2>&1
$VOLUME_EXISTS = ($LASTEXITCODE -eq 0)
$BACKUP_EXISTS_VOLUME = (Test-Path $BACKUP_FILE_VOLUME)

# --- LÓGICA AUTOMÁTICA DE VOLUME (n8n) ---
if ($VOLUME_EXISTS) {
    if ($BACKUP_EXISTS_VOLUME) {
        Write-Host "♻️ Volume existe e backup existe → restaurando backup..." -ForegroundColor Cyan
        docker volume rm $VOLUME_NAME | Out-Null
        docker volume create $VOLUME_NAME | Out-Null
        docker run --rm -v ${VOLUME_NAME}:/volume -v ${BACKUP_DIR}:/backup busybox sh -c "tar -xf /backup/n8n_data.tar -C /volume"
    } else {
        Write-Host "💾 Volume existe e backup não existe → criando backup..." -ForegroundColor Green
        docker run --rm -v ${VOLUME_NAME}:/volume -v ${BACKUP_DIR}:/backup busybox sh -c "tar -cf /backup/n8n_data.tar -C /volume ."
    }
} else {
    if ($BACKUP_EXISTS_VOLUME) {
        Write-Host "📥 Volume não existe e backup existe → restaurando backup..." -ForegroundColor Cyan
        docker volume create $VOLUME_NAME | Out-Null
        docker run --rm -v ${VOLUME_NAME}:/volume -v ${BACKUP_DIR}:/backup busybox sh -c "tar -xf /backup/n8n_data.tar -C /volume"
    } else {
        Write-Host "📂 Volume e backup não existem → criando volume vazio..." -ForegroundColor Gray
        docker volume create $VOLUME_NAME | Out-Null
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