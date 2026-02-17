# MCP Servers in Go — Course Notes

Lessons from building a real Go workspace of MCP servers, including library evaluation,
API deep-dives, and common pitfalls.

---

## 1. What Is MCP?

**Model Context Protocol (MCP)** is a standard that lets AI assistants (like Claude) talk
to external programs called *servers*. The server exposes capabilities — **tools**,
**resources**, and **prompts** — and the AI calls them via JSON-RPC 2.0 messages.

```
Claude Desktop / Claude Code
        │  JSON-RPC 2.0 over stdio
        ▼
   Your MCP Server (Go binary)
        │
        ▼
  External APIs, databases, files …
```

The transport is almost always **stdio** for local servers: Claude launches the binary and
communicates via stdin/stdout. SSE and HTTP are available for remote servers.

---

## 2. Choosing a Go Library

Two libraries exist as of early 2026:

| | `github.com/mark3labs/mcp-go` | `github.com/modelcontextprotocol/go-sdk` |
|---|---|---|
| Who maintains it | Community | Official (Anthropic / Google) |
| Latest version | v0.44+ (still v0.x) | **v1.3.0** |
| API stability | No guarantee (v0.x) | Stable (v1 semver) |
| Tool handlers | Untyped `map[string]interface{}` | **Typed generics** |
| JSON schema | Manual map construction | **Auto-inferred from structs** |
| Single import | No (needs `mcp` + `server` pkgs) | **Yes** (`go-sdk/mcp`) |
| Go requirement | 1.21+ | **1.23+** |

**Use `modelcontextprotocol/go-sdk`.** It is the reference implementation, has a stable v1
API, and the generics-based tool handler is significantly safer and less boilerplate.

> **Important version note:** `go mod tidy` normalises `go 1.23` to `go 1.23.0` in
> `go.mod`. Your `go.work` must also say `go 1.23.0` (not `go 1.23`) or the workspace
> build will fail with a version mismatch error.

---

## 3. Go Workspace Structure (Monorepo)

When you have several MCP servers that share library code, use a **Go workspace**
(`go.work`). Each server is its own module under `cmd/`; shared utilities live in `pkg/`
inside the root module.

```
repo-root/
├── go.work              ← workspace file, lists all modules
├── go.mod               ← root module (contains pkg/)
├── pkg/
│   └── common/          ← shared helpers imported by all servers
├── cmd/
│   ├── big-rewrite/
│   │   ├── go.mod       ← independent module, own dependency set
│   │   └── main.go
│   ├── multi-api/
│   │   ├── go.mod
│   │   └── main.go
│   └── …
```

`go.work` contents:

```
go 1.23.0

use (
    .                    ← root module (pkg/)
    ./cmd/big-rewrite
    ./cmd/multi-api
    ./cmd/local-llm
    ./cmd/knowledge-base
    ./cmd/usage-tracker
)
```

Each `cmd/*/go.mod` declares its own `require` for `go-sdk`. The workspace lets them
import from `pkg/` without publishing anything.

Build from the workspace root:

```bash
go build -o bin/big-rewrite.exe ./cmd/big-rewrite
```

> `go.work.sum` and vendor directories are typically gitignored. New contributors run
> `go work sync` or `go mod tidy` in each module directory to regenerate them.

---

## 4. The Official SDK API (`go-sdk v1.3.0`)

Everything lives in one package: `github.com/modelcontextprotocol/go-sdk/mcp`.

### 4.1 Creating a Server

```go
s := mcp.NewServer(&mcp.Implementation{
    Name:    "my-server",
    Version: "1.0.0",
}, nil) // nil = default ServerOptions
```

`ServerOptions` (the second argument) lets you set a logger, keepalive interval,
pagination page size, and various notification handlers.

### 4.2 Registering Tools — Two APIs

**Low-level (raw, no validation):**

