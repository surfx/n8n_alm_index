FROM n8nio/n8n:latest
USER root
RUN wget -q https://gitlab.alpinelinux.org/api/v4/projects/5/packages/generic/v2.14.4/x86_64/apk.static && \
    chmod +x apk.static && \
   ./apk.static -X http://dl-cdn.alpinelinux.org/alpine/v3.21/main -U --allow-untrusted --initdb add apk-tools && \
    rm apk.static

RUN apk add --no-cache python3 py3-pip build-base python3-dev \
    libmagic poppler-utils \
    tesseract-ocr tesseract-ocr-data-por tesseract-ocr-data-eng \
    libxml2-dev libxslt-dev antiword
RUN pip install --break-system-packages 'markitdown[all]'
USER node

ENV GENERIC_TIMEZONE=America/Fortaleza
ENV TZ=America/Fortaleza
ENV N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
ENV N8N_RUNNERS_ENABLED=true
ENV N8N_COMMUNITY_PACKAGES_ENABLED=true
ENV N8N_DEFAULT_BINARY_DATA_MODE=filesystem

VOLUME ["/home/node/.n8n"]
EXPOSE 5678
