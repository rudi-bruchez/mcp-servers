# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```powershell
# Build all servers (outputs to bin/)
.\scripts\build-all.ps1

# Build a single server
.\scripts\build-all.ps1 -Server big-rewrite

# Build an individual server manually (from repo root)
go build -o bin/big-rewrite.exe ./cmd/big-rewrite

# Run tests across all servers
.\scripts\test-all.ps1

# Run tests for a specific server
go test -v -race ./cmd/big-rewrite/...

# Run tests for shared packages
go test -v -race ./pkg/...
```

> **Note:** `build-all.ps1` has a character encoding issue on Windows (a quote inside a
> `Format-Table` call causes a PowerShell parser error). The script still exits 0 so
> builds succeed, but if the script misbehaves use `go build` directly.

## Go Workspace Structure

This is a **Go workspace monorepo** (`go.work`) where each server under `cmd/` is its own Go module with its own `go.mod`. The workspace allows them to share code from `pkg/` without publishing.

Key modules:
- Root module: `github.com/rudi-bruchez/mcp-servers` (Go 1.23.0) — contains `pkg/`, listed as `.` in `go.work`
- Each `cmd/<server>/` is an independent module requiring `github.com/modelcontextprotocol/go-sdk v1.3.0`

The broken imports in diagnostics are because `go.work.sum` and vendor directories are gitignored. Run `go work sync` or `go mod tidy` in each server directory to resolve.

**Go version must use the patch number.** `go mod tidy` normalises `go 1.23` to `go 1.23.0`
in each `cmd/*/go.mod`. The `go.work` file must match (`go 1.23.0`, not `go 1.23`), or
builds fail with: `module requires go >= 1.23.0, but go.work lists go 1.23`.

**After `go mod tidy` each `cmd/*/go.mod` gains indirect deps** — `jsonschema-go`,
`uritemplate`, and `oauth2`. That is expected and correct; commit them.

**Diagnostic noise from the language server is normal.** "No packages found" and stale
"could not import" errors appear after editing because the LS can't see the gitignored
`go.work.sum`. `go build` is the authoritative check — if it passes, the code is fine.

## Architecture

**Purpose:** MCP (Model Context Protocol) servers that integrate with Claude Desktop to extend Claude Code's capabilities — primarily for token savings and external API delegation.

**Common MCP server pattern** (all `cmd/*/main.go` follow this):
1. Create server: `mcp.NewServer(&mcp.Implementation{Name, Version}, nil)`
2. Register tools via `mcp.AddTool(s, &mcp.Tool{Name, Description}, handler)` — handler is typed `func(ctx, *mcp.CallToolRequest, InputStruct) (*mcp.CallToolResult, OutputStruct, error)`
3. Serve: `s.Run(context.Background(), &mcp.StdioTransport{})`

Input schemas are automatically inferred from the `InputStruct` type using `jsonschema` struct tags. All from a single import: `github.com/modelcontextprotocol/go-sdk/mcp`.

**MCP SDK critical details:**

- **Single import:** `github.com/modelcontextprotocol/go-sdk/mcp` — no separate `server` package.
- **Returning nil `*CallToolResult` is valid** when using `mcp.AddTool`. The SDK populates
  `Content` from the output struct automatically: `return nil, MyOutput{...}, nil`.
- **Tool errors vs protocol errors:** A non-nil error from a raw `s.AddTool` handler is a
  *protocol error* that can disconnect the client. Return tool-level failures as
  `&mcp.CallToolResult{IsError: true, Content: [...]}`. The generic `mcp.AddTool`
  handles this automatically — a returned error becomes `IsError` content, not a crash.
- **Logs must go to stderr.** Stdout is the JSON-RPC transport channel; any stray write
  there corrupts the session. Use `log.SetOutput(os.Stderr)` or `ServerOptions.Logger`.
- **Tool name constraints:** only `[a-zA-Z0-9_\-.]`, max 128 characters. Spaces and
  other punctuation are rejected at `AddTool` time.
- **`s.Run` vs `s.Connect`:** `s.Run(ctx, transport)` is the normal entrypoint — it
  connects, blocks until the session ends, and returns any error. Use `s.Connect` only
  when you need to hold the `*ServerSession` handle directly (e.g. for `session.Wait()`
  or to send notifications).

**Shared library** (`pkg/common/`):
- `tokens.go` — `EstimateTokens(text)` and `CalculateCost(inputTokens, outputTokens, provider)` (supports claude-opus, claude-sonnet, gemini, gpt-4)
- `files.go` — `CreateBackup(filePath)` and `CountLines(content)`

**The five servers:**
- `big-rewrite` — one-shot file rewrites via Claude API (60-80% token savings)
- `multi-api` — parallel comparison across Claude/Gemini/OpenAI (requires `ANTHROPIC_API_KEY`, `GOOGLE_API_KEY`, `OPENAI_API_KEY`)
- `local-llm` — delegates to local llama.cpp instance (requires `LLAMA_MODEL_PATH`)
- `knowledge-base` — RAG with FAISS vector search (90-95% token savings)
- `usage-tracker` — real-time token tracking and cost analysis

## Setup

```powershell
# Configure Claude Desktop with all servers
.\scripts\setup-claude-desktop.ps1
```

This writes `claude_desktop_config.json` with executable paths and environment variables. Requires Claude Desktop restart after running.

## Adding a New Server

1. Create `cmd/<server-name>/` with its own `go.mod` and `main.go`
2. Add the module to `go.work` under the `use` directive
3. Follow the existing MCP server pattern from any existing `cmd/*/main.go`
4. Run `go mod tidy` inside `cmd/<server-name>/` to generate `go.sum`
5. Document in `docs/` and update the root `README.md`

Minimal `go.mod` for a new server:

```
module github.com/rudi-bruchez/mcp-servers/cmd/<server-name>

go 1.23.0

require github.com/modelcontextprotocol/go-sdk v1.3.0
```

After `go mod tidy`, indirect deps (`jsonschema-go`, `uritemplate`, `oauth2`) are added
automatically — commit the updated `go.mod` and the generated `go.sum`.
