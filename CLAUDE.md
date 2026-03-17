# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## O que é este projeto

Ambiente Docker para rodar o **Notebook Intelligence (NBI)** — plugin JupyterLab que integra assistentes de IA (Claude, GitHub Copilot, LiteLLM, Ollama) ao JupyterLab. Este repositório contém apenas a infraestrutura de container; o código-fonte do NBI fica em `references/notebook-intelligence/`.

## Comandos principais

```bash
make build   # build da imagem Docker
make run     # sobe o container (JupyterLab em localhost:8888)
make stop    # para e remove o container
make logs    # acompanha logs do container
make clean   # stop + remoção da imagem
```

## Arquitetura

```
docker/Docerkfile        # imagem Python 3.12-slim com jupyterlab + notebook-intelligence
Makefile                 # automação: build/run/stop/logs/clean
notebooks/               # notebooks Jupyter de trabalho (montados em /workspace)
references/              # material de referência — ignorado pelo git, pode estar vazio
```

### Volumes montados no `make run`

| Host | Container | Propósito |
|---|---|---|
| `$PWD` | `/workspace` | workspace de trabalho |
| `~/.claude` | `/root/.claude` | auth do Claude Code (persiste entre reinicializações) |

### Claude mode no container

A config NBI é criada em tempo de build em `/root/.jupyter/nbi/config.json` com `claude_settings.enabled: true`. O diretório `/root/.claude` é criado na imagem e sobrescrito pelo volume em runtime.

Para autenticar pela primeira vez:
```bash
# dentro do terminal integrado do JupyterLab
claude /login
```

## Estrutura do NBI (referência)

O NBI é instalado via `pip install notebook-intelligence` na imagem Docker. Se precisar inspecionar o código-fonte, adicione o repositório upstream em `references/notebook-intelligence/` (não versionado aqui).

O plugin é uma extensão híbrida (servidor Python + frontend TypeScript/React):

- **Backend Python** (`notebook_intelligence/`): `claude.py` (integração Claude Code), `api.py` (endpoints REST/WebSocket), `extension.py` (registro no Jupyter Server), `config.py`, `mcp_manager.py`, `rule_manager.py`, provedores LLM em `llm_providers/`
- **Frontend TypeScript** (`src/`): `chat-sidebar.tsx` (UI principal do chat), `settings-panel.tsx` (configurações), `api.ts` (comunicação com backend)

Dependências principais: `claude-agent-sdk` (bundla o CLI do Claude Code), `litellm`, `anthropic`, `fastmcp`, `ollama`.
