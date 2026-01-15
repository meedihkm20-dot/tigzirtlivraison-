# Script pour tester le backend localement
# Usage: .\scripts\test-local.ps1

Write-Host "🧪 Test du backend local" -ForegroundColor Cyan

# Vérifier si le serveur tourne
$port = 3000
$url = "http://localhost:$port"

try {
    Write-Host "📡 Test health check..." -ForegroundColor Yellow
    $response = Invoke-RestMethod -Uri "$url/health" -Method Get -TimeoutSec 5
    Write-Host "✅ Health: $($response.status)" -ForegroundColor Green
    Write-Host "   Service: $($response.service)" -ForegroundColor Gray
    Write-Host "   Timestamp: $($response.timestamp)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Le serveur ne répond pas sur $url" -ForegroundColor Red
    Write-Host "   Lancez d'abord: npm run start:dev" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "📚 Swagger disponible sur: $url/api/docs" -ForegroundColor Cyan
Write-Host ""

# Test calcul prix livraison
Write-Host "💰 Test calcul prix livraison..." -ForegroundColor Yellow
try {
    $priceResponse = Invoke-RestMethod -Uri "$url/api/delivery/calculate-price?distance=5&zone=tigzirt" -Method Get
    Write-Host "✅ Prix: $($priceResponse.price) $($priceResponse.currency)" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Endpoint delivery non disponible" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ Tests terminés!" -ForegroundColor Green
