Set-Location "D:\projetos\ia\n8n\scripts"

$VOLUME_PATH = Resolve-Path "..\arquivos_docker\n8n_data"
$BACKUP_DIR  = "D:\backup\docker\n8n"
$BACKUP_FILE = "$BACKUP_DIR\n8n_data.tar"

if (-not (Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR | Out-Null
}

Write-Host ""
Write-Host "Selecione:"
Write-Host "1 - Realizar backup do diretório de dados (n8n_data)"
Write-Host "2 - Restaurar backup no diretório de dados (n8n_data)"
Write-Host ""

$OPCAO = Read-Host "Digite 1 ou 2"

switch ($OPCAO) {

    "1" {
        Write-Host "💾 Realizando backup de '$VOLUME_PATH'..."

        if (-not (Test-Path $VOLUME_PATH)) {
             Write-Host "❌ Diretório '$VOLUME_PATH' não existe. Abortando." -ForegroundColor Red
             exit 1
        }

        docker-compose stop

        if (Test-Path $BACKUP_FILE) {
            Remove-Item $BACKUP_FILE -Force
        }

        # Monta o diretório local do host como /volume dentro do container
        docker run --rm `
          -v "${VOLUME_PATH}:/volume" `
          -v "${BACKUP_DIR}:/backup" `
          busybox `
          sh -c "cd /volume && tar cf /backup/n8n_data.tar ."

        docker-compose start

        Write-Host "✅ Backup concluído com sucesso em: $BACKUP_FILE"
    }

    "2" {
        Write-Host "📥 Restaurando backup em '$VOLUME_PATH'..."

        if (-not (Test-Path $BACKUP_FILE)) {
            Write-Host "❌ Arquivo de backup não encontrado: $BACKUP_FILE" -ForegroundColor Red
            exit 1
        }
        
        if (-not (Test-Path $VOLUME_PATH)) {
            New-Item -ItemType Directory -Force -Path $VOLUME_PATH | Out-Null
        }

        docker-compose stop

        # Limpa o diretório e extrai o tar
        docker run --rm `
          -v "${VOLUME_PATH}:/volume" `
          -v "${BACKUP_DIR}:/backup" `
          busybox `
          sh -c "rm -rf /volume/* && tar xf /backup/n8n_data.tar -C /volume && chown -R 1000:1000 /volume"

        docker-compose start

        Write-Host "✅ Backup restaurado com sucesso!"
    }

    default {
        Write-Host "❌ Opção inválida"
    }
}
