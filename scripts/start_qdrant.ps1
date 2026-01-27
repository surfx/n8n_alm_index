Set-Location "D:\projetos\ia\n8n"

# Configurações
$SecondaryContainers = @("ollama", "qdrant", "redis")
$MainContainer = "n8n"

Write-Host "--- 🛠️  Garantindo Infraestrutura ---" -ForegroundColor Cyan

# 1. Sobe os containers de apoio se estiverem parados
foreach ($name in $SecondaryContainers) {
    $status = docker ps -a --filter "name=^$name$" --format "{{.Status}}"
    
    if ($status -and ($status -notlike "Up*")) {
        Write-Host "🚀 Iniciando $name..." -NoNewline
        docker start $name | Out-Null
        Write-Host " [OK]" -ForegroundColor Green
    }
}

# 2. Lógica para o n8n
$n8nStatus = docker ps -a --filter "name=^$MainContainer$" --format "{{.Status}}"

if ($n8nStatus -notlike "Up*") {
    Write-Host "🔹 Iniciando $MainContainer..." -ForegroundColor Cyan
    docker start $MainContainer | Out-Null
    Start-Sleep -Seconds 2 # Tempo para o SO do container estabilizar
}

Write-Host "⌨️  Acessando shell (Bash Mode)..." -ForegroundColor Green
docker exec -it -e "TERM=xterm-256color" -w /home/node/.n8n-files $MainContainer /bin/bash -il

# 3. Retorno ao local dos scripts após sair do shell
Set-Location "D:\projetos\ia\n8n\scripts"