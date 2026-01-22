Set-Location "D:\projetos\ia\n8n"

# Remove imagem antiga se existir
$oldImage = docker images -q n8n:custom
if ($oldImage) {
    Write-Host "🗑️ Removendo imagem antiga n8n:custom..."
    docker rmi -f $oldImage
}

# Remove container antigo se existir
$oldContainer = docker ps -a -q -f "name=^n8n$"
if ($oldContainer) {
    Write-Host "🗑️ Removendo container antigo..."
    docker rm -f $oldContainer
}

# Tenta derrubar via compose também para garantir limpeza de rede
docker-compose down 2>$null

# Cria volume se não existir
docker volume inspect n8n_data > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "📂 Criando volume n8n_data..."
    docker volume create n8n_data
}

# Limpa cache de build
Write-Host "🧹 Limpando cache de build..."
docker builder prune -a -f

# Cria diretórios locais para garantir o bind mount
if (-not (Test-Path "arquivos_n8n/requisitos/raw")) {
    New-Item -ItemType Directory -Force -Path "arquivos_n8n/requisitos/raw" | Out-Null
}

# Inicia via Docker Compose
Write-Host "🚀 Iniciando n8n via Docker Compose..."
docker-compose up -d --build --force-recreate

Write-Host "⏳ Aguardando inicialização..."
Start-Sleep -Seconds 10

# Cria estrutura e ajusta permissões
Write-Host "🔧 Criando pastas e ajustando permissões..."
docker exec -u 0 n8n mkdir -p /files/requisitos/raw
docker exec -u 0 n8n chown -R node:node /files
docker exec -u 0 n8n chmod -R 777 /files

Write-Host "✅ Ambiente pronto!"