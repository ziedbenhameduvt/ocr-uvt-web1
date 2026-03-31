# Script de démarrage du backend en mode verbose pour OCR-UVT-Web (Windows)
# Ce script démarre le backend en affichant les logs en temps réel

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Démarrage du backend OCR-UVT-Web" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Vérifier si nous sommes à la racine du projet
if (-not (Test-Path "api/main.py")) {
    Write-Host "Erreur: Ce script doit être exécuté à la racine du projet OCR-UVT-Web" -ForegroundColor Red
    exit 1
}

# Vérifier que le port 8000 est disponible
Write-Host ""
Write-Host "Vérification du port 8000..." -ForegroundColor Yellow

$portInUse = Test-NetConnection -ComputerName localhost -Port 8000 -InformationLevel Quiet
if ($portInUse) {
    Write-Host "✗ Le port 8000 est déjà utilisé" -ForegroundColor Red
    Write-Host "⚠ Veuillez arrêter l'application qui utilise ce port" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "✓ Port 8000 disponible" -ForegroundColor Green
}

# Démarrer le backend en mode verbose
Write-Host ""
Write-Host "Démarrage du backend..." -ForegroundColor Yellow
Write-Host "⚠ Appuyez sur Ctrl+C pour arrêter le backend" -ForegroundColor Yellow
Write-Host ""

try {
    # Démarrer le backend avec uvicorn en mode verbose
    python -m uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload
} catch {
    Write-Host ""
    Write-Host "✗ Erreur lors du démarrage du backend: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Pour plus de détails, consultez:" -ForegroundColor Yellow
    Write-Host "  - Les logs ci-dessus" -ForegroundColor White
    Write-Host "  - Le fichier api/main.py" -ForegroundColor White
    Write-Host "  - Le fichier DEPLOYMENT.md" -ForegroundColor White
    exit 1
}
