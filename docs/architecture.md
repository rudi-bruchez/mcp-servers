# Architecture

## Vue d'ensemble

Le monorepo est structuré pour maximiser la réutilisation de code entre serveurs MCP.

## Structure
```
claude-mcp-servers-go/
├── cmd/          # Serveurs (binaries)
├── pkg/          # Code partagé
├── internal/     # Code privé
└── docs/         # Documentation
```

## Principes

1. **DRY**: Pas de duplication entre serveurs
2. **Modularité**: Chaque serveur est indépendant
3. **Partage**: Code commun dans pkg/
4. **Tests**: Coverage > 80%

## Flux de données
```
Claude Code → MCP Server → pkg/clients → API externe
                ↓
            pkg/evaluator → Résultat
```
