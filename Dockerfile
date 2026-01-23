FROM node:20-bookworm-slim

# ===============================
# Sistema
# ===============================
USER root

ENV DEBIAN_FRONTEND=noninteractive

#RUN sed -i 's/^deb http/deb [signed-by=\/usr\/share\/keyrings\/debian-archive-keyring.gpg] http/' /etc/apt/sources.list || true

RUN apt-get update && apt-get install -y \
    sudo \
    wget \
    python3 \
    python3-pip \
    python3-dev \
	python3-venv \
    build-essential \
    libmagic1 \
    poppler-utils \
    tesseract-ocr \
    tesseract-ocr-por \
    tesseract-ocr-eng \
	ffmpeg \
    libxml2-dev \
    libxslt1-dev \
    antiword \
    pandoc \
    libreoffice \
    fonts-dejavu \
    fonts-liberation \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ===============================
# Usuário node + sudo
# ===============================
RUN echo "node ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ===============================
# Python libs
# ===============================
RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir 'markitdown[all]'
ENV PATH="/opt/venv/bin:$PATH"

# ===============================
# n8n
# ===============================
RUN npm install -g n8n



# ===============================
# Runtime
# ===============================
USER node
WORKDIR /home/node

ENV GENERIC_TIMEZONE=America/Fortaleza
ENV TZ=America/Fortaleza
ENV N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
#ENV N8N_RUNNERS_ENABLED=true
ENV N8N_COMMUNITY_PACKAGES_ENABLED=true
ENV N8N_DEFAULT_BINARY_DATA_MODE=filesystem

VOLUME ["/home/node/.n8n"]
EXPOSE 5678

CMD ["n8n"]