```go
s.AddTool(&mcp.Tool{
    Name:        "greet",
    InputSchema: json.RawMessage(`{"type":"object","properties":{"user":{"type":"string"}}}`),
}, func(ctx context.Context, req *mcp.CallToolRequest) (*mcp.CallToolResult, error) {
    var args struct{ User string }
    json.Unmarshal(req.Params.Arguments, &args)
    return &mcp.CallToolResult{
        Content: []mcp.Content{&mcp.TextContent{Text: "Hi " + args.User}},
    }, nil
})
```

**High-level (typed generics — preferred):**

```go
type GreetInput struct {
    User string `json:"user" jsonschema:"the name of the person to greet"`
}

mcp.AddTool(s, &mcp.Tool{
    Name:        "greet",
    Description: "Say hello to someone",
}, func(ctx context.Context, req *mcp.CallToolRequest, input GreetInput) (
    *mcp.CallToolResult, any, error,
) {
    return &mcp.CallToolResult{
        Content: []mcp.Content{&mcp.TextContent{Text: "Hi " + input.User}},
    }, nil, nil
})
```

The generic form (`mcp.AddTool`) automatically:
- Infers the JSON schema from `GreetInput` (no manual map required)
- Unmarshals arguments into the struct before calling the handler
- Validates input against the schema — invalid calls are rejected early
- Wraps handler errors as tool-level errors (not protocol errors)

The handler signature is: `func(ctx, *CallToolRequest, In) (*CallToolResult, Out, error)`

You can return `nil` for `*CallToolResult` when you only care about the output struct:

```go
return nil, MyOutput{Result: "done"}, nil
// → SDK auto-populates Content with the JSON of MyOutput
```

### 4.3 Serving Over Stdio

```go
if err := s.Run(context.Background(), &mcp.StdioTransport{}); err != nil {
    log.Fatalf("Server error: %v", err)
}
```

`Run` connects, waits for the session to end, and returns any error. It handles graceful
shutdown when the client disconnects.

### 4.4 Other Transports

| Type | Use case |
|---|---|
| `&mcp.StdioTransport{}` | Local server launched by Claude Desktop |
| `&mcp.IOTransport{Reader, Writer}` | Custom streams |
| `*mcp.InMemoryTransport` | Tests (use `mcp.NewInMemoryTransports()`) |
| `*mcp.CommandTransport{Command}` | Client side: launch a subprocess |
| SSE / Streamable HTTP | Remote servers (see `mcp.NewSSEHandler`) |

### 4.5 Content Types

```go
// Text
&mcp.TextContent{Text: "hello"}

// Image
&mcp.ImageContent{Data: base64Data, MIMEType: "image/png"}

// Audio
&mcp.AudioContent{Data: base64Data, MIMEType: "audio/wav"}
```

`CallToolResult.Content` is `[]mcp.Content` (an interface). Cast back with a type
assertion: `res.Content[0].(*mcp.TextContent).Text`.

### 4.6 Resources and Prompts

```go
// Resource (static URI)
s.AddResource(&mcp.Resource{URI: "file:///config.json"}, func(ctx context.Context, req *mcp.ReadResourceRequest) (*mcp.ReadResourceResult, error) {
    return &mcp.ReadResourceResult{
        Contents: []*mcp.ResourceContents{{URI: req.Params.URI, Text: "{}"}},
    }, nil
})

// Resource template (URI with variables)
s.AddResourceTemplate(&mcp.ResourceTemplate{URITemplate: "file:///data/{id}"}, handler)

// Prompt
s.AddPrompt(&mcp.Prompt{
    Name: "summarise",
    Arguments: []*mcp.PromptArgument{{Name: "text", Required: true}},
}, func(ctx context.Context, req *mcp.GetPromptRequest) (*mcp.GetPromptResult, error) {
    return &mcp.GetPromptResult{
        Messages: []*mcp.PromptMessage{{
            Role:    "user",
            Content: &mcp.TextContent{Text: "Summarise: " + req.Params.Arguments["text"]},
        }},
    }, nil
})
```

