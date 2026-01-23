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


# Urls

- [n8n docs](https://docs.n8n.io/hosting/installation/docker/#prerequisites)
- [n8n.io](https://n8n.io/)
- [markitdown](https://github.com/microsoft/markitdown)
