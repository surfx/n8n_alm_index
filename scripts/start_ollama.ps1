Set-Location "D:\projetos\ia\n8n"

$ContainerName = "ollama"

# Verifica o status
$containerStatus = docker ps -a --filter "name=^$ContainerName$" --format "{{.Status}}"

if (-not $containerStatus) {
    Write-Host "❌ Container '$ContainerName' não existe." -ForegroundColor Red
    exit 1
}

if ($containerStatus -notlike "Up*") {
    Write-Host "🔹 Container '$ContainerName' está parado. Iniciando..." -ForegroundColor Cyan
    docker start $ContainerName | Out-Null
    # Aguarda 2 segundos para garantir que o driver NVIDIA carregue no container
    Start-Sleep -Seconds 2
}

Write-Host "🚀 Verificando GPU na RTX 4090..." -ForegroundColor Green
docker exec -it $ContainerName nvidia-smi

Set-Location "D:\projetos\ia\n8n\scripts"