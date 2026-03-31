# Prochaines étapes recommandées - Guide complet

Ce guide détaille les prochaines étapes pour finaliser et optimiser le déploiement de votre application OCR-UVT-Web.

## Étape 1 : Préparation du frontend

### 1.1 Remplacer le fichier index.html par la version améliorée

```bash
cd web
mv index.html index.html.old
mv index.html.new index.html
```

### 1.2 Vérifier la structure du frontend

Assurez-vous que les fichiers suivants sont présents dans le répertoire `web/` :
- `index.html` (version améliorée)
- `app.js` (code JavaScript séparé)

### 1.3 Tester localement le frontend

```bash
# Option 1: Avec un serveur Python
cd web
python -m http.server 8080

# Option 2: Avec Node.js
cd web
npx serve
```

Ouvrez votre navigateur et accédez à `http://localhost:8080` pour vérifier que tout fonctionne correctement.

## Étape 2 : Préparation du backend

### 2.1 Vérifier les dépendances Python

```bash
cd api
pip install -r requirements.txt
```

### 2.2 Tester localement le backend

```bash
cd api
uvicorn main:app --host 0.0.0.0 --port 8000
```

Vérifiez que les endpoints suivants fonctionnent :
- `http://localhost:8000/` - Racine de l'API
- `http://localhost:8000/api/health` - Health check
- `http://localhost:8000/api/health/detailed` - Health check détaillé
- `http://localhost:8000/api/metrics` - Métriques
- `http://localhost:8000/docs` - Documentation Swagger

### 2.3 Tester le traitement OCR

```bash
# Utiliser curl pour tester l'endpoint de traitement
curl -X POST "http://localhost:8000/api/ocr/process"   -F "file=@test.pdf"   -F "template={type}_{numero}_{beneficiaire}_{annee}.pdf"   -F "use_ai=false"
```

## Étape 3 : Configuration des variables d'environnement

### 3.1 Créer le fichier .env

```bash
# À la racine du projet
cp .env.example .env
```

### 3.2 Adapter les variables d'environnement

Éditez le fichier `.env` pour adapter les valeurs à votre environnement :

```bash
# Configuration de l'application
PORT=8000
LOG_LEVEL=INFO

# Configuration CORS
FRONTEND_URL=https://ocr-uvt-web.vercel.app
LOCAL_FRONTEND_URLS=http://localhost:3000,http://localhost:8080

# Limites de l'application
MAX_FILE_SIZE=10485760
UVICORN_WORKERS=4
OCR_TIMEOUT=60
```

## Étape 4 : Préparation du dépôt Git

### 4.1 Initialiser le dépôt (si nécessaire)

```bash
cd c:\Projects\ocr-uvt-web
git init
```

### 4.2 Créer le fichier .gitignore

Assurez-vous que le fichier `.gitignore` existe et contient les éléments sensibles :

```bash
# Variables d'environnement
.env

# Base de données
*.db
*.sqlite
*.sqlite3

# Fichiers temporaires
temp_uploads/
*.tmp

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log
```

### 4.3 Commiter les modifications

```bash
git add .
git commit -m "Initial commit: Configuration de déploiement OCR-UVT-Web"
```

### 4.4 Créer les branches

```bash
# Créer une branche principale
git branch -M main

# Créer une branche de développement (optionnel)
git checkout -b develop
```

## Étape 5 : Configuration du CI/CD avec GitHub Actions

### 5.1 Créer un dépôt sur GitHub

1. Connectez-vous à votre compte GitHub
2. Créez un nouveau dépôt nommé `ocr-uvt-web`
3. Suivez les instructions pour pousser votre dépôt local

```bash
git remote add origin https://github.com/VOTRE_USERNAME/ocr-uvt-web.git
git push -u origin main
```

### 5.2 Configurer les secrets GitHub

Suivez le guide `CI_CD.md` pour configurer les secrets suivants :

#### Pour Render (Backend)
- RENDER_SERVICE_ID
- RENDER_API_KEY

#### Pour Vercel (Frontend)
- VERCEL_TOKEN
- VERCEL_ORG_ID
- VERCEL_PROJECT_ID

### 5.3 Vérifier le workflow GitHub Actions

