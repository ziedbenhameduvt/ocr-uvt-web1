# Script de vérification du déploiement pour OCR-UVT-Web (Windows)
# Ce script vérifie l'état de l'application après déploiement

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Vérification du déploiement OCR-UVT-Web" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Étape 1: Récupération des URLs de déploiement
Write-Host ""
Write-Host "Étape 1: Récupération des URLs de déploiement..." -ForegroundColor Yellow

# URL Render (Backend)
$renderUrlFile = "scriptsender-url.txt"
if (Test-Path $renderUrlFile) {
    $renderUrl = Get-Content $renderUrlFile
    Write-Host "✓ URL Render détectée: $renderUrl" -ForegroundColor Green
} else {
    $renderUrl = Read-Host "Entrez l'URL de votre API Render (ex: https://ocr-uvt-api.onrender.com)"
    if ($renderUrl) {
        New-Item -Path $renderUrlFile -ItemType File -Force | Out-Null
        Set-Content -Path $renderUrlFile -Value $renderUrl
        Write-Host "✓ URL Render enregistrée" -ForegroundColor Green
    } else {
        Write-Host "✗ URL Render non fournie, impossible de continuer" -ForegroundColor Red
        exit 1
    }
}

# URL Vercel (Frontend)
$vercelUrl = "https://ocr-uvt-web.vercel.app"
Write-Host "✓ URL Vercel: $vercelUrl" -ForegroundColor Green

# Étape 2: Test du backend Render
Write-Host ""
Write-Host "Étape 2: Test du backend Render..." -ForegroundColor Yellow

$backendEndpoints = @(
    @{Name="Racine"; Url="$renderUrl/"},
    @{Name="Health Check"; Url="$renderUrl/api/health"},
    @{Name="Health Check Détaillé"; Url="$renderUrl/api/health/detailed"},
    @{Name="Métriques"; Url="$renderUrl/api/metrics"},
    @{Name="Documentation"; Url="$renderUrl/docs"}
)

$backendStatus = $true

foreach ($endpoint in $backendEndpoints) {
    try {
        $response = Invoke-WebRequest -Uri $endpoint.Url -UseBasicParsing -TimeoutSec 30
        if ($response.StatusCode -eq 200) {
            Write-Host "✓ $($endpoint.Name): $($endpoint.Url) - Status: $($response.StatusCode)" -ForegroundColor Green
        } else {
            Write-Host "⚠ $($endpoint.Name): $($endpoint.Url) - Status: $($response.StatusCode)" -ForegroundColor Yellow
            $backendStatus = $false
        }
    } catch {
        Write-Host "✗ $($endpoint.Name): $($endpoint.Url) - Erreur: $($_.Exception.Message)" -ForegroundColor Red
        $backendStatus = $false
    }
}

# Étape 3: Test du frontend Vercel
Write-Host ""
Write-Host "Étape 3: Test du frontend Vercel..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri $vercelUrl -UseBasicParsing -TimeoutSec 30
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ Frontend: $vercelUrl - Status: $($response.StatusCode)" -ForegroundColor Green
        $frontendStatus = $true
    } else {
        Write-Host "⚠ Frontend: $vercelUrl - Status: $($response.StatusCode)" -ForegroundColor Yellow
        $frontendStatus = $false
    }
} catch {
    Write-Host "✗ Frontend: $vercelUrl - Erreur: $($_.Exception.Message)" -ForegroundColor Red
    $frontendStatus = $false
}

# Étape 4: Test de communication frontend-backend
Write-Host ""
Write-Host "Étape 4: Test de communication frontend-backend..." -ForegroundColor Yellow

