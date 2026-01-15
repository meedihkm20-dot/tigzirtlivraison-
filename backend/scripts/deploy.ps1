# Script de déploiement pour Windows PowerShell
# Usage: .\scripts\deploy.ps1

Write-Host "🚀 Préparation du déploiement Tigzirt Backend" -ForegroundColor Cyan

# Vérifier si git est initialisé
if (-not (Test-Path ".git")) {
    Write-Host "📦 Initialisation Git..." -ForegroundColor Yellow
    git init
}

# Ajouter tous les fichiers
Write-Host "📝 Ajout des fichiers..." -ForegroundColor Yellow
git add .

# Commit
$commitMessage = Read-Host "Message de commit (ou Entrée pour 'Update backend')"
if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    $commitMessage = "Update backend"
}
git commit -m $commitMessage

# Vérifier si remote existe
$remoteExists = git remote | Select-String "origin"
if (-not $remoteExists) {
    Write-Host ""
    Write-Host "⚠️  Aucun remote 'origin' configuré." -ForegroundColor Yellow
    Write-Host "Créez un repo GitHub et exécutez:" -ForegroundColor White
    Write-Host "  git remote add origin https://github.com/VOTRE_USERNAME/tigzirt-backend.git" -ForegroundColor Green
    Write-Host "  git push -u origin main" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "📤 Push vers GitHub..." -ForegroundColor Yellow
    git push origin main
    Write-Host ""
    Write-Host "✅ Code poussé vers GitHub!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Prochaines étapes sur Koyeb:" -ForegroundColor Cyan
    Write-Host "1. Aller sur https://www.koyeb.com" -ForegroundColor White
    Write-Host "2. Create App → GitHub → Sélectionner le repo" -ForegroundColor White
    Write-Host "3. Builder: Dockerfile, Port: 3000" -ForegroundColor White
    Write-Host "4. Ajouter les variables d'environnement" -ForegroundColor White
    Write-Host "5. Deploy!" -ForegroundColor White
}
