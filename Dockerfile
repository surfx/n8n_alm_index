FROM docker.n8n.io/n8nio/n8n

# Variáveis de ambiente
ENV GENERIC_TIMEZONE=America/Fortaleza
ENV TZ=America/Fortaleza
ENV N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
ENV N8N_RUNNERS_ENABLED=true

# Volume persistente
VOLUME ["/home/node/.n8n"]

# Porta usada pelo n8n
EXPOSE 5678