1. Allez dans l'onglet "Actions" de votre dépôt GitHub
2. Sélectionnez le workflow "Deploy OCR-UVT-Web"
3. Vérifiez que le workflow est bien configuré

## Étape 6 : Déploiement du backend sur Render

### 6.1 Créer un compte Render

1. Connectez-vous à https://render.com
2. Créez un compte (gratuit)
3. Vérifiez votre adresse email

### 6.2 Créer un nouveau service Web

1. Cliquez sur "New +" puis "Web Service"
2. Connectez votre dépôt GitHub
3. Configurez le service :
   - Name: ocr-uvt-api
   - Region: Choisissez la région la plus proche de vos utilisateurs
   - Branch: main
   - Runtime: Docker
   - DockerfilePath: ./docker/Dockerfile.render
   - Instance Type: Free (pour tester) ou Standard (pour la production)

### 6.3 Configurer les variables d'environnement

Ajoutez les variables d'environnement suivantes dans la section "Environment" :

```bash
PORT=8000
PYTHONUNBUFFERED=1
DEFAULT_LANGUAGE=eng+fra+ara
LOG_LEVEL=INFO
FRONTEND_URL=https://ocr-uvt-web.vercel.app
LOCAL_FRONTEND_URLS=http://localhost:3000,http://localhost:8080
MAX_FILE_SIZE=10485760
UVICORN_WORKERS=4
OCR_TIMEOUT=60
```

### 6.4 Déployer le service

Cliquez sur "Create Web Service" pour déployer votre backend. Render va automatiquement :
- Construire l'image Docker
- Démarrer le service
- Exécuter les health checks

### 6.5 Vérifier le déploiement

Une fois le déploiement terminé, vous aurez une URL du type : `https://ocr-uvt-api.onrender.com`

Vérifiez que votre API fonctionne en accédant à :
- `https://ocr-uvt-api.onrender.com/` - Racine de l'API
- `https://ocr-uvt-api.onrender.com/api/health` - Health check
- `https://ocr-uvt-api.onrender.com/api/health/detailed` - Health check détaillé
- `https://ocr-uvt-api.onrender.com/api/metrics` - Métriques
- `https://ocr-uvt-api.onrender.com/docs` - Documentation Swagger

### 6.6 Mettre à jour le fichier scripts/render-url.txt

```bash
echo "https://ocr-uvt-api.onrender.com" > scripts/render-url.txt
git add scripts/render-url.txt
git commit -m "Update Render API URL"
git push
```

## Étape 7 : Déploiement du frontend sur Vercel

### 7.1 Créer un compte Vercel

1. Connectez-vous à https://vercel.com
2. Créez un compte (gratuit)
3. Connectez votre compte GitHub

### 7.2 Créer un nouveau projet

1. Cliquez sur "Add New..." puis "Project"
2. Importez votre dépôt GitHub `ocr-uvt-web`
3. Configurez le projet :
   - Project Name: ocr-uvt-web
   - Framework Preset: Other
   - Root Directory: .
   - Build Command: (laisser vide pour un site statique)
   - Output Directory: web

### 7.3 Configurer les variables d'environnement (si nécessaire)

Ajoutez les variables d'environnement suivantes si nécessaire :
```bash
NEXT_PUBLIC_API_URL=https://ocr-uvt-api.onrender.com
```

### 7.4 Déployer le projet

Cliquez sur "Deploy" pour déployer votre frontend. Vercel va automatiquement :
- Détecter la configuration dans `vercel.json`
- Configurer les routes et les rewrites
- Déployer votre application

### 7.5 Vérifier le déploiement

Une fois le déploiement terminé, vous aurez une URL du type : `https://ocr-uvt-web.vercel.app`

Accédez à `https://ocr-uvt-web.vercel.app` et vérifiez que :
- L'interface se charge correctement
- L'état de l'API affiche "En ligne"
- Vous pouvez télécharger et traiter des fichiers PDF

## Étape 8 : Configuration du monitoring

### 8.1 Configurer les alertes Render

Suivez le guide `MONITORING.md` pour configurer des alertes sur Render :
- Utilisation CPU > 80%
- Utilisation mémoire > 80%
- Temps de réponse > 5s
- Taux d'erreur > 5%

