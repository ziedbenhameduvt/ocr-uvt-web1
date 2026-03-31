# OCR UVT Web Application

Cette application web fournit une interface pour l'OCR (Reconnaissance Optique de Caractères) avec support multilingue (arabe, français, anglais).

## Architecture

- **API FastAPI**: Service backend qui expose des endpoints pour l'OCR
- **Frontend**: Interface web moderne pour interagir avec l'API
- **Nginx**: Serveur web qui sert le frontend et proxy les requêtes vers l'API

## Prérequis

- Docker (version 20.10 ou supérieure)
- Docker Compose (version 1.29 ou supérieure)

## Déploiement

1. Clonez le repository:
   ```bash
   git clone <repository-url>
   cd ocr-uvt-web
   ```

2. Vérifiez que Docker et Docker Compose sont installés:
   ```bash
   docker --version
   docker-compose --version
   ```

3. Déployez l'application avec Docker Compose:
   ```bash
   docker-compose up -d
   ```

4. Vérifiez que les services sont en cours d'exécution:
   ```bash
   docker-compose ps
   ```

5. Vérifiez les logs pour vous assurer que tout fonctionne correctement:
   ```bash
   docker-compose logs -f
   ```

6. Accédez à l'application:
   - Frontend: http://localhost
   - API: http://localhost:8000
   - Documentation API: http://localhost:8000/docs
   - État de l'API: http://localhost:8000/api/health

## Utilisation

1. Ouvrez votre navigateur et accédez à http://localhost
2. Sélectionnez la langue de reconnaissance (par défaut: français, arabe et anglais)
3. Glissez-déposez une image ou cliquez pour sélectionner un fichier
4. Cliquez sur "Traiter l'image" pour lancer l'OCR
5. Le texte extrait s'affichera dans la zone de résultat
6. Vous pouvez copier le texte ou effacer le résultat pour recommencer

## Gestion des services

- Arrêter les services:
  ```bash
  docker-compose stop
  ```

- Redémarrer les services:
  ```bash
  docker-compose restart
  ```

- Voir les logs:
  ```bash
  docker-compose logs -f
  ```

- Voir les logs d'un service spécifique:
  ```bash
  docker-compose logs -f api
  docker-compose logs -f web
  ```

- Arrêter et supprimer les conteneurs:
  ```bash
  docker-compose down
  ```

- Mettre à jour l'application après des modifications:
  ```bash
  docker-compose down
  docker-compose up -d --build
  ```

## Structure du projet

```
ocr-uvt-web/
├── api/              # Code de l'API FastAPI
│   ├── main.py       # Point d'entrée de l'API
│   └── requirements.txt # Dépendances Python
├── docker/           # Configuration Docker
│   └── Dockerfile    # Image Docker pour l'API
├── web/              # Frontend
│   └── index.html    # Page principale
├── docker-compose.yml # Configuration Docker Compose
├── nginx.conf        # Configuration Nginx
└── README.md         # Documentation
```

## Dépannage

### Les services ne démarrent pas

1. Vérifiez les logs pour identifier le problème:
   ```bash
   docker-compose logs
   ```

2. Vérifiez que les ports 80 et 8000 ne sont pas déjà utilisés:
   ```bash
   # Sur Linux/Mac
   lsof -i :80
   lsof -i :8000
   
   # Sur Windows
   netstat -ano | findstr :80
   netstat -ano | findstr :8000
   ```

### L'API ne répond pas

1. Vérifiez que le service API est en cours d'exécution:
   ```bash
   docker-compose ps api
   ```

2. Vérifiez les logs de l'API:
   ```bash
   docker-compose logs api
   ```

3. Testez l'endpoint de santé directement:
   ```bash
   curl http://localhost:8000/api/health
   ```

### L'OCR ne fonctionne pas correctement

1. Vérifiez que les paquets de langue Tesseract sont installés dans le conteneur:
   ```bash
   docker-compose exec api tesseract --list-langs
   ```

2. Vérifiez les logs de l'API pour les erreurs:
   ```bash
   docker-compose logs api
   ```

## Support

Pour toute question ou problème, veuillez ouvrir une issue sur le repository.
