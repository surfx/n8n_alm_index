# Sobre

Projeto docker para executar uma imagem n8n

# Acesso

- [http://localhost:5678](http://localhost:5678)

![n8n](arquivos_readme/n8n.png)

## how

Para buildar o docker do zero

```ps
try_all.ps1
```

Para iniciar

```ps
start.ps1
```

O volume local aponta para a pasta `arquivos_n8n`, no docker mapeado para `/files`

# Http

- Authorization: Basic MDUzMTIwOTc5MjY6VHJhYmFsaG9yZW1vdG8wMQ==

# Resetar usuário e senha do n8n

`docker exec -it n8n n8n user-management:reset --email "...@gmail.com" --password "...."`

# Configurações n8n

Acessar [community-nodes](http://localhost:5678/settings/community-nodes), instale o package `@bitovi/n8n-nodes-markitdown`

# qdrant

Dentro do docker use `qdrant`, no windows use `localhost`

- [http://qdrant:6333](http://qdrant:6333)
- [http://localhost:6333/collections](http://localhost:6333/collections)
- [http://localhost:6333/dashboard](http://localhost:6333/dashboard)

Criar índice no qdrant

```bash
curl -X DELETE "http://qdrant:6333/collections/minha_collection"
curl -X PUT "http://qdrant:6333/collections/minha_collection" \
     -H "Content-Type: application/json" \
     -d '{
           "vectors": {
             "size": 768, 
             "distance": "Cosine"
           }
         }'
```

# Ollama

dentro do docker use `ollama`, no windows use `localhost`

- [http://ollama:11434](http://ollama:11434)

Dentro do docker ollama instale:

`ollama pull nomic-embed-text`

# Urls

- [n8n docs](https://docs.n8n.io/hosting/installation/docker/#prerequisites)
- [n8n.io](https://n8n.io/)
- [markitdown](https://github.com/microsoft/markitdown)
