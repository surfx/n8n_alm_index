Set-Location "D:\projetos\ia\n8n"

# Remove imagem antiga se existir
$oldImage = docker images -q n8n:custom
if ($oldImage) {
    docker rmi -f $oldImage
}

# Remove container antigo se existir
$oldContainer = docker ps -a -q -f "name=^n8n$"
if ($oldContainer) {
    docker rm -f $oldContainer
}

# Cria volume se não existir
docker volume inspect n8n_data > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    docker volume create n8n_data
}

# Limpa cache de build
docker builder prune -f

# Build da imagem
docker build -t n8n:custom .

# Run do container
docker run -d `
  --name n8n `
  -p 5678:5678 `
  -v n8n_data:/home/node/.n8n `
  -v "${PWD}/arquivos_n8n:/files" `
  n8n:custom
