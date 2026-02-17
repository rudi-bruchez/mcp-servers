# Claude MCP Servers (Go)

[![Go Version](https://img.shields.io/badge/Go-1.23+-00ADD8?style=flat&logo=go)](https://go.dev/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Collection of MCP servers in Go to extend Claude Code's capabilities.

## Available Servers

| Server | Description | Token Savings |
|--------|-------------|---------------|
| [big-rewrite](cmd/big-rewrite) | One-shot file rewrites via Claude API | 60-80% |
| [multi-api](cmd/multi-api) | Parallel comparison across Claude/Gemini/OpenAI | Best quality |
| [local-llm](cmd/local-llm) | Delegate to a local llama.cpp instance | 70-90% |
| [knowledge-base](cmd/knowledge-base) | RAG with embeddings + FAISS vector search | 90-95% |
| [usage-tracker](cmd/usage-tracker) | Real-time token tracking and cost analysis | Insights |

## Quick Start

```powershell
# 1. Clone
git clone https://github.com/rudi-bruchez/mcp-servers
cd mcp-servers

# 2. Build all servers
.\scripts\build-all.ps1

# 3. Configure Claude Desktop
.\scripts\setup-claude-desktop.ps1

# 4. Restart Claude Desktop
```

## Install a Single Server

```powershell
# Build one server manually
go build -o bin/big-rewrite.exe ./cmd/big-rewrite
```

## Architecture

Monorepo with shared code:

- **cmd/**: MCP servers (executables), each with its own `go.mod`
- **pkg/**: Shared libraries (API clients, token estimation, file utilities)
- **docs/**: Documentation
- **scripts/**: Build and configuration utilities

The workspace is managed via `go.work`. Each server under `cmd/` is an independent Go module that references shared code from `pkg/` through the workspace.

## Requirements

- Go 1.23+
- Claude Desktop
- (Optional) llama.cpp for `local-llm`
- (Optional) FAISS for `knowledge-base`
- API keys: `ANTHROPIC_API_KEY`, `GOOGLE_API_KEY`, `OPENAI_API_KEY` (for `multi-api`)

## Documentation

- [Architecture](docs/architecture.md)
- [Contributing](docs/contributing.md)

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](docs/contributing.md).

## License

MIT — see [LICENSE](LICENSE)

## Acknowledgements

- [MCP Go SDK](https://github.com/modelcontextprotocol/go-sdk)
- [Anthropic Claude](https://www.anthropic.com)
- The Go community
