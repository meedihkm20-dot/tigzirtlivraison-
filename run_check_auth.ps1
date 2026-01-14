# Script PowerShell pour vérifier les logs d'authentification
# Utilise Supabase CLI

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  VÉRIFICATION DES LOGS D'AUTH" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Chemin vers Supabase CLI
$supabasePath = "C:\Users\$env:USERNAME\scoop\apps\supabase\current\supabase.exe"

# Vérifier que Supabase CLI existe
if (-not (Test-Path $supabasePath)) {
    Write-Host "❌ Supabase CLI non trouvé à: $supabasePath" -ForegroundColor Red
    Write-Host "Essayez: scoop install supabase" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Supabase CLI trouvé" -ForegroundColor Green
Write-Host "📊 Exécution du script de vérification...`n" -ForegroundColor Yellow

# Lire le contenu du script SQL
$sqlContent = Get-Content -Path "check_auth_logs.sql" -Raw

# Créer un fichier temporaire pour la sortie
$tempOutput = "auth_check_results.txt"

# Exécuter le script SQL via Supabase CLI
Write-Host "Connexion à la base de données..." -ForegroundColor Cyan

# Note: Supabase CLI n'a pas de commande directe pour exécuter du SQL
# On doit utiliser psql ou le Dashboard
Write-Host "`n⚠️ Supabase CLI ne peut pas exécuter du SQL directement" -ForegroundColor Yellow
Write-Host "`n📋 OPTIONS DISPONIBLES:" -ForegroundColor Green
Write-Host "  1. Copier le contenu de check_auth_logs.sql" -ForegroundColor White
Write-Host "  2. Ouvrir: https://supabase.com/dashboard/project/pauqmhqriyjdqctvfvtt/sql/new" -ForegroundColor Cyan
Write-Host "  3. Coller et exécuter (F5)`n" -ForegroundColor White

Write-Host "🔗 Lien direct SQL Editor:" -ForegroundColor Yellow
Write-Host "https://supabase.com/dashboard/project/pauqmhqriyjdqctvfvtt/sql/new`n" -ForegroundColor Cyan

# Ouvrir le fichier SQL dans l'éditeur par défaut
Write-Host "📝 Ouverture du fichier SQL..." -ForegroundColor Green
Start-Process "check_auth_logs.sql"

# Ouvrir le navigateur
Write-Host "🌐 Ouverture du SQL Editor..." -ForegroundColor Green
Start-Process "https://supabase.com/dashboard/project/pauqmhqriyjdqctvfvtt/sql/new"

Write-Host "`n✅ Fichiers ouverts!" -ForegroundColor Green
Write-Host "Copiez le contenu du fichier SQL dans le SQL Editor`n" -ForegroundColor White

Write-Host "========================================`n" -ForegroundColor Cyan
