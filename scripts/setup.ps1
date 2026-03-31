# Script de configuration initiale pour OCR-UVT-Web (Windows)
# Ce script automatise la configuration initiale du projet

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Configuration initiale d'OCR-UVT-Web" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Vérifier si nous sommes à la racine du projet
if (-not (Test-Path "render.yaml") -or -not (Test-Path "vercel.json")) {
    Write-Host "Erreur: Ce script doit être exécuté à la racine du projet OCR-UVT-Web" -ForegroundColor Red
    exit 1
}

# Étape 1: Préparation du frontend
Write-Host ""
Write-Host "Étape 1: Préparation du frontend..." -ForegroundColor Yellow

Set-Location web

if (Test-Path "index.html.new") {
    Write-Host "Remplacement de index.html par la version améliorée..." -ForegroundColor Green

    if (Test-Path "index.html") {
        Move-Item -Path "index.html" -Destination "index.html.old" -Force
    }

    Move-Item -Path "index.html.new" -Destination "index.html" -Force
    Write-Host "✓ index.html remplacé avec succès" -ForegroundColor Green
} else {
    Write-Host "⚠ Le fichier index.html.new n'existe pas, utilisation de l'index.html actuel" -ForegroundColor Yellow
}

Set-Location ..

# Étape 2: Création du fichier .env
Write-Host ""
Write-Host "Étape 2: Configuration des variables d'environnement..." -ForegroundColor Yellow

if (-not (Test-Path ".env")) {
    Write-Host "Création du fichier .env à partir de .env.example..." -ForegroundColor Green
    Copy-Item -Path ".env.example" -Destination ".env"
    Write-Host "✓ Fichier .env créé" -ForegroundColor Green
    Write-Host "⚠ N'oubliez pas de modifier les valeurs dans .env selon votre environnement" -ForegroundColor Yellow
} else {
    Write-Host "⚠ Le fichier .env existe déjà, conservation de la version actuelle" -ForegroundColor Yellow
}

# Étape 3: Initialisation du dépôt Git
Write-Host ""
Write-Host "Étape 3: Initialisation du dépôt Git..." -ForegroundColor Yellow

if (-not (Test-Path ".git")) {
    Write-Host "Initialisation du dépôt Git..." -ForegroundColor Green
    git init
    Write-Host "✓ Dépôt Git initialisé" -ForegroundColor Green
} else {
    Write-Host "⚠ Le dépôt Git existe déjà" -ForegroundColor Yellow
}

# Étape 4: Installation des dépendances
Write-Host ""
Write-Host "Étape 4: Installation des dépendances..." -ForegroundColor Yellow

Write-Host "Installation des dépendances Python..." -ForegroundColor Green
Set-Location api

if (Test-Path "requirements.txt") {
    pip install -r requirements.txt
    Write-Host "✓ Dépendances Python installées" -ForegroundColor Green
} else {
    Write-Host "⚠ Le fichier requirements.txt n'existe pas" -ForegroundColor Yellow
}

Set-Location ..

# Étape 5: Vérification de la structure
Write-Host ""
Write-Host "Étape 5: Vérification de la structure du projet..." -ForegroundColor Yellow

$requiredFiles = @(
    "render.yaml",
    "vercel.json",
    "api/main.py",
    "api/requirements.txt",
    "docker/Dockerfile.render",
    "web/index.html",
    "web/app.js",
    ".env.example",
    ".github/workflows/deploy.yml"
)

$missingFiles = @()

foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -eq 0) {
    Write-Host "✓ Tous les fichiers requis sont présents" -ForegroundColor Green
} else {
    Write-Host "⚠ Fichiers manquants :" -ForegroundColor Yellow
    foreach ($file in $missingFiles) {
        Write-Host "  - $file" -ForegroundColor Red
    }
}

# Étape 6: Résumé
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Résumé de la configuration" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ Configuration initiale terminée" -ForegroundColor Green
Write-Host ""
Write-Host "Prochaines étapes :" -ForegroundColor Yellow
Write-Host "1. Modifier le fichier .env selon votre environnement" -ForegroundColor White
Write-Host "2. Créer un dépôt sur GitHub" -ForegroundColor White
Write-Host "3. Configurer les secrets GitHub (voir CI_CD.md)" -ForegroundColor White
Write-Host "4. Déployer le backend sur Render (voir DEPLOYMENT.md)" -ForegroundColor White
Write-Host "5. Déployer le frontend sur Vercel (voir DEPLOYMENT.md)" -ForegroundColor White
Write-Host ""
Write-Host "Pour plus de détails, consultez le fichier NEXT_STEPS.md" -ForegroundColor Cyan
Write-Host ""
