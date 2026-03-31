// Variables globales
let selectedFile = null;

// Fonction de retry pour les requêtes API
async function fetchWithRetry(url, options = {}, retries = 3, backoff = 1000) {
    try {
        const response = await fetch(url, options);
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        return await response.json();
    } catch (error) {
        if (retries <= 0) throw error;
        await new Promise(resolve => setTimeout(resolve, backoff));
        return fetchWithRetry(url, options, retries - 1, backoff * 2);
    }
}

// API status check avec retry automatique
async function checkApiStatus(retries = 3, backoff = 1000) {
    try {
        const data = await fetchWithRetry('/api/health', {}, retries, backoff);
        const statusElement = document.getElementById('api-status');
        statusElement.textContent = 'En ligne';
        statusElement.classList.remove('status-error');
        statusElement.classList.add('status-ok');
        return true;
    } catch (error) {
        const statusElement = document.getElementById('api-status');
        statusElement.textContent = 'Hors ligne';
        statusElement.classList.remove('status-ok');
        statusElement.classList.add('status-error');
        console.error('Erreur de connexion à l\'API:', error);
        return false;
    }
}

// Fonction pour traiter l'image
function processImage() {
    if (!selectedFile) return;

    // Vérifier le statut de l'API avant de traiter
    const statusElement = document.getElementById('api-status');
    if (statusElement.textContent === 'Hors ligne') {
        errorMessage.textContent = 'L\'API est actuellement hors ligne. Veuillez réessayer plus tard.';
        errorMessage.style.display = 'block';
        return;
    }

    const formData = new FormData();
    formData.append('file', selectedFile);
    formData.append('template', '{type}_{numero}_{beneficiaire}_{annee}.pdf');
    formData.append('use_ai', 'false');

    // Show spinner, hide error
    spinner.style.display = 'inline-block';
    errorMessage.style.display = 'none';
    processBtn.disabled = true;

    fetchWithRetry('/api/ocr/process', {
        method: 'POST',
        body: formData
    })
    .then(data => {
        spinner.style.display = 'none';
        processBtn.disabled = false;

        if (data.success) {
            // Afficher les données extraites
            let resultHtml = '<h4>Données extraites:</h4><ul>';
            for (const [key, value] of Object.entries(data.extracted_data)) {
                resultHtml += `<li><strong>${key}:</strong> ${value}</li>`;
            }
            resultHtml += '</ul>';

            // Afficher un aperçu du texte brut
            resultHtml += '<h4>Aperçu du texte:</h4>';
            resultHtml += `<div class="result-text">${data.raw_text_preview}</div>`;

            // Afficher les informations de traitement
            resultHtml += '<div class="mt-3 text-muted">';
            resultHtml += `<small>Temps de traitement: ${data.processing_time_ms}ms | `;
            resultHtml += `Pages traitées: ${data.pages_processed}</small>`;
            resultHtml += '</div>';

            resultArea.innerHTML = resultHtml;
            resultArea.style.display = 'block';
        } else {
            errorMessage.textContent = `Erreur: ${data.message || 'Erreur lors du traitement de l\'image.'}`;
            errorMessage.style.display = 'block';
        }
    })
    .catch(error => {
        spinner.style.display = 'none';
        processBtn.disabled = false;
        console.error('Erreur de traitement:', error);

        // Message d'erreur plus détaillé
        let errorDetails = 'Erreur de connexion au serveur';
        if (error.message.includes('HTTP error')) {
            errorDetails = `Erreur du serveur (${error.message})`;
        } else if (error.message.includes('Failed to fetch')) {
            errorDetails = 'Impossible de contacter le serveur. Vérifiez votre connexion.';
        }

        errorMessage.textContent = `${errorDetails}. Veuillez réessayer.`;
        errorMessage.style.display = 'block';

        // Rafraîchir le statut de l'API après une erreur
        checkApiStatus(1, 500);
    });
}