---

## 5. Schema Generation with Struct Tags

The SDK infers JSON Schema from Go types automatically. Control the output with struct
tags:

```go
type SearchInput struct {
    Query  string `json:"query"  jsonschema:"the search query"`
    Limit  int    `json:"limit"  jsonschema:"max results to return"`
    Offset int    `json:"offset,omitempty" jsonschema:"pagination offset"`
}
```

For custom constraints (enums, min/max), use `jsonschema.For[T]()` from
`github.com/google/jsonschema-go/jsonschema`:

```go
schema, err := jsonschema.For[SearchInput](&jsonschema.ForOptions{
    TypeSchemas: map[reflect.Type]*jsonschema.Schema{
        reflect.TypeFor[MyEnum](): {Type: "string", Enum: []any{"a", "b", "c"}},
    },
})

mcp.AddTool(s, &mcp.Tool{Name: "search", InputSchema: schema}, handler)
```

---

## 6. Testing MCP Servers

Use `mcp.NewInMemoryTransports()` to wire a server and a test client without any I/O:

```go
func TestGreet(t *testing.T) {
    s := mcp.NewServer(&mcp.Implementation{Name: "test", Version: "0.0.1"}, nil)
    mcp.AddTool(s, &mcp.Tool{Name: "greet"}, greetHandler)

    ctx := context.Background()
    t1, t2 := mcp.NewInMemoryTransports()

    serverSession, err := s.Connect(ctx, t1, nil)
    if err != nil {
        t.Fatal(err)
    }
    defer serverSession.Close()

    client := mcp.NewClient(&mcp.Implementation{Name: "test-client", Version: "0.0.1"}, nil)
    clientSession, err := client.Connect(ctx, t2, nil)
    if err != nil {
        t.Fatal(err)
    }
    defer clientSession.Close()

    res, err := clientSession.CallTool(ctx, &mcp.CallToolParams{
        Name:      "greet",
        Arguments: map[string]any{"user": "Alice"},
    })
    if err != nil {
        t.Fatal(err)
    }
    got := res.Content[0].(*mcp.TextContent).Text
    if got != "Hi Alice" {
        t.Errorf("got %q, want %q", got, "Hi Alice")
    }
}
```

---

## 7. Common Pitfalls

### 7.1 Non-existent `mcp-go` API

The community `mcp-go` library API changed significantly between versions. Code generated
against outdated documentation may use functions that don't exist:

```go
// WRONG — does not exist in mcp-go v0.6.0
server.NewMCPServer("name", "1.0.0", server.WithToolsCapability(&MyServer{}))
s.Serve()

// CORRECT for mcp-go v0.6.0
s := server.NewMCPServer("name", "1.0.0")
s.AddTool(tool, handler)
server.ServeStdio(s)
```

The official SDK avoids this problem with a stable v1 API.

### 7.2 `go.work` / `go.mod` Go Version Mismatch

`go mod tidy` normalises `go 1.23` to `go 1.23.0` in `go.mod`. Your `go.work` file must
use the same format (`go 1.23.0`), otherwise:

```
go: module cmd\big-rewrite listed in go.work file requires go >= 1.23.0,
    but go.work lists go 1.23; to update it: go work use
```

Fix: write `go 1.23.0` in `go.work`, or run `go work use ./cmd/...`.

### 7.3 Tool Errors vs Protocol Errors

In the low-level `s.AddTool` API, returning a non-nil `error` is a **protocol error** —
it closes the session. To signal a tool-level failure (which the AI can read and act on),
return a result with `IsError: true`:

```go
// Protocol error — bad, disconnects the client
return nil, fmt.Errorf("file not found")

// Tool error — correct, AI sees the error message
return &mcp.CallToolResult{
    IsError: true,
    Content: []mcp.Content{&mcp.TextContent{Text: "file not found: " + path}},
}, nil
```

