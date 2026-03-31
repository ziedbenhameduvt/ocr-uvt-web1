# Guide de sécurité pour OCR-UVT-Web

Ce guide présente les mesures de sécurité à mettre en place pour votre application OCR-UVT-Web.

## Sécurité du Backend (Render)

### 1. Variables d'environnement

Toutes les informations sensibles doivent être stockées dans des variables d'environnement :

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

# Secrets (à ajouter dans Render)
# DATABASE_URL=...
# API_KEY=...
# SECRET_KEY=...
```

### 2. Validation des entrées

Le backend implémente déjà une validation des entrées :
- Vérification du type de fichier (PDF uniquement)
- Validation de la taille du fichier (max 10MB)
- Validation des paramètres de requête

### 3. Rate Limiting

L'API utilise `slowapi` pour le rate limiting :
- 20 requêtes/minute pour le traitement de documents
- 30 requêtes/minute pour l'historique
- 5 requêtes/minute pour la suppression de l'historique
- 10 requêtes/minute pour les métriques

### 4. Gestion des erreurs

Les messages d'erreur ne révèlent pas d'informations sensibles :
- Les erreurs système sont journalisées mais pas exposées aux clients
- Les messages d'erreur sont génériques pour les utilisateurs finaux
- Les détails techniques sont disponibles dans les logs

### 5. Headers de sécurité

Le backend devrait inclure les headers de sécurité suivants :

```python
from fastapi.middleware.httpsredirect import HTTPSRedirectMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware

# Redirection HTTPS
app.add_middleware(HTTPSRedirectMiddleware)

# Hôtes de confiance
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["ocr-uvt-api.onrender.com", "localhost"]
)
```

## Sécurité du Frontend (Vercel)

### 1. Headers de sécurité

Le fichier `vercel.json` configure déjà les headers de sécurité suivants :
- X-Content-Type-Options: nosniff
- X-Frame-Options: DENY
- X-XSS-Protection: 1; mode=block

Vous pouvez ajouter d'autres headers de sécurité :

```json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Strict-Transport-Security",
          "value": "max-age=31536000; includeSubDomains"
        },
        {
          "key": "Content-Security-Policy",
          "value": "default-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net;"
        },
        {
          "key": "Referrer-Policy",
          "value": "strict-origin-when-cross-origin"
        },
        {
          "key": "Permissions-Policy",
          "value": "geolocation=(), microphone=(), camera=()"
        }
      ]
    }
  ]
}
```

### 2. Validation des entrées

Le frontend devrait valider les entrées côté client avant de les envoyer au backend :
- Type de fichier
- Taille du fichier
- Format des données

### 3. Protection XSS

Le frontend utilise déjà des pratiques de protection XSS :
- Échappement automatique des données par le navigateur
- Utilisation de `textContent` au lieu de `innerHTML` lorsque possible
- Validation des entrées utilisateur

### 4. Gestion des erreurs

Les erreurs sont affichées de manière sécurisée :
- Pas d'exposition de détails techniques
- Messages d'erreur génériques pour les utilisateurs
- Logging des erreurs côté serveur

## Bonnes pratiques de sécurité

### 1. Gestion des secrets

- Ne jamais commiter de secrets dans le dépôt
- Utiliser des variables d'environnement pour stocker les secrets
- Faire régulièrement la rotation des secrets
- Utiliser des secrets différents pour les environnements dev/staging/prod

### 2. Mises à jour régulières

- Maintenir les dépendances à jour
- Appliquer les correctifs de sécurité rapidement
- Surveiller les vulnérabilités connues des dépendances

### 3. Surveillance de la sécurité

- Surveiller les logs pour les activités suspectes
- Configurer des alertes pour les tentatives d'intrusion
- Effectuer des audits de sécurité réguliers
- Utiliser des outils de scan de vulnérabilités

### 4. Tests de sécurité

- Effectuer des tests de pénétration réguliers
- Utiliser des outils d'analyse de code statique
- Effectuer des revues de code régulières
- Tester les scénarios d'attaque courants

### 5. Documentation

- Documenter les mesures de sécurité en place
- Créer des procédures de réponse aux incidents
- Former l'équipe aux bonnes pratiques de sécurité
- Maintenir un registre des incidents de sécurité

## Outils de sécurité recommandés

### Scan de vulnérabilités des dépendances

```bash
# Pour Python
pip install safety
safety check

# Pour JavaScript
npm install -g auditjs
auditjs ossi
```

### Analyse de code statique

```bash
# Pour Python
pip install bandit
bandit -r api/

# Pour JavaScript
npm install -g eslint
eslint web/
```

### Tests de sécurité automatisés

```bash
# OWASP ZAP
docker run -t owasp/zap2docker-stable zap-baseline.py -t https://ocr-uvt-api.onrender.com

# Nuclei
nuclei -u https://ocr-uvt-api.onrender.com -t cves/
```

## Réponse aux incidents de sécurité

En cas d'incident de sécurité :

1. **Identifier et contenir** l'incident
2. **Investiguer** pour comprendre la cause
3. **Notifier** les parties concernées
4. **Résoudre** le problème
5. **Documenter** l'incident
6. **Apprendre** et améliorer les processus

## Ressources supplémentaires

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [FastAPI Security](https://fastapi.tiangolo.com/tutorial/security/)
- [Vercel Security](https://vercel.com/docs/security)
- [Render Security](https://render.com/docs/security)
