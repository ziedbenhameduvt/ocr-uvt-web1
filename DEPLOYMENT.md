# Guide de déploiement OCR-UVT-Web

Ce guide explique comment déployer l'application OCR-UVT-Web sur Render (backend) et Vercel (frontend).

## Prérequis

- Compte Render (https://render.com)
- Compte Vercel (https://vercel.com)
- Repository Git avec le code de l'application

## Déploiement du Backend sur Render

### 1. Préparation du dépôt

Assurez-vous que votre dépôt Git contient tous les fichiers nécessaires :
- `api/main.py` - Code de l'API FastAPI
- `api/requirements.txt` - Dépendances Python
- `docker/Dockerfile.render` - Configuration Docker pour Render
- `render.yaml` - Configuration du service Render
- `.env.example` - Exemple de variables d'environnement

### 2. Création d'un nouveau service Web sur Render

1. Connectez-vous à votre compte Render
2. Cliquez sur "New +" puis "Web Service"
3. Connectez votre dépôt Git
4. Configurez le service :
   - Name: ocr-uvt-api (ou le nom de votre choix)
   - Region: Choisissez la région la plus proche de vos utilisateurs
   - Branch: main (ou votre branche principale)
   - Runtime: Docker
   - DockerfilePath: ./docker/Dockerfile.render
   - Instance Type: Free (pour tester) ou Standard (pour la production)

### 3. Configuration des variables d'environnement

Ajoutez les variables d'environnement suivantes dans la section "Environment" :

```
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

### 4. Déploiement

Cliquez sur "Create Web Service" pour déployer votre backend. Render va automatiquement :
- Construire l'image Docker
- Démarrer le service
- Exécuter les health checks

Une fois le déploiement terminé, vous aurez une URL du type : `https://ocr-uvt-api.onrender.com`

### 5. Vérification du déploiement

Vérifiez que votre API fonctionne en accédant à :
- `https://ocr-uvt-api.onrender.com/` - Racine de l'API
- `https://ocr-uvt-api.onrender.com/api/health` - Health check
- `https://ocr-uvt-api.onrender.com/docs` - Documentation Swagger

## Déploiement du Frontend sur Vercel

### 1. Préparation du dépôt

Assurez-vous que votre dépôt Git contient tous les fichiers nécessaires :
- `web/index.html` - Page principale de l'application
- `vercel.json` - Configuration Vercel

### 2. Création d'un nouveau projet sur Vercel

1. Connectez-vous à votre compte Vercel
2. Cliquez sur "Add New..." puis "Project"
3. Importez votre dépôt Git
4. Configurez le projet :
   - Project Name: ocr-uvt-web (ou le nom de votre choix)
   - Framework Preset: Other
   - Root Directory: . (racine du dépôt)
   - Build Command: (laisser vide pour un site statique)
   - Output Directory: web

### 3. Configuration des variables d'environnement

Ajoutez les variables d'environnement suivantes si nécessaire :
```
NEXT_PUBLIC_API_URL=https://ocr-uvt-api.onrender.com
```

### 4. Déploiement

Cliquez sur "Deploy" pour déployer votre frontend. Vercel va automatiquement :
- Détecter la configuration dans `vercel.json`
- Configurer les routes et les rewrites
- Déployer votre application

Une fois le déploiement terminé, vous aurez une URL du type : `https://ocr-uvt-web.vercel.app`

### 5. Vérification du déploiement

Accédez à `https://ocr-uvt-web.vercel.app` et vérifiez que :
- L'interface se charge correctement
- L'état de l'API affiche "En ligne"
- Vous pouvez télécharger et traiter des fichiers PDF

## Mise à jour de l'application

Pour mettre à jour l'application :

1. Effectuez vos modifications dans le code
2. Committez et poussez vos modifications vers votre dépôt Git
3. Render et Vercel détecteront automatiquement les modifications et redéploieront l'application

## Surveillance et maintenance

### Backend (Render)

- Consultez les logs dans le dashboard Render
- Surveillez les métriques de performance (CPU, mémoire, réseau)
- Configurez des alertes pour les erreurs et les temps de réponse élevés

### Frontend (Vercel)

- Consultez les logs dans le dashboard Vercel
- Surveillez les métriques de performance (temps de chargement, taux d'erreur)
- Utilisez Analytics Vercel pour suivre l'utilisation

## Dépannage

### Problèmes de connexion entre Frontend et Backend

Si le frontend ne peut pas communiquer avec le backend :

1. Vérifiez que l'URL du backend est correcte dans `vercel.json`
2. Vérifiez la configuration CORS dans `api/main.py`
3. Consultez les logs du backend sur Render pour identifier les erreurs

### Erreurs de déploiement

Si le déploiement échoue :

1. Consultez les logs de déploiement sur Render ou Vercel
2. Vérifiez que toutes les variables d'environnement sont correctement configurées
3. Assurez-vous que toutes les dépendances sont correctement listées dans `requirements.txt`

### Problèmes de performance

Si l'application est lente :

1. Augmentez le nombre de workers uvicorn (variable `UVICORN_WORKERS`)
2. Optimisez les images avant traitement
3. Envisagez d'augmenter les ressources sur Render (plan Standard ou Pro)
