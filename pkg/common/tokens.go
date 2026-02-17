package common

// EstimateTokens estime le nombre de tokens (approximatif)
func EstimateTokens(text string) int {
    return len(text) / 4
}

// CalculateCost calcule le coût pour un provider donné
func CalculateCost(inputTokens, outputTokens int, provider string) float64 {
    var inputCost, outputCost float64
    
    switch provider {
    case "claude-opus":
        inputCost = float64(inputTokens) * 15.0 / 1_000_000
        outputCost = float64(outputTokens) * 75.0 / 1_000_000
    case "claude-sonnet":
        inputCost = float64(inputTokens) * 3.0 / 1_000_000
        outputCost = float64(outputTokens) * 15.0 / 1_000_000
    case "gemini":
        inputCost = float64(inputTokens) * 1.25 / 1_000_000
        outputCost = float64(outputTokens) * 5.0 / 1_000_000
    case "gpt-4":
        inputCost = float64(inputTokens) * 10.0 / 1_000_000
        outputCost = float64(outputTokens) * 30.0 / 1_000_000
    default:
        return 0
    }
    
    return inputCost + outputCost
}
