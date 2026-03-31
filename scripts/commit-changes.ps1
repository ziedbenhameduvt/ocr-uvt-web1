# Script pour committer les modifications du projet OCR-UVT-Web
$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Commit des modifications" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Ajouter tous les fichiers modifiés
Write-Host ""
Write-Host "Ajout des fichiers modifiés..." -ForegroundColor Yellow
git add api/main.py scripts/check-deployment.ps1 scripts/deploy.ps1 scripts/diagnose.ps1 scripts/test-local.ps1 scripts/start-backend.ps1

# Committer les modifications
Write-Host ""
Write-Host "Commit des modifications..." -ForegroundColor Yellow
git commit -m "Correction: Ajout de l'argument request aux fonctions avec limiteur de taux

- Ajout de l'argument request: Request aux fonctions get_metrics, process_document, get_history, get_stats et clear_history
- Ajout du script start-backend.ps1 pour démarrer le backend
- Amélioration des scripts de déploiement et de test"

Write-Host ""
Write-Host "✓ Modifications commitées avec succès" -ForegroundColor Green
