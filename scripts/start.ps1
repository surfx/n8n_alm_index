Set-Location "D:\projetos\ia\n8n"

# Nome do container fixo
$ContainerName = "n8n"

# Verifica se o container existe
$containerStatus = docker ps -a `
  --filter "name=^$ContainerName$" `
  --format "{{.Status}}"

if (-not $containerStatus) {
    Write-Host "❌ Container '$ContainerName' não existe." -ForegroundColor Red
    exit 1
}

if ($containerStatus -like "Up*") {
    Write-Host "🔹 Container '$ContainerName' já está em execução. Abrindo shell..."
    docker exec -w /root/.n8n-files/arquivos -it $ContainerName sh
} else {
    Write-Host "🔹 Container '$ContainerName' está parado. Iniciando..."
    docker start $ContainerName | Out-Null
    Write-Host "🔹 Container iniciado. Abrindo shell..."
    docker exec -w /root/.n8n-files/arquivos -it $ContainerName sh
}
