# ============================================================
# Script de verification de synchronisation du schema
# ============================================================

Write-Host "Verification de la synchronisation du schema..." -ForegroundColor Cyan

$errors = @()

# 1. Verifier que les fichiers existent
$files = @(
    "supabase/migrations/000_complete_schema.sql",
    "supabase/migrations/102_unified_schema_fix.sql",
    "backend/src/types/database.types.ts",
    "apps/dz_delivery/lib/core/models/database_models.dart",
    "SCHEMA_REFERENCE.md"
)

Write-Host ""
Write-Host "Verification des fichiers..." -ForegroundColor Yellow
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "  OK: $file" -ForegroundColor Green
    } else {
        Write-Host "  MANQUANT: $file" -ForegroundColor Red
        $errors += "Fichier manquant: $file"
    }
}

# 2. Verifier les colonnes critiques dans le backend
Write-Host ""
Write-Host "Verification des colonnes critiques (Backend)..." -ForegroundColor Yellow
$backendFile = Get-Content "backend/src/types/database.types.ts" -Raw

$criticalChecks = @(
    @{ good = "livreur_id"; bad = "driver_id" },
    @{ good = "delivery_latitude"; bad = "delivery_lat" },
    @{ good = "delivery_longitude"; bad = "delivery_lng" },
    @{ good = "prepared_at"; bad = "preparing_at" }
)

foreach ($check in $criticalChecks) {
    $badPattern = $check.bad
    if ($backendFile -match $badPattern) {
        # Verifier si c'est dans un commentaire
        if ($backendFile -match "PAS.*$badPattern") {
            Write-Host "  OK: $($check.good)" -ForegroundColor Green
        } else {
            Write-Host "  ERREUR: $badPattern trouve" -ForegroundColor Red
            $errors += "Backend utilise $badPattern au lieu de $($check.good)"
        }
    } else {
        Write-Host "  OK: $($check.good)" -ForegroundColor Green
    }
}

# 3. Resume
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
if ($errors.Count -eq 0) {
    Write-Host "SCHEMA SYNCHRONISE - Aucune erreur!" -ForegroundColor Green
} else {
    Write-Host "ERREURS DETECTEES: $($errors.Count)" -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host "  - $err" -ForegroundColor Red
    }
}
Write-Host "================================================" -ForegroundColor Cyan