try {
    # Vérifier si le frontend peut accéder à l'API
    $apiHealthUrl = "$vercelUrl/api/health"
    $response = Invoke-WebRequest -Uri $apiHealthUrl -UseBasicParsing -TimeoutSec 30
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ Communication frontend-backend: OK" -ForegroundColor Green
        $communicationStatus = $true
    } else {
        Write-Host "⚠ Communication frontend-backend: Status $($response.StatusCode)" -ForegroundColor Yellow
        $communicationStatus = $false
    }
} catch {
    Write-Host "✗ Communication frontend-backend: Erreur $($_.Exception.Message)" -ForegroundColor Red
    $communicationStatus = $false
}

# Étape 5: Vérification des métriques système
Write-Host ""
Write-Host "Étape 5: Vérification des métriques système..." -ForegroundColor Yellow

try {
    $metricsUrl = "$renderUrl/api/metrics"
    $response = Invoke-WebRequest -Uri $metricsUrl -UseBasicParsing -TimeoutSec 30
    $metrics = $response.Content | ConvertFrom-Json

    Write-Host "Métriques système:" -ForegroundColor White
    Write-Host "  - Traitements totaux: $($metrics.total_processed)" -ForegroundColor White
    Write-Host "  - Traitements réussis: $($metrics.successful)" -ForegroundColor White
    Write-Host "  - Traitements échoués: $($metrics.failed)" -ForegroundColor White
    Write-Host "  - Temps moyen: $($metrics.avg_processing_time_ms)ms" -ForegroundColor White
    Write-Host "  - Dernières 24h: $($metrics.last_24h_processed)" -ForegroundColor White
} catch {
    Write-Host "⚠ Impossible de récupérer les métriques système" -ForegroundColor Yellow
}

# Étape 6: Résumé
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Résumé du déploiement" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "État du backend Render:" -ForegroundColor Yellow
if ($backendStatus) {
    Write-Host "  ✓ Opérationnel" -ForegroundColor Green
} else {
    Write-Host "  ✗ Problèmes détectés" -ForegroundColor Red
}

Write-Host "État du frontend Vercel:" -ForegroundColor Yellow
if ($frontendStatus) {
    Write-Host "  ✓ Opérationnel" -ForegroundColor Green
} else {
    Write-Host "  ✗ Problèmes détectés" -ForegroundColor Red
}

Write-Host "Communication frontend-backend:" -ForegroundColor Yellow
if ($communicationStatus) {
    Write-Host "  ✓ Opérationnelle" -ForegroundColor Green
} else {
    Write-Host "  ✗ Problèmes détectés" -ForegroundColor Red
}

Write-Host ""
Write-Host "URLs de déploiement:" -ForegroundColor Yellow
Write-Host "  - Backend: $renderUrl" -ForegroundColor White
Write-Host "  - Frontend: $vercelUrl" -ForegroundColor White
Write-Host ""

if ($backendStatus -and $frontendStatus -and $communicationStatus) {
    Write-Host "✓ Déploiement réussi!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Prochaines étapes:" -ForegroundColor Yellow
    Write-Host "  1. Configurer le monitoring (voir MONITORING.md)" -ForegroundColor White
    Write-Host "  2. Mettre en place les mesures de sécurité (voir SECURITY.md)" -ForegroundColor White
    Write-Host "  3. Surveiller les métriques régulièrement" -ForegroundColor White
} else {
    Write-Host "⚠ Problèmes détectés lors du déploiement" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Actions recommandées:" -ForegroundColor Yellow
    Write-Host "  1. Vérifier les logs Render pour le backend" -ForegroundColor White
    Write-Host "  2. Vérifier les logs Vercel pour le frontend" -ForegroundColor White
    Write-Host "  3. Consulter DEPLOYMENT.md pour résoudre les problèmes" -ForegroundColor White
}

Write-Host ""
Write-Host "Pour plus de détails, consultez:" -ForegroundColor Yellow
Write-Host "  - DEPLOYMENT.md" -ForegroundColor White
Write-Host "  - MONITORING.md" -ForegroundColor White
Write-Host "  - SECURITY.md" -ForegroundColor White
Write-Host ""
