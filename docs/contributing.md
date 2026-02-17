# Guide de contribution

Merci de contribuer ! 🎉

## Processus

1. Fork le repo
2. Créer une branche: `git checkout -b feature/ma-feature`
3. Commit: `git commit -m 'Add: ma feature'`
4. Push: `git push origin feature/ma-feature`
5. Ouvrir une Pull Request

## Standards

- Go 1.21+
- Tests obligatoires
- Code formaté (`go fmt`)
- Documentation à jour

## Ajout d'un serveur

1. Créer `cmd/mon-serveur/`
2. Ajouter à `go.work`
3. Documenter dans `docs/servers/`
4. Ajouter au README principal

## Tests
```powershell
.\scripts\test-all.ps1
```
