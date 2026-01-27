Set-Location "D:\projetos\ia\n8n"

# Lista de containers secundários (apenas para subir)
$SecondaryContainers = @("ollama", "qdrant", "redis")
$N8NContainer = "n8n"

Write-Host "--- Verificando Infraestrutura ---" -ForegroundColor Cyan

# 1. Garante que os containers de apoio estejam rodando
foreach ($name in $SecondaryContainers) {
    $status = docker ps -a --filter "name=^$name$" --format "{{.Status}}"
    
    if (-not $status) {
        Write-Warning "⚠️ Container '$name' não encontrado no Docker."
        continue
    }

    if ($status -notlike "Up*") {
        Write-Host "🚀 Iniciando $name..." -NoNewline
        docker start $name | Out-Null
        Write-Host " [OK]" -ForegroundColor Green
    } else {
        Write-Host "✅ $name já está operacional." -ForegroundColor Gray
    }
}

Write-Host "`n--- Acessando n8n ---" -ForegroundColor Cyan

# 2. Lógica principal para o n8n e entrada no shell
$n8nStatus = docker ps -a --filter "name=^$N8NContainer$" --format "{{.Status}}"

if (-not $n8nStatus) {
    Write-Host "❌ Container '$N8NContainer' não existe." -ForegroundColor Red
    exit 1
}

if ($n8nStatus -notlike "Up*") {
    Write-Host "🔹 Iniciando $N8NContainer..."
    docker start $N8NContainer | Out-Null
}

Write-Host "🔹 Abrindo shell no n8n..."
docker exec -w /home/node/.n8n-files/ -it $N8NContainer sh

# 3. Retorna ao local dos scripts após sair do shell
Set-Location "D:\projetos\ia\n8n\scripts"