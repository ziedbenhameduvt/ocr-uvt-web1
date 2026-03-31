#!/bin/bash

# Script de configuration initiale pour OCR-UVT-Web
# Ce script automatise la configuration initiale du projet

set -e  # Arrêter le script en cas d'erreur

echo "=========================================="
echo "Configuration initiale d'OCR-UVT-Web"
echo "=========================================="

# Vérifier si nous sommes à la racine du projet
if [ ! -f "render.yaml" ] || [ ! -f "vercel.json" ]; then
    echo "Erreur: Ce script doit être exécuté à la racine du projet OCR-UVT-Web"
    exit 1
fi

# Étape 1: Préparation du frontend
echo ""
echo "Étape 1: Préparation du frontend..."
cd web

if [ -f "index.html.new" ]; then
    echo "Remplacement de index.html par la version améliorée..."
    mv index.html index.html.old 2>/dev/null || true
    mv index.html.new index.html
    echo "✓ index.html remplacé avec succès"
else
    echo "⚠ Le fichier index.html.new n'existe pas, utilisation de l'index.html actuel"
fi

cd ..

# Étape 2: Création du fichier .env
echo ""
echo "Étape 2: Configuration des variables d'environnement..."

if [ ! -f ".env" ]; then
    echo "Création du fichier .env à partir de .env.example..."
    cp .env.example .env
    echo "✓ Fichier .env créé"
    echo "⚠ N'oubliez pas de modifier les valeurs dans .env selon votre environnement"
else
    echo "⚠ Le fichier .env existe déjà, conservation de la version actuelle"
fi

# Étape 3: Initialisation du dépôt Git
echo ""
echo "Étape 3: Initialisation du dépôt Git..."

if [ ! -d ".git" ]; then
    echo "Initialisation du dépôt Git..."
    git init
    echo "✓ Dépôt Git initialisé"
else
    echo "⚠ Le dépôt Git existe déjà"
fi

# Étape 4: Installation des dépendances
echo ""
echo "Étape 4: Installation des dépendances..."

echo "Installation des dépendances Python..."
cd api
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    echo "✓ Dépendances Python installées"
else
    echo "⚠ Le fichier requirements.txt n'existe pas"
fi
cd ..

# Étape 5: Vérification de la structure
echo ""
echo "Étape 5: Vérification de la structure du projet..."

required_files=(
    "render.yaml"
    "vercel.json"
    "api/main.py"
    "api/requirements.txt"
    "docker/Dockerfile.render"
    "web/index.html"
    "web/app.js"
    ".env.example"
    ".github/workflows/deploy.yml"
)

missing_files=()

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -eq 0 ]; then
    echo "✓ Tous les fichiers requis sont présents"
else
    echo "⚠ Fichiers manquants :"
    for file in "${missing_files[@]}"; do
        echo "  - $file"
    done
fi

# Étape 6: Résumé
echo ""
echo "=========================================="
echo "Résumé de la configuration"
echo "=========================================="
echo ""
echo "✓ Configuration initiale terminée"
echo ""
echo "Prochaines étapes :"
echo "1. Modifier le fichier .env selon votre environnement"
echo "2. Créer un dépôt sur GitHub"
echo "3. Configurer les secrets GitHub (voir CI_CD.md)"
echo "4. Déployer le backend sur Render (voir DEPLOYMENT.md)"
echo "5. Déployer le frontend sur Vercel (voir DEPLOYMENT.md)"
echo ""
echo "Pour plus de détails, consultez le fichier NEXT_STEPS.md"
echo ""
