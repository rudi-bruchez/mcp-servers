# Claude MCP Servers (Go)

[![Go Version](https://img.shields.io/badge/Go-1.21+-00ADD8?style=flat&logo=go)](https://go.dev/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Tests](https://github.com/yourusername/claude-mcp-servers-go/workflows/Test/badge.svg)](https://github.com/yourusername/claude-mcp-servers-go/actions)

Collection de serveurs MCP en Go pour optimiser et étendre Claude Code.

## 🚀 Serveurs Disponibles

| Serveur | Description | Économie | Documentation |
|---------|-------------|----------|---------------|
| [big-rewrite](cmd/big-rewrite) | One-shot file rewrites via API Claude | 60-80% tokens | [Docs](docs/servers/big-rewrite.md) |
| [multi-api](cmd/multi-api) | Compare Claude/Gemini/OpenAI en parallèle | Meilleure qualité | [Docs](docs/servers/multi-api.md) |
| [local-llm](cmd/local-llm) | Délégation à llama.cpp local | 70-90% tokens | [Docs](docs/servers/local-llm.md) |
| [knowledge-base](cmd/knowledge-base) | RAG avec embeddings + FAISS | 90-95% tokens | [Docs](docs/servers/knowledge-base.md) |
| [usage-tracker](cmd/usage-tracker) | Auto-analyse et optimisation coûts | Insights | [Docs](docs/servers/usage-tracker.md) |

## ⚡ Quick Start
```powershell
# 1. Clone
git clone https://github.com/yourusername/claude-mcp-servers-go
cd claude-mcp-servers-go

# 2. Build tous les serveurs
.\scripts\build-all.ps1

# 3. Configure Claude Desktop
.\scripts\setup-claude-desktop.ps1

# 4. Redémarrer Claude Desktop
```

## 📦 Installation Serveur Spécifique
```powershell
# Build un seul serveur
cd cmd\big-rewrite
go build -o ..\..\bin\big-rewrite.exe

# Ou avec le script
.\scripts\build-all.ps1 -Server big-rewrite
```

## 🏗️ Architecture

Monorepo avec code partagé:
- **cmd/**: Serveurs MCP (executables)
- **pkg/**: Bibliothèques partagées (clients API, évaluateurs, etc.)
- **docs/**: Documentation complète
- **scripts/**: Utilitaires de build et configuration

## 🔧 Prérequis

- Go 1.21+
- Claude Desktop
- (Optionnel) llama.cpp pour local-llm
- (Optionnel) FAISS pour knowledge-base

## 📖 Documentation

- [Architecture](docs/architecture.md)
- [Guide de contribution](docs/contributing.md)
- [Exemples d'utilisation](docs/examples/workflows.md)

## 🤝 Contributing

Les contributions sont bienvenues! Voir [CONTRIBUTING.md](docs/contributing.md).

## 📄 License

MIT - Voir [LICENSE](LICENSE)

## 🙏 Remerciements

- [MCP SDK Go](https://github.com/mark3labs/mcp-go)
- [Anthropic Claude](https://www.anthropic.com)
- Communauté Go

---

Créé avec ❤️ pour optimiser Claude Code
