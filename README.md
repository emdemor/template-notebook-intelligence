# Template para `notebook-intelligence`

Ambiente Docker para rodar o **Notebook Intelligence (NBI)** — plugin JupyterLab que integra assistentes de IA (Claude, GitHub Copilot, LiteLLM, Ollama) diretamente ao JupyterLab. Este repositório contém apenas a infraestrutura de container; o código-fonte do NBI é instalado via `pip` a partir do PyPI.

## Funcionalidades principais

- JupyterLab com o plugin NBI pré-instalado e configurado
- Integração com Claude Code habilitada por padrão (modo `claude_settings.enabled: true`)
- Suporte a múltiplos provedores LLM: Claude (Anthropic), GitHub Copilot, LiteLLM e Ollama
- Workspace montado como volume — seus notebooks ficam acessíveis dentro do container sem cópia
- Autenticação do Claude Code persistida entre reinicializações via volume `~/.claude`

---

## Sumário

- [Tech Stack](#tech-stack)
- [Pré-requisitos](#pré-requisitos)
- [Início rápido](#início-rápido)
- [Arquitetura](#arquitetura)
- [Configuração NBI](#configuração-nbi)
- [Autenticação Claude Code](#autenticação-claude-code)
- [Comandos disponíveis](#comandos-disponíveis)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Solução de problemas](#solução-de-problemas)

---

## Tech Stack

| Componente | Tecnologia |
|---|---|
| Linguagem base | Python 3.12-slim |
| IDE | JupyterLab >= 4.5 |
| Plugin IA | notebook-intelligence (PyPI) |
| Container | Docker |
| Automação | GNU Make |
| Provedores LLM | Claude (Anthropic), GitHub Copilot, LiteLLM, Ollama |

---

## Pré-requisitos

- [Docker](https://docs.docker.com/get-docker/) instalado e rodando
- `make` disponível no sistema (pré-instalado no Linux/macOS)
- Conta Anthropic com acesso ao Claude (para usar Claude Code)

Não é necessário Python, pip ou qualquer dependência local além do Docker.

---

## Início rápido

### 1. Clone o repositório

```bash
git clone <url-do-repo>
cd notebook-intelligence
```

### 2. Build da imagem Docker

```bash
make build
```

Este comando executa `docker build -f docker/Docerkfile -t notebook-intelligence .`, criando a imagem com:

- Python 3.12-slim como base
- JupyterLab >= 4.5 instalado via pip
- Plugin `notebook-intelligence` instalado via pip
- Configuração NBI em `/root/.jupyter/nbi/config.json` com Claude habilitado
- Diretório `/root/.claude` criado para receber o volume de autenticação

### 3. Suba o container

```bash
make run
```

Este comando executa:

```
docker run -d \
  --name notebook-intelligence \
  -p 8888:8888 \
  -v $PWD:/workspace \
  -v ~/.claude:/root/.claude \
  -w /workspace \
  notebook-intelligence
```

Volumes montados:

| Host | Container | Propósito |
|---|---|---|
| `$PWD` | `/workspace` | Seus notebooks e arquivos locais |
| `~/.claude` | `/root/.claude` | Credenciais do Claude Code (persistidas entre reinicializações) |

### 4. Acesse o JupyterLab

Abra [http://localhost:8888](http://localhost:8888) no navegador. Nenhuma senha ou token é exigido.

### 5. Autentique o Claude Code (primeira vez)

No terminal integrado do JupyterLab (menu **File → New → Terminal**):

```bash
claude /login
```

Siga o fluxo OAuth no navegador. As credenciais são salvas em `~/.claude` e persistem entre reinicializações do container.

---

## Arquitetura

```
notebook-intelligence/
├── docker/
│   └── Docerkfile          # Imagem Python 3.12-slim com JupyterLab + NBI
├── Makefile                # Automação: build / run / stop / logs / clean
├── notebooks/              # Diretório para notebooks Jupyter (montado em /workspace)
├── references/             # Material de referência (não é código do projeto, ignorado pelo git)
│   ├── notebook-intelligence/   # Código-fonte upstream do NBI (leitura)
│   └── post-claude-mode.md      # Documentação da integração Claude Code × NBI
└── CLAUDE.md               # Instruções para o Claude Code ao trabalhar neste repo
```

### Fluxo de funcionamento

```
Usuário → Navegador (localhost:8888)
            ↓
         JupyterLab (dentro do container Docker)
            ↓
         Plugin NBI (notebook-intelligence)
            ├── Backend Python: API REST/WebSocket, integração Claude Code
            └── Frontend React: chat sidebar, painel de configurações
                    ↓
              Provedores LLM (Claude / Copilot / LiteLLM / Ollama)
```

### O que acontece no `make build`

1. Docker usa `docker/Docerkfile` baseado em `python:3.12-slim`
2. Instala `jupyterlab>=4.5` e `notebook-intelligence` via pip
3. Cria `/root/.jupyter/nbi/config.json` com Claude habilitado e ferramentas built-in
4. Cria `/root/.claude` (sobrescrito em runtime pelo volume)
5. Expõe a porta 8888
6. Define o CMD para iniciar o JupyterLab sem autenticação por token/senha

### O que acontece no `make run`

1. Sobe o container em background (`-d`)
2. Mapeia porta `8888` do host para `8888` do container
3. Monta o diretório atual como `/workspace` (working directory do container)
4. Monta `~/.claude` do host como `/root/.claude` no container (persistência de auth)

---

## Configuração NBI

A configuração do plugin é gravada em tempo de build em `/root/.jupyter/nbi/config.json`:

```json
{
  "claude_settings": {
    "enabled": true,
    "tools": [
      "claude-code:built-in-tools",
      "nbi:built-in-jupyter-ui-tools"
    ],
    "setting_sources": ["user", "project"]
  }
}
```

| Campo | Valor | Descrição |
|---|---|---|
| `claude_settings.enabled` | `true` | Ativa a integração Claude Code no NBI |
| `tools` | `claude-code:built-in-tools` | Ferramentas nativas do Claude Code |
| `tools` | `nbi:built-in-jupyter-ui-tools` | Ferramentas de UI do JupyterLab (executar células, ler notebooks) |
| `setting_sources` | `["user", "project"]` | Fontes de configuração aceitas |

Para personalizar, edite o arquivo `docker/Docerkfile` e rebuild com `make clean && make build`.

---

## Autenticação Claude Code

O Claude Code autentica via OAuth com a Anthropic. As credenciais ficam em `~/.claude` no host e são montadas no container, portanto:

- **Primeira vez:** execute `claude /login` dentro do terminal do JupyterLab
- **Reinicializações:** as credenciais já estão persistidas; nenhuma ação necessária
- **Atualização de credenciais:** execute `claude /login` novamente se expiradas

---

## Comandos disponíveis

| Comando | O que faz |
|---|---|
| `make build` | Build da imagem Docker `notebook-intelligence` |
| `make run` | Sobe o container em background na porta 8888 |
| `make stop` | Para e remove o container |
| `make logs` | Acompanha os logs do container em tempo real (`docker logs -f`) |
| `make clean` | Para o container e remove a imagem Docker (equivale a `stop` + `docker rmi`) |

### Exemplos de uso

```bash
# Build inicial
make build

# Subir o ambiente
make run

# Ver se está funcionando (acompanha logs em tempo real)
make logs

# Parar o container sem remover a imagem
make stop

# Limpar tudo (para rebuild completo)
make clean && make build
```

---

## Estrutura do repositório

```
.
├── docker/
│   └── Docerkfile        # Dockerfile da imagem (note: nome com typo é intencional no projeto)
├── notebooks/            # Diretório local para notebooks — montado como /workspace no container
├── references/           # Ignorado pelo git; contém código-fonte NBI upstream e docs de referência
├── Makefile              # Automação principal
├── CLAUDE.md             # Instruções para o Claude Code (AI assistant)
└── .gitignore            # Ignora checkpoints Jupyter, dados, modelos e references/
```

**Nota sobre `references/`:** este diretório está no `.gitignore` e não é versionado. Serve apenas como material de referência local para entendimento do NBI upstream.

---

## Solução de problemas

### Container não sobe / porta já em uso

**Erro:** `docker: Error response from daemon: Conflict. The container name "/notebook-intelligence" is already in use.`

**Solução:**
```bash
make stop   # remove o container existente
make run    # sobe novamente
```

**Erro:** `Bind for 0.0.0.0:8888 failed: port is already allocated`

**Solução:** outra aplicação está usando a porta 8888. Pare-a ou edite o `Makefile` para mudar `PORT := 8888` para outra porta disponível, por exemplo `PORT := 8889`.

---

### JupyterLab não abre no navegador

1. Verifique se o container está rodando: `docker ps | grep notebook-intelligence`
2. Veja os logs para erros de inicialização: `make logs`
3. Aguarde alguns segundos — o JupyterLab pode levar 5-10s para inicializar

---

### Claude Code não aparece no NBI

1. Verifique a configuração dentro do container:
   ```bash
   docker exec notebook-intelligence cat /root/.jupyter/nbi/config.json
   ```
   Deve retornar o JSON com `claude_settings.enabled: true`.

2. Se o arquivo não existir, rebuild a imagem:
   ```bash
   make clean && make build
   ```

---

### Erro de autenticação Claude Code

**Sintoma:** mensagem de erro ao usar o chat NBI com Claude.

**Solução:**
1. Abra o terminal integrado do JupyterLab
2. Execute `claude /login`
3. Complete o fluxo OAuth no navegador
4. Tente novamente no chat NBI

---

### Rebuild completo após mudanças no Dockerfile

```bash
make clean    # para container e remove imagem
make build    # reconstrói do zero
make run      # sobe o ambiente atualizado
```

---

### Permissões no diretório `~/.claude`

Se o volume `~/.claude` não existir no host, o Docker cria um diretório vazio. Isso é normal — ele será populado após o primeiro `claude /login`.

Se houver erros de permissão:
```bash
mkdir -p ~/.claude
chmod 755 ~/.claude
make run
```