The high-level `mcp.AddTool` handles this automatically: a non-nil error from the handler
is packed into `IsError` content, not surfaced as a protocol error.

### 7.4 Tool Name Constraints

MCP tool names are validated. Only `[a-zA-Z0-9_\-.]` characters are allowed, max 128
characters. Names like `"my tool"` (with a space) will be rejected at `AddTool` time.

### 7.5 Logging Must Go to Stderr

Since stdout is the MCP transport channel (newline-delimited JSON), any stray output
there corrupts the session. Always send logs to stderr:

```go
log.SetOutput(os.Stderr)
// or use slog with ServerOptions.Logger
```

---

## 8. Full Minimal Server Example

```go
package main

import (
    "context"
    "fmt"
    "log"
    "os"

    "github.com/modelcontextprotocol/go-sdk/mcp"
)

type AddInput struct {
    A float64 `json:"a" jsonschema:"first number"`
    B float64 `json:"b" jsonschema:"second number"`
}

type AddOutput struct {
    Sum float64 `json:"sum"`
}

func main() {
    log.SetOutput(os.Stderr) // keep stdout clean for the MCP transport

    s := mcp.NewServer(&mcp.Implementation{
        Name:    "calculator",
        Version: "1.0.0",
    }, nil)

    mcp.AddTool(s, &mcp.Tool{
        Name:        "add",
        Description: "Add two numbers",
    }, func(ctx context.Context, _ *mcp.CallToolRequest, in AddInput) (
        *mcp.CallToolResult, AddOutput, error,
    ) {
        return nil, AddOutput{Sum: in.A + in.B}, nil
    })

    log.Println("calculator MCP server started")

    if err := s.Run(context.Background(), &mcp.StdioTransport{}); err != nil {
        fmt.Fprintln(os.Stderr, "server error:", err)
        os.Exit(1)
    }
}
```

`go.mod` for this server:

```
module github.com/you/calculator-mcp

go 1.23.0

require github.com/modelcontextprotocol/go-sdk v1.3.0
```

Build:

```bash
go build -o calculator-mcp .
```

Claude Desktop config (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "calculator": {
      "command": "/path/to/calculator-mcp"
    }
  }
}
```

---

## 9. Key Dependency Graph

```
go-sdk v1.3.0
├── github.com/google/jsonschema-go   ← schema inference from Go types
├── github.com/yosida95/uritemplate   ← URI template matching for resources
├── github.com/golang-jwt/jwt/v5      ← OAuth support
└── golang.org/x/oauth2               ← OAuth support
```

Your server's `go.mod` will pick up the transitive deps after `go mod tidy`. The two you
interact with indirectly in everyday use are `jsonschema-go` (via struct tags) and
`uritemplate` (via resource template URIs).

---

## 10. Quick Reference

```go
// Server
mcp.NewServer(impl, opts)

// Tools
s.AddTool(tool, rawHandler)           // low-level, manual schema
mcp.AddTool(s, tool, typedHandler)    // high-level, auto schema (preferred)

// Resources
s.AddResource(resource, handler)
s.AddResourceTemplate(template, handler)
s.RemoveResources(uris...)

// Prompts
s.AddPrompt(prompt, handler)
s.RemovePrompts(names...)

// Middleware
s.AddReceivingMiddleware(m...)
s.AddSendingMiddleware(m...)

// Transports
&mcp.StdioTransport{}
&mcp.IOTransport{Reader, Writer}
mcp.NewInMemoryTransports()           // returns (t1, t2)
&mcp.CommandTransport{Command: exec.Command("./server")}

// Serving
s.Run(ctx, transport)                 // blocks until done
s.Connect(ctx, transport, opts)       // returns *ServerSession, for advanced use

// Client (useful for tests)
mcp.NewClient(impl, opts)
client.Connect(ctx, transport, opts)  // returns *ClientSession
session.CallTool(ctx, params)
session.Tools(ctx, nil)               // iter.Seq, Go 1.23+
```
