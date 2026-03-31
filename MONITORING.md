# Guide de monitoring pour OCR-UVT-Web

Ce guide explique comment configurer le monitoring et les alertes pour votre application OCR-UVT-Web déployée sur Render (backend) et Vercel (frontend).

## Monitoring du Backend (Render)

### 1. Consultation des logs

1. Connectez-vous à votre compte Render
2. Allez sur votre service ocr-uvt-api
3. Cliquez sur l'onglet "Logs"
4. Vous verrez les logs en temps réel de votre application

### 2. Surveillance des métriques

Render fournit automatiquement les métriques suivantes :
- Utilisation CPU
- Utilisation mémoire
- Réseau (entrée/sortie)
- Temps de réponse

Pour consulter ces métriques :
1. Connectez-vous à votre compte Render
2. Allez sur votre service ocr-uvt-api
3. Cliquez sur l'onglet "Metrics"

### 3. Utilisation des endpoints de monitoring

Votre backend dispose de plusieurs endpoints pour le monitoring :

#### Health Check basique
```
GET /api/health
```
Retourne le statut de base de l'API.

#### Health Check détaillé
```
GET /api/health/detailed
```
Retourne des informations détaillées sur :
- Statut de l'API
- Utilisation système (CPU, mémoire, disque)
- État de la base de données
- État du répertoire temporaire

#### Métriques d'utilisation
```
GET /api/metrics
```
Retourne des métriques sur l'utilisation de l'API :
- Nombre total de traitements
- Nombre de traitements réussis/échoués
- Temps de traitement moyen/min/max
- Nombre de traitements des dernières 24h

### 4. Configuration des alertes Render

Pour configurer des alertes sur Render :

1. Connectez-vous à votre compte Render
2. Allez sur votre service ocr-uvt-api
3. Cliquez sur "Alerts"
4. Cliquez sur "New Alert"
5. Configurez les conditions d'alerte :
   - Utilisation CPU > 80%
   - Utilisation mémoire > 80%
   - Temps de réponse > 5s
   - Taux d'erreur > 5%
6. Configurez les notifications :
   - Email
   - Slack (via webhook)
   - PagerDuty
7. Cliquez sur "Create Alert"

## Monitoring du Frontend (Vercel)

### 1. Consultation des logs

1. Connectez-vous à votre compte Vercel
2. Allez sur votre projet ocr-uvt-web
3. Cliquez sur l'onglet "Logs"
4. Vous verrez les logs de votre application

### 2. Surveillance des métriques

Vercel Analytics fournit les métriques suivantes :
- Temps de chargement
- First Contentful Paint (FCP)
- Largest Contentful Paint (LCP)
- Cumulative Layout Shift (CLS)
- Taux de rebond
- Pages vues

Pour consulter ces métriques :
1. Connectez-vous à votre compte Vercel
2. Allez sur votre projet ocr-uvt-web
3. Cliquez sur l'onglet "Analytics"

### 3. Configuration des alertes Vercel

Vercel ne fournit pas de système d'alertes intégré, mais vous pouvez utiliser des outils tiers :

#### UptimeRobot (gratuit)
1. Créez un compte sur UptimeRobot
2. Ajoutez un nouveau monitor :
   - Type : HTTPS
   - URL : https://ocr-uvt-web.vercel.app
   - Monitoring Interval : 5 minutes
3. Configurez les alertes par email, Slack, etc.

#### Better Uptime (gratuit)
1. Créez un compte sur Better Uptime
2. Ajoutez un nouveau monitor :
   - Nom : OCR-UVT-Web Frontend
   - URL : https://ocr-uvt-web.vercel.app
   - Check interval : 1 minute
3. Configurez les alertes par email, SMS, Slack, etc.

### 4. Intégration avec des outils de monitoring avancés

#### Sentry (pour le tracking des erreurs)

1. Créez un projet Sentry pour votre frontend
2. Ajoutez le SDK Sentry dans votre frontend :

```html
<script src="https://cdn.ravenjs.com/3.27.0/raven.min.js"></script>
<script>
  Raven.config('YOUR_SENTRY_DSN').install();
</script>
```

3. Configurez les alertes dans Sentry pour être notifié des erreurs

#### LogRocket (pour l'analyse de session)

1. Créez un compte LogRocket
2. Ajoutez le SDK LogRocket dans votre frontend :

```html
<script src="https://cdn.logrocket.io/logrocket.min.js"></script>
<script>
  LogRocket.init('YOUR_APP_ID');
</script>
```

3. Configurez les alertes pour être notifié des problèmes de performance

## Tableau de bord de monitoring

Pour un monitoring centralisé, vous pouvez créer un tableau de bord personnalisé en utilisant :

### Grafana (gratuit)

1. Installez Grafana (ou utilisez Grafana Cloud)
2. Configurez des datasources pour :
   - Render (via Prometheus)
   - Vercel (via API)
   - Sentry (pour les erreurs)
3. Créez des dashboards personnalisés pour visualiser vos métriques

### Datadog (payant)

1. Créez un compte Datadog
2. Installez l'agent Datadog sur votre infrastructure
3. Configurez des intégrations pour Render et Vercel
4. Créez des dashboards et des alertes personnalisés

## Bonnes pratiques de monitoring

1. **Surveillez les métriques clés** : temps de réponse, taux d'erreur, utilisation des ressources
2. **Configurez des alertes appropriées** : pas trop sensibles pour éviter les fausses alertes
3. **Analysez les tendances** : identifiez les problèmes avant qu'ils ne deviennent critiques
4. **Documentez les incidents** : créez des runbooks pour les problèmes courants
5. **Effectuez des revues régulières** : examinez les métriques et les alertes périodiquement

## Dépannage

### Alertes fréquentes sans problème réel

Ajustez les seuils d'alerte pour éviter les fausses alertes :
- Augmentez légèrement les seuils d'utilisation CPU/mémoire
- Augmentez le temps de réponse acceptable
- Ajoutez une période de grâce avant de déclencher une alerte

### Pas d'alertes malgré des problèmes

Vérifiez que :
- Les alertes sont activées
- Les seuils sont correctement configurés
- Les notifications sont correctement configurées (email, Slack, etc.)
- Les services de monitoring sont accessibles depuis votre infrastructure

### Difficulté à identifier la cause d'un problème

Utilisez les outils suivants pour diagnostiquer :
- Logs détaillés (backend et frontend)
- Traces distribuées (si configurées)
- Profiling de performance (pour identifier les goulots d'étranglement)
- Analyse des métriques historiques (pour identifier les tendances)

## Ressources supplémentaires

- [Documentation Render - Monitoring](https://render.com/docs/monitoring)
- [Documentation Vercel - Analytics](https://vercel.com/docs/analytics)
- [Documentation Grafana](https://grafana.com/docs/)
- [Documentation Datadog](https://docs.datadoghq.com/)
- [Documentation Sentry](https://docs.sentry.io/)
