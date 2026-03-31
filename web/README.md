# Frontend OCR-UVT-Web

Ce répertoire contient le frontend de l'application OCR-UVT-Web.

## Structure des fichiers

- `index.html` - Page principale de l'application (à remplacer par index.html.new)
- `index.html.new` - Version améliorée de la page principale avec code JavaScript séparé
- `app.js` - Code JavaScript de l'application

## Mise à jour du fichier index.html

Pour utiliser la nouvelle version améliorée du frontend, remplacez le fichier `index.html` par `index.html.new` :

```bash
cd web
mv index.html index.html.old
mv index.html.new index.html
```

## Fonctionnalités

- Interface utilisateur pour l'OCR de documents PDF
- Sélection de la langue de reconnaissance
- Drag & drop pour le téléchargement de fichiers
- Affichage des résultats de l'OCR
- Gestion des erreurs avec retry automatique
- Vérification du statut de l'API en temps réel

## Déploiement sur Vercel

Le frontend est configuré pour être déployé sur Vercel. Le fichier `vercel.json` à la racine du projet contient la configuration nécessaire.

## Variables d'environnement

Aucune variable d'environnement n'est requise pour le frontend. L'URL de l'API backend est configurée dans le fichier `vercel.json` à la racine du projet.
