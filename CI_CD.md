# Guide de configuration CI/CD avec GitHub Actions

Ce guide explique comment configurer le déploiement automatique de votre application OCR-UVT-Web sur Render (backend) et Vercel (frontend) en utilisant GitHub Actions.

## Prérequis

- Compte GitHub avec accès administrateur au dépôt
- Compte Render avec service backend déjà créé
- Compte Vercel avec projet frontend déjà créé

## Configuration des secrets GitHub

Vous devez configurer les secrets suivants dans votre dépôt GitHub :

### Pour Render (Backend)

1. **RENDER_SERVICE_ID**
   - Connectez-vous à votre compte Render
   - Allez sur votre service ocr-uvt-api
   - L'ID du service se trouve dans l'URL : `https://dashboard.render.com/web/services/{RENDER_SERVICE_ID}`
   - Copiez cet ID et ajoutez-le comme secret GitHub

2. **RENDER_API_KEY**
   - Connectez-vous à votre compte Render
   - Allez dans Settings > API Keys
   - Cliquez sur "Create API Key"
   - Donnez un nom descriptif (ex: "GitHub Actions")
   - Copiez la clé générée et ajoutez-la comme secret GitHub

### Pour Vercel (Frontend)

1. **VERCEL_TOKEN**
   - Connectez-vous à votre compte Vercel
   - Allez dans Settings > Tokens
   - Cliquez sur "Create"
   - Donnez un nom descriptif (ex: "GitHub Actions")
   - Sélectionnez les scopes nécessaires (Full Account)
   - Copiez le token généré et ajoutez-le comme secret GitHub

2. **VERCEL_ORG_ID**
   - Connectez-vous à votre compte Vercel
   - Allez dans Settings > General
   - Copiez l'ID de l'organisation et ajoutez-le comme secret GitHub

3. **VERCEL_PROJECT_ID**
   - Connectez-vous à votre compte Vercel
   - Allez sur votre projet ocr-uvt-web
   - Allez dans Settings > General
   - Copiez l'ID du projet et ajoutez-le comme secret GitHub

## Workflow de déploiement

Le workflow `.github/workflows/deploy.yml` est configuré pour :

1. Se déclencher automatiquement lors d'un push sur la branche `main`
2. Déployer le backend sur Render
3. Déployer le frontend sur Vercel en production

## Personnalisation du workflow

Vous pouvez personnaliser le workflow en modifiant le fichier `.github/workflows/deploy.yml` :

### Modifier la branche de déploiement

```yaml
on:
  push:
    branches: [ main ]  # Remplacez 'main' par votre branche principale
```

### Ajouter des étapes de test

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Run tests
        run: |
          # Ajoutez vos commandes de test ici
          echo "Running tests..."
```

### Ajouter des notifications

Vous pouvez ajouter des notifications par email ou Slack en cas d'échec du déploiement :

```yaml
- name: Notify failure
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: 'Deployment failed!'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## Surveillance des déploiements

### Surveiller les workflows GitHub

1. Allez dans l'onglet "Actions" de votre dépôt GitHub
2. Sélectionnez le workflow "Deploy OCR-UVT-Web"
3. Vous verrez l'historique des exécutions et leur statut

### Surveiller les déploiements Render

1. Connectez-vous à votre compte Render
2. Allez sur votre service ocr-uvt-api
3. Consultez l'onglet "Events" pour voir l'historique des déploiements

### Surveiller les déploiements Vercel

1. Connectez-vous à votre compte Vercel
2. Allez sur votre projet ocr-uvt-web
3. Consultez l'onglet "Deployments" pour voir l'historique des déploiements

## Dépannage

### Le workflow échoue avec une erreur d'authentification

Vérifiez que tous les secrets sont correctement configurés dans GitHub :
- RENDER_SERVICE_ID
- RENDER_API_KEY
- VERCEL_TOKEN
- VERCEL_ORG_ID
- VERCEL_PROJECT_ID

### Le déploiement Render échoue

1. Vérifiez que le service backend existe sur Render
2. Vérifiez que RENDER_SERVICE_ID est correct
3. Vérifiez que RENDER_API_KEY a les permissions nécessaires
4. Consultez les logs du workflow GitHub pour plus de détails

### Le déploiement Vercel échoue

1. Vérifiez que le projet frontend existe sur Vercel
2. Vérifiez que VERCEL_TOKEN, VERCEL_ORG_ID et VERCEL_PROJECT_ID sont corrects
3. Vérifiez que le fichier vercel.json est correctement configuré
4. Consultez les logs du workflow GitHub pour plus de détails

## Bonnes pratiques

1. **Utilisez des branches de fonctionnalités** pour développer de nouvelles fonctionnalités
2. **Faites des pull requests** pour fusionner les modifications dans la branche principale
3. **Testez localement** avant de pousser vos modifications
4. **Surveillez les déploiements** pour détecter rapidement les problèmes
5. **Gardez vos secrets à jour** en les régénérant régulièrement

## Ressources supplémentaires

- [Documentation GitHub Actions](https://docs.github.com/en/actions)
- [Documentation Render](https://render.com/docs)
- [Documentation Vercel](https://vercel.com/docs)
