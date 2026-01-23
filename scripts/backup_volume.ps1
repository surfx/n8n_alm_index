Set-Location "D:\projetos\ia\n8n\scripts"

$VOLUME_NAME = "n8n_data"
$BACKUP_DIR  = "D:\backup\docker\n8n"
$BACKUP_FILE_VOLUME = "$BACKUP_DIR\n8n_data.tar"

# Pastas locais (bind mounts)
$DATA_FOLDERS = @("qdrant_data", "ollama_data")

# Cria a pasta de backup se não existir
if (-not (Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR | Out-Null
}

Write-Host ""
Write-Host "Selecione:"
Write-Host "1 - Realizar backup completo (volume + pastas)"
Write-Host "2 - Restaurar backup completo (volume + pastas)"
Write-Host ""

$OPCAO = Read-Host "Digite 1 ou 2"

switch ($OPCAO) {

    "1" {
        Write-Host "💾 Realizando backup do volume e pastas..."

        # Verifica se o volume existe
        docker volume inspect $VOLUME_NAME > $null 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Volume '$VOLUME_NAME' não existe. Abortando." -ForegroundColor Red
            exit 1
        }

        Write-Host "🛑 Parando serviços..."
        docker-compose stop

        # --- Backup do volume ---
        if (Test-Path $BACKUP_FILE_VOLUME) {
            Remove-Item $BACKUP_FILE_VOLUME -Force
        }
        docker run --rm `
          -v ${VOLUME_NAME}:/volume `
          -v ${BACKUP_DIR}:/backup `
          busybox `
          sh -c "tar -cvf /backup/n8n_data.tar -C /volume ."

        # --- Backup das pastas locais ---
        foreach ($folder in $DATA_FOLDERS) {
            $backup_file = "$BACKUP_DIR\$folder.tar"
            if (Test-Path $backup_file) { Remove-Item $backup_file -Force }
            if (Test-Path "..\$folder") {
                Write-Host "📂 Gerando backup da pasta: $folder"
                tar -cvf $backup_file "..\$folder"
            } else {
                Write-Host "⚠️ Pasta $folder não encontrada, pulando..." -ForegroundColor Yellow
            }
        }

        Write-Host "🚀 Reiniciando serviços..."
        docker-compose start

        Write-Host "✅ Backup completo finalizado em $BACKUP_DIR"
    }

    "2" {
        Write-Host "📥 Restaurando backup do volume e pastas..."

        Write-Host "🛑 Parando serviços..."
        docker-compose stop

        # --- Restaurar volume ---
        if (Test-Path $BACKUP_FILE_VOLUME) {
            docker run --rm `
              -v ${VOLUME_NAME}:/volume `
              -v ${BACKUP_DIR}:/backup `
              busybox `
              sh -c "rm -rf /volume/* && tar -xvf /backup/n8n_data.tar -C /volume && chown -R 1000:1000 /volume"
            Write-Host "✅ Volume $VOLUME_NAME restaurado"
        } else {
            Write-Host "⚠️ Backup do volume não encontrado, pulando..." -ForegroundColor Yellow
        }

        # --- Restaurar pastas locais ---
        foreach ($folder in $DATA_FOLDERS) {
            $backup_file = "$BACKUP_DIR\$folder.tar"
            if (Test-Path $backup_file) {
                Write-Host "📂 Restaurando pasta: $folder"
                tar -xvf $backup_file -C ".."
            } else {
                Write-Host "⚠️ Backup da pasta $folder não encontrado, pulando..." -ForegroundColor Yellow
            }
        }

        Write-Host "🚀 Reiniciando serviços..."
        docker-compose start

        Write-Host "✅ Restauração completa finalizada!"
    }

    default {
        Write-Host "❌ Opção inválida"
    }
}
