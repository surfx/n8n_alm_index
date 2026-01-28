# Define a raiz do projeto baseada na localização deste script
$PROJECT_ROOT = Resolve-Path "$PSScriptRoot\.."
Set-Location $PROJECT_ROOT

# --- 1. LIMPEZA DE AMBIENTE ---
Write-Host "🧹 Limpando ambiente anterior..." -ForegroundColor Gray
docker-compose down 2>$null
$oldContainer = docker ps -a -q -f "name=^n8n$"
if ($oldContainer) { docker rm -f n8n | Out-Null }
#docker builder prune -f # deleta tb outros containers...
docker-compose rm -f


# --- 2. GPU CHECK ---
Write-Host "`n🖥️ Verificando GPU NVIDIA..." -ForegroundColor Magenta
nvidia-smi

# --- 3. INICIALIZAÇÃO DOS SERVIÇOS CORE ---
Write-Host "🚀 Iniciando serviços principais via Docker Compose..." -ForegroundColor Cyan
# docker-compose up -d --build --force-recreate # - limpa tudo
docker-compose up -d        # reutiliza libs

# Aguarda um pouco para os serviços subirem antes dos comandos de exec
Write-Host "⏳ Aguardando serviços estabilizarem (10s)..." -ForegroundColor Gray
Start-Sleep -Seconds 10

# --- 4. CONFIGURAÇÃO INTERNA: n8n (Permissões, Pastas e Usuário Owner) ---
Write-Host "🔧 Ajustando permissões e configurando conta do proprietário..." -ForegroundColor Gray

# Ajusta permissões e pastas
docker exec -u 0 n8n sh -c "mkdir -p /files/requisitos/raw && chown -R node:node /files /home/node/.n8n && chmod -R 777 /files"

# Cria o usuário Owner automaticamente para pular a tela de Setup
# Nota: Só funcionará se o banco de dados estiver limpo (primeira execução)
docker exec n8n bash -c "n8n user-management:create --email 'eme.vbnet@gmail.com' --password 'X!qr3VvYt2aR@En' --firstName 'Emerson' --lastName 'Silva' --role 'owner'" 2>$null

Write-Host "✅ Usuário proprietário configurado (ou já existente)." -ForegroundColor Green

# --- 5. CONFIGURAÇÃO INTERNA: OLLAMA (Pull de Modelos) ---
Write-Host "🧠 Baixando modelos no Ollama (isso pode demorar)..." -ForegroundColor Magenta
docker exec ollama ollama pull nomic-embed-text
docker exec ollama ollama pull llama3.1

# --- 6. CONFIGURAÇÃO INTERNA: QDRANT (Criação de Coleção) ---
Write-Host "🔍 Verificando coleção no Qdrant..." -ForegroundColor Blue
$QDRANT_URL = "http://localhost:6333/collections/collection_rag_alm"

try {
    # Tenta verificar se a coleção existe
    Invoke-WebRequest -Uri $QDRANT_URL -Method Get -ErrorAction Stop | Out-Null
    Write-Host "✅ Coleção 'collection_rag_alm' já existe." -ForegroundColor Gray
} catch {
    Write-Host "🆕 Coleção não encontrada. Criando..." -ForegroundColor Yellow
    $body = @{
        vectors = @{
            size = 768
            distance = "Cosine"
        }
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri $QDRANT_URL -Method Put -Body $body -ContentType "application/json" | Out-Null
    Write-Host "✅ Coleção criada com sucesso!" -ForegroundColor Green
}

# --- 7. LIMPEZA FINAL ---
Write-Host "🧹 Removendo containers residuais..." -ForegroundColor Gray
# docker container prune -f | Out-Null # deleta tb outros containers...
docker-compose rm -f

Write-Host "`n✨ Ambiente pronto e organizado!" -ForegroundColor Green
Write-Host "Acesse n8n em: http://localhost:5678" -ForegroundColor White

Set-Location $PROJECT_ROOT\scripts