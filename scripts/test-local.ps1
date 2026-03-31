# Script de test local pour OCR-UVT-Web (Windows)
# Ce script permet de tester localement le backend et le frontend

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Test local d'OCR-UVT-Web" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Vérifier si nous sommes à la racine du projet
if (-not (Test-Path "api/main.py") -or -not (Test-Path "web/index.html")) {
    Write-Host "Erreur: Ce script doit être exécuté à la racine du projet OCR-UVT-Web" -ForegroundColor Red
    exit 1
}

# Étape 1: Vérification des dépendances Python
Write-Host ""
Write-Host "Étape 1: Vérification des dépendances Python..." -ForegroundColor Yellow

try {
    $pythonVersion = python --version 2>&1
    Write-Host "✓ Python installé: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Python n'est pas installé ou non trouvé dans le PATH" -ForegroundColor Red
    exit 1
}

# Étape 2: Installation des dépendances Python
Write-Host ""
Write-Host "Étape 2: Installation des dépendances Python..." -ForegroundColor Yellow

Set-Location api

if (Test-Path "requirements.txt") {
    try {
        pip install -r requirements.txt
        Write-Host "✓ Dépendances Python installées" -ForegroundColor Green
    } catch {
        Write-Host "✗ Erreur lors de l'installation des dépendances Python" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✗ Le fichier requirements.txt n'existe pas" -ForegroundColor Red
    exit 1
}

Set-Location ..

# Étape 3: Démarrage du backend
Write-Host ""
Write-Host "Étape 3: Démarrage du backend..." -ForegroundColor Yellow

$backendProcess = Start-Process -FilePath "python" -ArgumentList "-m uvicorn api.main:app --host 0.0.0.0 --port 8000" -PassThru -WindowStyle Hidden

Write-Host "✓ Backend démarré sur http://localhost:8000" -ForegroundColor Green
Write-Host "⚠ Appuyez sur Ctrl+C pour arrêter le backend" -ForegroundColor Yellow

# Attendre que le backend soit prêt
Write-Host "Attente du démarrage du backend..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

# Étape 4: Test des endpoints backend
Write-Host ""
Write-Host "Étape 4: Test des endpoints backend..." -ForegroundColor Yellow

$endpoints = @(
    "http://localhost:8000/",
    "http://localhost:8000/api/health",
    "http://localhost:8000/api/health/detailed",
    "http://localhost:8000/api/metrics"
)

foreach ($endpoint in $endpoints) {
    try {
        $response = Invoke-WebRequest -Uri $endpoint -UseBasicParsing
        Write-Host "✓ $endpoint - Status: $($response.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "✗ $endpoint - Erreur: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Étape 5: Démarrage du frontend
Write-Host ""
Write-Host "Étape 5: Démarrage du frontend..." -ForegroundColor Yellow

# Vérifier si un serveur HTTP est disponible
$frontendPort = 8080
$frontendUrl = "http://localhost:$frontendPort"

# Utiliser Python pour servir le frontend si disponible
try {
    $frontendProcess = Start-Process -FilePath "python" -ArgumentList "-m http.server $frontendPort --directory web" -PassThru -WindowStyle Hidden
    Write-Host "✓ Frontend démarré sur $frontendUrl" -ForegroundColor Green
} catch {
    Write-Host "✗ Impossible de démarrer le frontend avec Python" -ForegroundColor Red
    Write-Host "⚠ Veuillez démarrer le frontend manuellement" -ForegroundColor Yellow
    $frontendProcess = $null
}

# Étape 6: Test de communication frontend-backend
Write-Host ""
Write-Host "Étape 6: Test de communication frontend-backend..." -ForegroundColor Yellow

if ($frontendProcess) {
    try {
        $response = Invoke-WebRequest -Uri "$frontendUrl" -UseBasicParsing
        Write-Host "✓ Frontend accessible sur $frontendUrl" -ForegroundColor Green
    } catch {
        Write-Host "✗ Frontend non accessible sur $frontendUrl" -ForegroundColor Red
    }
}

# Étape 7: Résumé
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Résumé des tests" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ Backend: http://localhost:8000" -ForegroundColor Green
Write-Host "✓ Frontend: $frontendUrl" -ForegroundColor Green
Write-Host "✓ Documentation API: http://localhost:8000/docs" -ForegroundColor Green
Write-Host ""
Write-Host "Pour arrêter les serveurs, appuyez sur Ctrl+C" -ForegroundColor Yellow

# Attendre que l'utilisateur appuie sur Ctrl+C
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    Write-Host ""
    Write-Host "Arrêt des serveurs..." -ForegroundColor Yellow

    if ($backendProcess) {
        Stop-Process -Id $backendProcess.Id -Force
        Write-Host "✓ Backend arrêté" -ForegroundColor Green
    }

    if ($frontendProcess) {
        Stop-Process -Id $frontendProcess.Id -Force
        Write-Host "✓ Frontend arrêté" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "Tests terminés" -ForegroundColor Cyan
}
