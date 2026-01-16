# Script pour créer les utilisateurs de test via l'API Admin Supabase
# Exécuter: .\create-test-users.ps1

$PROJECT_REF = "pauqmhqriyjdqctvfvtt"

# IMPORTANT: Remplace cette valeur par ta service_role key
# Trouve-la dans: Supabase Dashboard > Settings > API > service_role (secret)
$SERVICE_ROLE_KEY = "REMPLACE_PAR_TA_SERVICE_ROLE_KEY"

$headers = @{
    "apikey" = $SERVICE_ROLE_KEY
    "Authorization" = "Bearer $SERVICE_ROLE_KEY"
    "Content-Type" = "application/json"
}

$baseUrl = "https://$PROJECT_REF.supabase.co/auth/v1/admin/users"

# Utilisateurs à créer
$users = @(
    @{
        email = "client@test.com"
        password = "test123456"
        user_metadata = @{
            full_name = "Ahmed Client"
            phone = "0555123456"
            role = "customer"
        }
    },
    @{
        email = "restaurant@test.com"
        password = "test123456"
        user_metadata = @{
            full_name = "Karim Restaurant"
            phone = "0555234567"
            role = "restaurant"
        }
    },
    @{
        email = "livreur@test.com"
        password = "test123456"
        user_metadata = @{
            full_name = "Yacine Livreur"
            phone = "0555345678"
            role = "livreur"
        }
    }
)

foreach ($user in $users) {
    $body = @{
        email = $user.email
        password = $user.password
        email_confirm = $true
        user_metadata = $user.user_metadata
    } | ConvertTo-Json -Depth 3

    Write-Host "Creation de $($user.email)..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri $baseUrl -Method POST -Headers $headers -Body $body
        Write-Host "OK: $($user.email) cree avec succes!" -ForegroundColor Green
    }
    catch {
        $errorMsg = $_.ErrorDetails.Message | ConvertFrom-Json
        if ($errorMsg.msg -like "*already been registered*") {
            Write-Host "INFO: $($user.email) existe deja" -ForegroundColor Cyan
        } else {
            Write-Host "ERREUR: $($errorMsg.msg)" -ForegroundColor Red
        }
    }
}

Write-Host "`nTermine! Teste la connexion avec:" -ForegroundColor Green
Write-Host "  Email: client@test.com" -ForegroundColor White
Write-Host "  Password: test123456" -ForegroundColor White
