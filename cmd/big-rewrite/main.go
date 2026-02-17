package main

import (
	"context"
	"log"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

type BigRewriteInput struct {
	FilePath string `json:"file_path" jsonschema:"Fichier à réécrire"`
}

func main() {
	s := mcp.NewServer(&mcp.Implementation{
		Name:    "big-rewrite",
		Version: "1.0.0",
	}, nil)

	mcp.AddTool(s, &mcp.Tool{
		Name:        "big_rewrite",
		Description: "Réécrit un fichier complet en one-shot",
	}, func(ctx context.Context, req *mcp.CallToolRequest, input BigRewriteInput) (*mcp.CallToolResult, any, error) {
		// TODO: Implement
		return &mcp.CallToolResult{
			Content: []mcp.Content{&mcp.TextContent{Text: "Not implemented yet"}},
		}, nil, nil
	})

	log.Println("Big Rewrite MCP Server started")

	if err := s.Run(context.Background(), &mcp.StdioTransport{}); err != nil {
		log.Fatalf("Server error: %v", err)
	}
}
