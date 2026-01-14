# ============================================
# SCRIPT: Rebuild APK DZ Delivery
# ============================================

Write-Host "🔨 Rebuild de l'APK DZ Delivery..." -ForegroundColor Cyan
Write-Host ""

# Aller dans le dossier de l'app
Set-Location "apps/dz_delivery"

# Clean
Write-Host "🧹 Nettoyage..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "📦 Récupération des dépendances..." -ForegroundColor Yellow
flutter pub get

# Build APK
Write-Host "🏗️ Build de l'APK..." -ForegroundColor Yellow
flutter build apk --release

# Vérifier si le build a réussi
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ APK créé avec succès!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📍 Emplacement: apps/dz_delivery/build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📱 Pour installer sur un appareil connecté:" -ForegroundColor Yellow
    Write-Host "   flutter install" -ForegroundColor White
    Write-Host ""
    Write-Host "🧪 Comptes de test disponibles:" -ForegroundColor Yellow
    Write-Host "   • client@test.com (mot de passe: test12345)" -ForegroundColor White
    Write-Host "   • restaurant@test.com (mot de passe: test12345)" -ForegroundColor White
    Write-Host "   • livreur@test.com (mot de passe: test12345)" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ Erreur lors du build!" -ForegroundColor Red
    Write-Host "Vérifiez les erreurs ci-dessus." -ForegroundColor Yellow
}

# Retour au dossier racine
Set-Location "../.."
