Set-Location "D:\projetos\ia\n8n"

$VOLUME_NAME = "n8n_data"
$BACKUP_DIR  = "D:\backup\docker\n8n"
$BACKUP_FILE = "$BACKUP_DIR\n8n_data.tar"

# Garante que o diretório de backup existe
if (-not (Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR | Out-Null
}

docker-compose down 2>$null

Write-Host ""
Write-Host "Selecione:"
Write-Host "1 - Realizar backup do volume"
Write-Host "2 - Restaurar backup do volume"
Write-Host ""

$OPCAO = Read-Host "Digite 1 ou 2"

switch ($OPCAO) {

    "1" {
        Write-Host "💾 Realizando backup do volume..."

        # Verifica se o volume existe
        docker volume inspect $VOLUME_NAME > $null 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Volume '$VOLUME_NAME' não existe. Abortando." -ForegroundColor Red
            exit 1
        }

        # Remove backup antigo se existir
        if (Test-Path $BACKUP_FILE) {
            Write-Host "♻️ Removendo backup antigo..."
            Remove-Item $BACKUP_FILE -Force
        }

        docker run --rm `
          -v ${VOLUME_NAME}:/volume `
          -v ${BACKUP_DIR}:/backup `
          busybox `
          sh -c "cd /volume && tar cf /backup/n8n_data.tar ."

        Write-Host "✅ Backup concluído com sucesso!"
    }

    "2" {
        Write-Host "📥 Restaurando backup do volume..."

        if (-not (Test-Path $BACKUP_FILE)) {
            Write-Host "❌ Backup não encontrado em $BACKUP_FILE" -ForegroundColor Red
            exit 1
        }

        # Remove volume antigo se existir
        docker volume inspect $VOLUME_NAME > $null 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "♻️ Removendo volume antigo..."
            docker volume rm $VOLUME_NAME | Out-Null
        }

        docker volume create $VOLUME_NAME | Out-Null

        docker run --rm `
          -v ${VOLUME_NAME}:/volume `
          -v ${BACKUP_DIR}:/backup `
          busybox `
          sh -c "cd /volume && tar xf /backup/n8n_data.tar"

        Write-Host "✅ Backup restaurado com sucesso!"
    }

    default {
        Write-Host "❌ Opção inválida. Execute o script novamente." -ForegroundColor Red
        exit 1
    }
}