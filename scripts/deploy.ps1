# Script de déploiement pour OCR-UVT-Web (Windows)
# Ce script facilite le déploiement sur Render et Vercel

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Déploiement d'OCR-UVT-Web" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Vérifier si nous sommes à la racine du projet
if (-not (Test-Path "render.yaml") -or -not (Test-Path "vercel.json")) {
    Write-Host "Erreur: Ce script doit être exécuté à la racine du projet OCR-UVT-Web" -ForegroundColor Red
    exit 1
}

# Étape 1: Vérification des prérequis
Write-Host ""
Write-Host "Étape 1: Vérification des prérequis..." -ForegroundColor Yellow

# Vérifier Git
try {
    $gitVersion = git --version 2>&1
    Write-Host "✓ Git installé: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Git n'est pas installé ou non trouvé dans le PATH" -ForegroundColor Red
    Write-Host "⚠ Veuillez installer Git: https://git-scm.com/downloads" -ForegroundColor Yellow
    exit 1
}

# Vérifier si le dépôt Git est initialisé
if (-not (Test-Path ".git")) {
    Write-Host "⚠ Le dépôt Git n'est pas initialisé" -ForegroundColor Yellow
    $initGit = Read-Host "Voulez-vous initialiser le dépôt Git maintenant? (O/N)"
    if ($initGit -eq "O" -or $initGit -eq "o") {
        git init
        Write-Host "✓ Dépôt Git initialisé" -ForegroundColor Green
    } else {
        Write-Host "✗ Impossible de continuer sans dépôt Git initialisé" -ForegroundColor Red
        exit 1
    }
}

# Étape 2: Vérification des modifications
Write-Host ""
Write-Host "Étape 2: Vérification des modifications..." -ForegroundColor Yellow

$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "⚠ Des modifications non commitées ont été détectées" -ForegroundColor Yellow
    Write-Host "Modifications:" -ForegroundColor White
    Write-Host $gitStatus
    $commitChanges = Read-Host "Voulez-vous commiter ces modifications maintenant? (O/N)"
    if ($commitChanges -eq "O" -or $commitChanges -eq "o") {
        $commitMessage = Read-Host "Entrez un message de commit"
        git add .
        git commit -m $commitMessage
        Write-Host "✓ Modifications commitées" -ForegroundColor Green
    } else {
        Write-Host "✗ Impossible de continuer sans commiter les modifications" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✓ Aucune modification non commitée détectée" -ForegroundColor Green
}

# Étape 3: Vérification de la branche
Write-Host ""
Write-Host "Étape 3: Vérification de la branche..." -ForegroundColor Yellow

$currentBranch = git rev-parse --abbrev-ref HEAD
Write-Host "Branche actuelle: $currentBranch" -ForegroundColor White

if ($currentBranch -ne "main") {
    Write-Host "⚠ Vous n'êtes pas sur la branche principale" -ForegroundColor Yellow
    $switchBranch = Read-Host "Voulez-vous basculer vers la branche main? (O/N)"
    if ($switchBranch -eq "O" -or $switchBranch -eq "o") {
        git checkout main
        Write-Host "✓ Basculé vers la branche main" -ForegroundColor Green
    }
}

# Étape 4: Vérification du déploiement Render
Write-Host ""
Write-Host "Étape 4: Vérification du déploiement Render..." -ForegroundColor Yellow

$renderUrlFile = "scriptsender-url.txt"
if (Test-Path $renderUrlFile) {
    $renderUrl = Get-Content $renderUrlFile
    Write-Host "✓ URL Render détectée: $renderUrl" -ForegroundColor Green
} else {
    Write-Host "⚠ Aucune URL Render détectée" -ForegroundColor Yellow
    $renderUrl = Read-Host "Entrez l'URL de votre API Render (ex: https://ocr-uvt-api.onrender.com)"
    if ($renderUrl) {
        New-Item -Path $renderUrlFile -ItemType File -Force | Out-Null
        Set-Content -Path $renderUrlFile -Value $renderUrl
        git add $renderUrlFile
        git commit -m "Update Render API URL"
        Write-Host "✓ URL Render enregistrée" -ForegroundColor Green
    } else {
        Write-Host "⚠ URL Render non fournie, le déploiement peut ne pas fonctionner correctement" -ForegroundColor Yellow
    }
}

# Étape 5: Vérification de la connexion GitHub
Write-Host ""
Write-Host "Étape 5: Vérification de la connexion GitHub..." -ForegroundColor Yellow

try {
    $remoteUrl = git remote get-url origin 2>&1
    if ($remoteUrl) {
        Write-Host "✓ Dépôt distant détecté: $remoteUrl" -ForegroundColor Green
    } else {
        Write-Host "⚠ Aucun dépôt distant configuré" -ForegroundColor Yellow
        $setupRemote = Read-Host "Voulez-vous configurer un dépôt distant maintenant? (O/N)"
        if ($setupRemote -eq "O" -or $setupRemote -eq "o") {
            $remoteUrl = Read-Host "Entrez l'URL du dépôt distant (ex: https://github.com/username/ocr-uvt-web.git)"
            git remote add origin $remoteUrl
            Write-Host "✓ Dépôt distant configuré" -ForegroundColor Green
        } else {
            Write-Host "⚠ Le déploiement automatique ne fonctionnera pas sans dépôt distant" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "✗ Erreur lors de la vérification du dépôt distant" -ForegroundColor Red
}

# Étape 6: Pousser les modifications
Write-Host ""
Write-Host "Étape 6: Pousser les modifications..." -ForegroundColor Yellow

if ($remoteUrl) {
    try {
        git push origin main
        Write-Host "✓ Modifications poussées vers GitHub" -ForegroundColor Green
    } catch {
        Write-Host "✗ Erreur lors du push vers GitHub" -ForegroundColor Red
        Write-Host "⚠ Veuillez vérifier vos identifiants GitHub" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "⚠ Aucun dépôt distant configuré, impossible de pousser les modifications" -ForegroundColor Yellow
}

# Étape 7: Vérification du déploiement
Write-Host ""
Write-Host "Étape 7: Vérification du déploiement..." -ForegroundColor Yellow

Write-Host "⚠ Le déploiement automatique est en cours sur Render et Vercel" -ForegroundColor Cyan
Write-Host "⚠ Cela peut prendre quelques minutes" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pour suivre le déploiement:" -ForegroundColor Yellow
Write-Host "  - Render: https://dashboard.render.com" -ForegroundColor White
Write-Host "  - Vercel: https://vercel.com/dashboard" -ForegroundColor White
Write-Host "  - GitHub Actions: https://github.com/YOUR_USERNAME/ocr-uvt-web/actions" -ForegroundColor White
Write-Host ""

# Étape 8: Résumé
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Résumé du déploiement" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ Modifications poussées vers GitHub" -ForegroundColor Green
Write-Host "✓ Déploiement automatique en cours" -ForegroundColor Green
Write-Host ""
Write-Host "URLs de déploiement:" -ForegroundColor Yellow
Write-Host "  - Backend: $renderUrl" -ForegroundColor White
Write-Host "  - Frontend: https://ocr-uvt-web.vercel.app" -ForegroundColor White
Write-Host ""
Write-Host "Pour plus de détails, consultez:" -ForegroundColor Yellow
Write-Host "  - DEPLOYMENT.md" -ForegroundColor White
Write-Host "  - CI_CD.md" -ForegroundColor White
Write-Host ""
