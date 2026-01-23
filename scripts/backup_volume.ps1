Set-Location "D:\projetos\ia\n8n\scripts"

$VOLUME_NAME = "n8n_data"
$BACKUP_DIR  = "D:\backup\docker\n8n"
$BACKUP_FILE = "$BACKUP_DIR\n8n_data.tar"

if (-not (Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR | Out-Null
}

Write-Host ""
Write-Host "Selecione:"
Write-Host "1 - Realizar backup do volume"
Write-Host "2 - Restaurar backup do volume"
Write-Host ""

$OPCAO = Read-Host "Digite 1 ou 2"

switch ($OPCAO) {

    "1" {
        Write-Host "💾 Realizando backup do volume..."

        docker volume inspect $VOLUME_NAME > $null 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Volume '$VOLUME_NAME' não existe. Abortando." -ForegroundColor Red
            exit 1
        }

        docker-compose stop

        if (Test-Path $BACKUP_FILE) {
            Remove-Item $BACKUP_FILE -Force
        }

        docker run --rm `
          -v ${VOLUME_NAME}:/volume `
          -v ${BACKUP_DIR}:/backup `
          busybox `
          sh -c "cd /volume && tar cf /backup/n8n_data.tar ."

        docker-compose start

        Write-Host "✅ Backup concluído com sucesso!"
    }

    "2" {
        Write-Host "📥 Restaurando backup do volume..."

        if (-not (Test-Path $BACKUP_FILE)) {
            Write-Host "❌ Backup não encontrado" -ForegroundColor Red
            exit 1
        }

        docker-compose stop

        docker run --rm `
          -v ${VOLUME_NAME}:/volume `
          -v ${BACKUP_DIR}:/backup `
          busybox `
          sh -c "rm -rf /volume/* && tar xf /backup/n8n_data.tar -C /volume && chown -R 1000:1000 /volume"

        docker-compose start

        Write-Host "✅ Backup restaurado com sucesso!"
    }

    default {
        Write-Host "❌ Opção inválida"
    }
}
