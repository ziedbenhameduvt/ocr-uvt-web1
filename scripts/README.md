# Scripts d'automatisation pour OCR-UVT-Web

Ce répertoire contient des scripts PowerShell pour automatiser diverses tâches liées au déploiement et à la maintenance de l'application OCR-UVT-Web.

## Scripts disponibles

### 1. setup.ps1 - Configuration initiale

Ce script automatise la configuration initiale du projet OCR-UVT-Web.

**Utilisation :**
```powershell
cd c:\Projects\ocr-uvt-web
.\scripts\setup.ps1
```

**Ce qu'il fait :**
- Remplace le fichier `index.html` par la version améliorée
- Crée le fichier `.env` à partir de `.env.example`
- Initialise le dépôt Git (si nécessaire)
- Installe les dépendances Python
- Vérifie la structure du projet

**Quand l'utiliser :**
- Lors de la première configuration du projet
- Après avoir cloné le dépôt pour la première fois
- Pour vérifier que tous les fichiers nécessaires sont présents

### 2. test-local.ps1 - Test local

Ce script permet de tester localement le backend et le frontend.

**Utilisation :**
```powershell
cd c:\Projects\ocr-uvt-web
.\scripts	est-local.ps1
```

**Ce qu'il fait :**
- Vérifie que Python est installé
- Installe les dépendances Python
- Démarre le backend sur http://localhost:8000
- Démarre le frontend sur http://localhost:8080
- Teste tous les endpoints backend
- Teste la communication frontend-backend

**Quand l'utiliser :**
- Avant de déployer pour vérifier que tout fonctionne localement
- Après avoir apporté des modifications au code
- Pour tester de nouvelles fonctionnalités

**Arrêt :**
Appuyez sur Ctrl+C pour arrêter les serveurs.

### 3. deploy.ps1 - Déploiement

Ce script facilite le déploiement de l'application sur Render et Vercel.

**Utilisation :**
```powershell
cd c:\Projects\ocr-uvt-web
.\scripts\deploy.ps1
```

**Ce qu'il fait :**
- Vérifie que Git est installé
- Vérifie que le dépôt Git est initialisé
- Commit les modifications non commitées
- Vérifie la branche actuelle
- Vérifie l'URL Render
- Vérifie la connexion GitHub
- Pousse les modifications vers GitHub

**Quand l'utiliser :**
- Pour déployer une nouvelle version de l'application
- Après avoir apporté des modifications importantes
- Pour mettre à jour le déploiement existant

**Prérequis :**
- Git installé
- Dépôt GitHub configuré
- Comptes Render et Vercel configurés

### 4. check-deployment.ps1 - Vérification du déploiement

Ce script vérifie l'état de l'application après déploiement.

**Utilisation :**
```powershell
cd c:\Projects\ocr-uvt-web
.\scripts\check-deployment.ps1
```

**Ce qu'il fait :**
- Récupère les URLs de déploiement
- Teste tous les endpoints backend
- Teste le frontend
- Teste la communication frontend-backend
- Affiche les métriques système
- Fournit un résumé de l'état du déploiement

**Quand l'utiliser :**
- Après un déploiement pour vérifier que tout fonctionne
- Pour surveiller régulièrement l'état de l'application
- Pour diagnostiquer des problèmes de déploiement

## Flux de travail recommandé

### Premier déploiement

1. Exécutez `setup.ps1` pour configurer le projet
2. Modifiez le fichier `.env` selon votre environnement
3. Exécutez `test-local.ps1` pour tester localement
4. Configurez les dépôts Render et Vercel
5. Exécutez `deploy.ps1` pour déployer
6. Exécutez `check-deployment.ps1` pour vérifier le déploiement

### Déploiements ultérieurs

1. Apportez vos modifications au code
2. Exécutez `test-local.ps1` pour tester localement
3. Exécutez `deploy.ps1` pour déployer
4. Exécutez `check-deployment.ps1` pour vérifier le déploiement

### Maintenance régulière

1. Exécutez `check-deployment.ps1` régulièrement pour surveiller l'état de l'application
2. Consultez les métriques système pour identifier les problèmes potentiels
3. Apportez des améliorations basées sur les métriques

## Dépannage

### Erreur lors de l'exécution des scripts

Si vous rencontrez une erreur lors de l'exécution des scripts, vérifiez que :
- Vous exécutez PowerShell avec les droits nécessaires
- Vous êtes à la racine du projet OCR-UVT-Web
- Les fichiers requis sont présents dans le projet

### Problèmes de déploiement

Si le déploiement échoue :
- Consultez les logs Render et Vercel
- Vérifiez que les variables d'environnement sont correctement configurées
- Consultez le guide DEPLOYMENT.md pour plus de détails

### Problèmes de test local

Si les tests locaux échouent :
- Vérifiez que Python est installé
- Vérifiez que les ports 8000 et 8080 ne sont pas déjà utilisés
- Consultez les logs du backend et du frontend pour plus de détails

## Ressources supplémentaires

- [Guide de déploiement](../DEPLOYMENT.md)
- [Guide CI/CD](../CI_CD.md)
- [Guide de monitoring](../MONITORING.md)
- [Guide de sécurité](../SECURITY.md)
- [Prochaines étapes](../NEXT_STEPS.md)
