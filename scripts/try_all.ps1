Set-Location "D:\projetos\ia\n8n\scripts"

$VOLUME_NAME = "n8n_data"
$BACKUP_DIR = "D:\backup\docker\n8n"
$BACKUP_FILE = "$BACKUP_DIR\n8n_data.tar"

# Garante diretório de backup
if (-not (Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Force -Path $BACKUP_DIR | Out-Null
}

# Remove container antigo se existir
$oldContainer = docker ps -a -q -f "name=^n8n$"
if ($oldContainer) {
    Write-Host "🗑️ Removendo container n8n..."
    docker rm -f n8n
}

# Derruba compose por garantia
docker-compose down 2>$null

# Verifica se volume existe
docker volume inspect $VOLUME_NAME > $null 2>&1
$VOLUME_EXISTS = ($LASTEXITCODE -eq 0)
$BACKUP_EXISTS = (Test-Path $BACKUP_FILE)

if ($VOLUME_EXISTS) {

    if ($BACKUP_EXISTS) {
        Write-Host "♻️ Volume existe e backup existe → restaurando backup..."

        docker volume rm $VOLUME_NAME
        docker volume create $VOLUME_NAME | Out-Null

        docker run --rm `
          -v ${VOLUME_NAME}:/volume `
          -v ${BACKUP_DIR}:/backup `
          busybox `
          sh -c "cd /volume && tar xf /backup/n8n_data.tar"

    } else {
        Write-Host "💾 Volume existe e backup não existe → criando backup..."

        docker run --rm `
          -v ${VOLUME_NAME}:/volume `
          -v ${BACKUP_DIR}:/backup `
          busybox `
          sh -c "cd /volume && tar cf /backup/n8n_data.tar ."
    }

} else {

    if ($BACKUP_EXISTS) {
        Write-Host "📥 Volume não existe e backup existe → restaurando backup..."

        docker volume create $VOLUME_NAME | Out-Null

        docker run --rm `
          -v ${VOLUME_NAME}:/volume `
          -v ${BACKUP_DIR}:/backup `
          busybox `
          sh -c "cd /volume && tar xf /backup/n8n_data.tar"

    } else {
        Write-Host "📂 Volume e backup não existem → criando volume vazio..."
        docker volume create $VOLUME_NAME | Out-Null
    }
}

# Limpa cache de build
Write-Host "🧹 Limpando cache de build..."
docker builder prune -a -f

# Garante bind mount local
if (-not (Test-Path "arquivos_n8n/requisitos/raw")) {
    New-Item -ItemType Directory -Force -Path "arquivos_n8n/requisitos/raw" | Out-Null
}

# Sobe o n8n
Write-Host "🚀 Iniciando n8n via Docker Compose..."
docker-compose up -d --build --force-recreate

Start-Sleep -Seconds 10

# Ajustes de permissão
Write-Host "🔧 Ajustando permissões..."
docker exec -u 0 n8n mkdir -p /files/requisitos/raw
docker exec -u 0 n8n chown -R node:node /files
docker exec -u 0 n8n chmod -R 777 /files

Write-Host "✅ Ambiente pronto (dados preservados)!"