### 8.2 Configurer le monitoring Vercel

Suivez le guide `MONITORING.md` pour configurer le monitoring sur Vercel :
- Activer Vercel Analytics
- Configurer des outils de monitoring tiers (UptimeRobot, Better Uptime, etc.)
- Intégrer des outils de tracking d'erreurs (Sentry, LogRocket)

### 8.3 Créer un tableau de bord de monitoring

Suivez le guide `MONITORING.md` pour créer un tableau de bord centralisé avec Grafana ou Datadog.

## Étape 9 : Mise en place des mesures de sécurité

### 9.1 Configurer les headers de sécurité

Suivez le guide `SECURITY.md` pour configurer les headers de sécurité sur Vercel :
- Strict-Transport-Security
- Content-Security-Policy
- Referrer-Policy
- Permissions-Policy

### 9.2 Effectuer un audit de sécurité

Suivez le guide `SECURITY.md` pour effectuer un audit de sécurité :
- Scan de vulnérabilités des dépendances
- Analyse de code statique
- Tests de sécurité automatisés

### 9.3 Configurer les alertes de sécurité

Configurez des alertes pour être notifié des incidents de sécurité :
- Tentatives d'intrusion
- Vulnérabilités découvertes
- Activités suspectes

## Étape 10 : Optimisation continue

### 10.1 Surveiller les performances

Utilisez les outils de monitoring pour identifier les goulots d'étranglement :
- Temps de réponse élevé
- Utilisation CPU/mémoire élevée
- Taux d'erreur élevé

### 10.2 Optimiser les performances

Apportez des améliorations basées sur les métriques :
- Augmenter le nombre de workers si nécessaire
- Optimiser les requêtes OCR
- Mettre en cache les résultats fréquents

### 10.3 Améliorer l'expérience utilisateur

Apportez des améliorations basées sur les retours utilisateurs :
- Messages d'erreur plus clairs
- Interface plus intuitive
- Temps de chargement réduit

## Étape 11 : Maintenance régulière

### 11.1 Mises à jour régulières

- Maintenir les dépendances à jour
- Appliquer les correctifs de sécurité rapidement
- Surveiller les vulnérabilités connues des dépendances

### 11.2 Sauvegardes régulières

- Sauvegarder la base de données régulièrement
- Sauvegarder les fichiers de configuration
- Documenter les modifications importantes

### 11.3 Revues régulières

- Examiner les métriques et les alertes périodiquement
- Effectuer des revues de code régulières
- Planifier des améliorations futures

## Étape 12 : Documentation et formation

### 12.1 Maintenir la documentation à jour

- Documenter les nouvelles fonctionnalités
- Mettre à jour les guides de déploiement
- Documenter les incidents et leur résolution

### 12.2 Former l'équipe

- Former l'équipe aux bonnes pratiques de sécurité
- Former l'équipe à l'utilisation des outils de monitoring
- Former l'équipe aux procédures de réponse aux incidents

## Checklist de déploiement

Avant de considérer le déploiement comme terminé, vérifiez que :

- [ ] Le fichier `index.html` a été remplacé par la version améliorée
- [ ] Le backend fonctionne localement
- [ ] Le frontend fonctionne localement
- [ ] Les variables d'environnement sont configurées
- [ ] Le dépôt Git est initialisé et configuré
- [ ] Les secrets GitHub sont configurés
- [ ] Le backend est déployé sur Render
- [ ] Le frontend est déployé sur Vercel
- [ ] La communication frontend-backend fonctionne
- [ ] Le monitoring est configuré
- [ ] Les alertes sont configurées
- [ ] Les mesures de sécurité sont en place
- [ ] La documentation est à jour
- [ ] L'équipe est formée

## Ressources supplémentaires

- [Guide de déploiement](DEPLOYMENT.md)
- [Guide CI/CD](CI_CD.md)
- [Guide de monitoring](MONITORING.md)
- [Guide de sécurité](SECURITY.md)
- [Documentation FastAPI](https://fastapi.tiangolo.com/)
- [Documentation Render](https://render.com/docs)
- [Documentation Vercel](https://vercel.com/docs)
