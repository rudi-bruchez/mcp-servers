package common

import (
    "os"
    "path/filepath"
)

// CreateBackup crée une copie de backup d'un fichier
func CreateBackup(filePath string) error {
    content, err := os.ReadFile(filePath)
    if err != nil {
        return err
    }
    
    backupPath := filePath + ".backup"
    return os.WriteFile(backupPath, content, 0644)
}

// CountLines compte le nombre de lignes dans une string
func CountLines(content string) int {
    if content == "" {
        return 0
    }
    lines := 1
    for _, c := range content {
        if c == '\n' {
            lines++
        }
    }
    return lines
}
