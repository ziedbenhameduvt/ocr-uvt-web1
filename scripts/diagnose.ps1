# Script de diagnostic pour OCR-UVT-Web (Windows)
# Ce script aide à identifier les problèmes de configuration ou d'exécution

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Diagnostic d'OCR-UVT-Web" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Étape 1: Vérification de Python
Write-Host ""
Write-Host "Étape 1: Vérification de Python..." -ForegroundColor Yellow

try {
    $pythonVersion = python --version 2>&1
    Write-Host "✓ Python installé: $pythonVersion" -ForegroundColor Green

    # Vérifier les modules Python
    Write-Host "Vérification des modules Python..." -ForegroundColor Cyan

    $modules = @("fastapi", "uvicorn", "pytesseract", "PIL", "psutil", "slowapi")
    foreach ($module in $modules) {
        try {
            python -c "import $module; print('$module OK')"
        } catch {
            Write-Host "✗ Module $module non installé" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "✗ Python n'est pas installé ou non trouvé dans le PATH" -ForegroundColor Red
    exit 1
}

# Étape 2: Vérification de la structure du projet
Write-Host ""
Write-Host "Étape 2: Vérification de la structure du projet..." -ForegroundColor Yellow

$requiredFiles = @(
    "api/main.py",
    "api/requirements.txt",
    "web/index.html",
    "web/app.js",
    "render.yaml",
    "vercel.json",
    ".env.example"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✓ $file" -ForegroundColor Green
    } else {
        Write-Host "✗ $file manquant" -ForegroundColor Red
    }
}

# Étape 3: Vérification des variables d'environnement
Write-Host ""
Write-Host "Étape 3: Vérification des variables d'environnement..." -ForegroundColor Yellow

if (Test-Path ".env") {
    Write-Host "✓ Fichier .env présent" -ForegroundColor Green

    # Vérifier les variables importantes
    $envContent = Get-Content ".env"
    $requiredVars = @("PORT", "LOG_LEVEL", "FRONTEND_URL")

    foreach ($var in $requiredVars) {
        if ($envContent -match "$var=") {
            Write-Host "  ✓ $var configuré" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ $var non configuré" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "⚠ Fichier .env absent, utilisation des valeurs par défaut" -ForegroundColor Yellow
}

# Étape 4: Vérification des ports
Write-Host ""
Write-Host "Étape 4: Vérification des ports..." -ForegroundColor Yellow

$ports = @(8000, 8080)
foreach ($port in $ports) {
    try {
        $connection = Test-NetConnection -ComputerName localhost -Port $port -InformationLevel Quiet
        if ($connection) {
            Write-Host "⚠ Port $port déjà utilisé" -ForegroundColor Yellow
        } else {
            Write-Host "✓ Port $port disponible" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠ Impossible de vérifier le port $port" -ForegroundColor Yellow
    }
}

# Étape 5: Test de démarrage du backend
Write-Host ""
Write-Host "Étape 5: Test de démarrage du backend..." -ForegroundColor Yellow

try {
    # Créer un répertoire temporaire pour les logs
    $tempDir = Join-Path $env:TEMP "ocr-uvt-backend-logs"
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir | Out-Null
    }

    $logFile = Join-Path $tempDir "backend-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

    # Démarrer le backend avec redirection des logs
    $backendProcess = Start-Process -FilePath "python" -ArgumentList "-m uvicorn api.main:app --host 0.0.0.0 --port 8000" -RedirectStandardOutput $logFile -RedirectStandardError $logFile -PassThru -WindowStyle Hidden

    Write-Host "✓ Backend démarré (PID: $($backendProcess.Id))" -ForegroundColor Green
    Write-Host "  Logs: $logFile" -ForegroundColor Cyan

    # Attendre que le backend démarre
    Write-Host "  Attente du démarrage du backend (10s)..." -ForegroundColor Cyan
    Start-Sleep -Seconds 10

    # Vérifier si le processus est toujours en cours d'exécution
    if (-not (Get-Process -Id $backendProcess.Id -ErrorAction SilentlyContinue)) {
        Write-Host "✗ Le backend s'est arrêté prématurément" -ForegroundColor Red
        Write-Host "  Vérifiez les logs: $logFile" -ForegroundColor Yellow

        # Afficher les 20 dernières lignes du log
        if (Test-Path $logFile) {
            Write-Host ""
            Write-Host "Dernières lignes du log:" -ForegroundColor Yellow
            Get-Content $logFile -Tail 20
        }
    } else {
        # Tester l'endpoint de santé
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8000/api/health" -UseBasicParsing -TimeoutSec 5
            Write-Host "✓ Backend répond correctement" -ForegroundColor Green
            Write-Host "  Status: $($response.StatusCode)" -ForegroundColor White

            # Arrêter le backend
            Stop-Process -Id $backendProcess.Id -Force
            Write-Host "✓ Backend arrêté" -ForegroundColor Green
        } catch {
            Write-Host "✗ Le backend ne répond pas aux requêtes" -ForegroundColor Red
            Write-Host "  Vérifiez les logs: $logFile" -ForegroundColor Yellow

            # Arrêter le backend
            Stop-Process -Id $backendProcess.Id -Force -ErrorAction SilentlyContinue

            # Afficher les 50 dernières lignes du log
            if (Test-Path $logFile) {
                Write-Host ""
                Write-Host "Dernières lignes du log:" -ForegroundColor Yellow
                Get-Content $logFile -Tail 50
            }
        }
    }
} catch {
    Write-Host "✗ Erreur lors du démarrage du backend: $($_.Exception.Message)" -ForegroundColor Red
}

# Étape 6: Vérification de Tesseract
Write-Host ""
Write-Host "Étape 6: Vérification de Tesseract..." -ForegroundColor Yellow

try {
    $tesseractVersion = python -c "import pytesseract; print(pytesseract.get_tesseract_version())" 2>&1
    Write-Host "✓ Tesseract détecté: $tesseractVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠ Tesseract non détecté via pytesseract" -ForegroundColor Yellow
    Write-Host "  Tesseract doit être installé séparément" -ForegroundColor Yellow
    Write-Host "  Téléchargez-le depuis: https://github.com/UB-Mannheim/tesseract/wiki" -ForegroundColor Cyan
}

# Étape 7: Résumé
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Résumé du diagnostic" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Si des problèmes ont été détectés:" -ForegroundColor Yellow
Write-Host "1. Consultez les logs du backend (voir étape 5)" -ForegroundColor White
Write-Host "2. Vérifiez que Tesseract est installé" -ForegroundColor White
Write-Host "3. Vérifiez que les ports 8000 et 8080 sont disponibles" -ForegroundColor White
Write-Host "4. Consultez le fichier DEPLOYMENT.md pour plus de détails" -ForegroundColor White
Write-Host ""