// Fonctions pour le drag & drop
function preventDefaults(e) {
    e.preventDefault();
    e.stopPropagation();
}

function highlight() {
    dropArea.classList.add('border-primary');
}

function unhighlight() {
    dropArea.classList.remove('border-primary');
}

function handleDrop(e) {
    const dt = e.dataTransfer;
    const files = dt.files;
    handleFiles(files);
}

function handleFiles(files) {
    if (files.length > 0) {
        selectedFile = files[0];
        dropArea.innerHTML = `<p>Fichier sélectionné: <strong>${selectedFile.name}</strong></p>
        <p class="text-muted">Taille: ${formatFileSize(selectedFile.size)}</p>`;
        processBtn.disabled = false;
    }
}

function formatFileSize(bytes) {
    if (bytes < 1024) {
        return bytes + ' octets';
    } else if (bytes < 1024 * 1024) {
        return (bytes / 1024).toFixed(2) + ' Ko';
    } else {
        return (bytes / (1024 * 1024)).toFixed(2) + ' Mo';
    }
}

// Initialisation au chargement de la page
document.addEventListener('DOMContentLoaded', function() {
    // Récupérer les éléments du DOM
    window.dropArea = document.getElementById('drop-area');
    window.fileInput = document.getElementById('file-input');
    window.fileLink = document.getElementById('file-link');
    window.processBtn = document.getElementById('process-btn');
    window.spinner = document.getElementById('spinner');
    window.resultArea = document.getElementById('result-area');
    window.resultText = document.getElementById('result-text');
    window.errorMessage = document.getElementById('error-message');
    window.copyBtn = document.getElementById('copy-btn');
    window.clearBtn = document.getElementById('clear-btn');
    window.languageSelect = document.getElementById('language');

    // Prevent default drag behaviors
    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
        dropArea.addEventListener(eventName, preventDefaults, false);
    });

    // Highlight drop area when item is dragged over it
    ['dragenter', 'dragover'].forEach(eventName => {
        dropArea.addEventListener(eventName, highlight, false);
    });

    ['dragleave', 'drop'].forEach(eventName => {
        dropArea.addEventListener(eventName, unhighlight, false);
    });

    // Handle dropped files
    dropArea.addEventListener('drop', handleDrop, false);

    // Handle file input change
    fileInput.addEventListener('change', function() {
        handleFiles(this.files);
    });

    // Handle file link click
    fileLink.addEventListener('click', function(e) {
        e.preventDefault();
        fileInput.click();
    });

    // Process button click
    processBtn.addEventListener('click', processImage);

    // Copy button click
    copyBtn.addEventListener('click', function() {
        navigator.clipboard.writeText(resultText.textContent)
            .then(() => {
                const originalText = copyBtn.textContent;
                copyBtn.textContent = 'Copié!';
                setTimeout(() => {
                    copyBtn.textContent = originalText;
                }, 2000);
            })
            .catch(err => {
                console.error('Erreur lors de la copie: ', err);
            });
    });

    // Clear button click
    clearBtn.addEventListener('click', function() {
        resultText.textContent = '';
        resultArea.style.display = 'none';
        dropArea.innerHTML = `<input type="file" id="file-input" accept="image/*" style="display: none;">
        <p>Glissez-déposez une image ici ou <a href="#" id="file-link">cliquez pour sélectionner</a></p>
        <p class="text-muted">Formats supportés: JPG, PNG, BMP, TIFF</p>`;

        // Re-attach event listeners
        document.getElementById('file-input').addEventListener('change', function() {
            handleFiles(this.files);
        });
        document.getElementById('file-link').addEventListener('click', function(e) {
            e.preventDefault();
            document.getElementById('file-input').click();
        });

        selectedFile = null;
        processBtn.disabled = true;
    });

    // Vérifier le statut de l'API au chargement
    checkApiStatus();

    // Rafraîchir le statut de l'API toutes les 30 secondes
    setInterval(() => checkApiStatus(1, 500), 30000);
});
