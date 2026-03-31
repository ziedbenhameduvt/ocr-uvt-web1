from fastapi import FastAPI, File, UploadFile, HTTPException, Form, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import shutil, os, re, json, sqlite3, tempfile
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional
import pytesseract
from pdf2image import convert_from_path
from PIL import Image
import fitz
from dotenv import load_dotenv
import logging

# Configuration du logging
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Charger les variables d'environnement
# Spécifier le chemin du fichier .env dans le répertoire parent
env_path = Path(__file__).parent.parent / '.env'
load_dotenv(dotenv_path=env_path)

app = FastAPI(title="OCR Enhanced API UVT", version="4.0.0")
limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Gestionnaire d'exceptions global
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Exception non gérée: {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Une erreur interne s'est produite. Veuillez réessayer plus tard."}
    )

# Gestionnaire d'exceptions pour HTTPException
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    logger.warning(f"HTTPException: {exc.status_code} - {exc.detail}")
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail}
    )

# Configuration CORS basée sur les variables d'environnement
frontend_url = os.getenv("FRONTEND_URL", "https://ocr-uvt-web.vercel.app")
local_frontend_urls = os.getenv("LOCAL_FRONTEND_URLS", "http://localhost:3000,http://localhost:8080").split(",")
allowed_origins = [frontend_url] + local_frontend_urls

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization"]
)

DB_PATH = Path("ocr_history_api.db")
UPLOAD_DIR = Path(os.getenv("TEMP_UPLOADS_DIR", "temp_uploads"))
UPLOAD_DIR.mkdir(exist_ok=True)

# Configuration de l'application
MAX_FILE_SIZE = int(os.getenv("MAX_FILE_SIZE", "10485760"))  # 10MB par défaut
OCR_TIMEOUT = int(os.getenv("OCR_TIMEOUT", "60"))  # 60 secondes par défaut

DEFAULT_CONFIG = {
    "languages": ["ara", "fra", "eng"],
    "page_limit": 3,
    "dpi": 300,
    "patterns": [
        {"name": "Type", "field": "type", "regex": r"(أمر بالصرف|Facture|FACTURE|DEVIS|Mandat)", "fallback_regex": r"(facture|devis|mandat)", "priority": 100, "active": True},
        {"name": "Numero", "field": "numero", "regex": r"(?:N[°]|Numero|Ref)\s*[:.]?\s*([A-Z0-9\-/]{3,20})", "fallback_regex": r"(?:#|n°)\s*([A-Z0-9\-/]{3,20})", "priority": 90, "active": True},
        {"name": "Beneficiaire", "field": "beneficiaire", "regex": r"(?:Beneficiaire|Client)\s*[:\-]?\s*([^\n]{3,60})", "fallback_regex": r"(?:SARL|SA|SNC)\s+([A-Z][^\n]{2,40})", "priority": 80, "active": True},
        {"name": "Annee", "field": "annee", "regex": r"\b(20(?:1[5-9]|2[0-9]))\b", "fallback_regex": r"[/\-](20\d{2})\b", "priority": 70, "active": True},
        {"name": "Mois", "field": "mois", "regex": r"\b(0[1-9]|1[0-2])/(?:20)?[2-9][0-9]\b", "fallback_regex": r"(?:janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)", "priority": 60, "active": True},
        {"name": "Montant", "field": "montant", "regex": r"(?:Montant|Total)\s*[:\-]?\s*([\d\s,.]+(?:DT|TND|€|\$)?)", "fallback_regex": r"\b(\d[\d\s,.]+)\s*(?:DT|TND)", "priority": 50, "active": True},
        {"name": "Objet", "field": "objet", "regex": r"(?:Objet|Description)\s*[:\-]?\s*([^\n]{5,80})", "fallback_regex": r"(?:services|fournitures|formation)", "priority": 40, "active": True}
    ],
    "keywords": ["FACTURE", "REF", "DEVIS", "MANDAT", "COMMANDE"]
}
MONTHS_FR = {"janvier": "01", "février": "02", "mars": "03", "avril": "04", "mai": "05", "juin": "06", "juillet": "07", "août": "08", "septembre": "09", "octobre": "10", "novembre": "11", "décembre": "12"}

def init_db():
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.execute("""CREATE TABLE IF NOT EXISTS history (id INTEGER PRIMARY KEY AUTOINCREMENT, source_name TEXT, renamed_name TEXT, extraction_json TEXT, success INTEGER, date_traitement TEXT, ai_used TEXT, processing_time_ms INTEGER)""")
    conn.commit()
    return conn
db_conn = init_db()

def pdf_to_images(pdf_path: str, dpi: int = 300, page_limit: int = 3) -> List[Image.Image]:
    try: return convert_from_path(pdf_path, first_page=1, last_page=page_limit, dpi=dpi)
    except: pass
    try:
        doc = fitz.open(pdf_path); images = []
        for i in range(min(len(doc), page_limit)):
            page = doc.load_page(i); mat = fitz.Matrix(dpi / 72, dpi / 72); pix = page.get_pixmap(matrix=mat)
            images.append(Image.frombytes("RGB", [pix.width, pix.height], pix.samples))
        doc.close(); return images
    except Exception as e: raise RuntimeError(f"Impossible d'extraire les images: {str(e)}")

def perform_ocr(images: List[Image.Image], languages: List[str] = None) -> str:
    if languages is None: languages = DEFAULT_CONFIG["languages"]
    lang_str = "+".join(languages); full_text = ""
    for idx, img in enumerate(images):
        try: page_text = pytesseract.image_to_string(img, lang=lang_str, config="--oem 3 --psm 6"); full_text += f"\n=== Page {idx+1} ===\n{page_text}"
        except Exception as e: full_text += f"\n=== Page {idx+1} ===\n[ERREUR OCR: {str(e)}]"
    return full_text

def extract_data(text: str) -> Dict[str, str]:
    norm = re.sub(r"[ \t\xA0\u200b]+", " ", text); data = {f: "UNKNOWN" for f in ["type", "numero", "beneficiaire", "annee", "mois", "client", "objet", "montant"]}
    patterns = sorted(DEFAULT_CONFIG["patterns"], key=lambda x: x.get("priority", 0), reverse=True)
    for p in patterns:
        if not p.get("active"): continue
        field = p.get("field")
        if not field or data.get(field) != "UNKNOWN": continue
        for key in ["regex", "fallback_regex"]:
            rx = p.get(key, "")
            if not rx: continue
            try:
                m = re.search(rx, norm, re.IGNORECASE | re.UNICODE | re.MULTILINE)
                if m: val = (m.group(1) if m.groups() else m.group(0)).strip()
                if m and len(val) >= 2: data[field] = val; break
            except: pass
    if data["type"] == "UNKNOWN":
        for kw in DEFAULT_CONFIG["keywords"]:
            if kw.upper() in norm.upper(): data["type"] = kw.lower(); break
    if data["annee"] == "UNKNOWN":
        m = re.search(r"\b(20[12]\d)\b", norm)
        if m: data["annee"] = m.group(1)
    if data["mois"] == "UNKNOWN":
        m = re.search(r"\b(0[1-9]|1[0-2])[/\-](?:20)?\d{2}\b", norm)
        if m: data["mois"] = m.group(1)
    if data["client"] == "UNKNOWN" and data["beneficiaire"] != "UNKNOWN": data["client"] = data["beneficiaire"]
    return data

# ✅ CORRECTION ICI : ajout du paramètre "data" avant le type
def generate_filename(template: str, data: Dict[str, str]) -> str:
    try:
        clean = {}
        for k, v in data.items():
            s = re.sub(r'[\\/*?:"<>|\r\t]', "", str(v).strip()); s = re.sub(r"\s+", "_", s)[:50]; clean[k] = s or "UNKNOWN"
        name = template.format(**clean); name = re.sub(r"[^\w\-_.]", "_", name).lower(); name = re.sub(r"_+", "_", name)
        if not name.endswith(".pdf"): name += ".pdf"
        return name
    except: return f"doc_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"

@app.get("/")
async def root(): 
    logger.info("Accès à la racine de l'API")
    return {"message": "OCR Enhanced API UVT v4.0", "status": "operational"}

@app.get("/api/health")
async def health_check():
    """Endpoint de santé de base pour les health checks"""
    return {
        "status": "ok",
        "version": "4.0.0",
        "ocr_engine": "tesseract",
        "languages": DEFAULT_CONFIG["languages"],
        "timestamp": datetime.now().isoformat()
    }

@app.get("/api/health/detailed")
async def detailed_health_check():
    """Endpoint de santé détaillé avec informations système"""
    import psutil

    # Informations sur le système
    cpu_percent = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    disk = psutil.disk_usage('/')

    # Vérification de la base de données
    db_status = "ok"
    try:
        cursor = db_conn.execute("SELECT COUNT(*) FROM history")
        row_count = cursor.fetchone()[0]
    except Exception as e:
        logger.error(f"Erreur lors de la vérification de la base de données: {str(e)}")
        db_status = "error"
        row_count = 0

    # Vérification du répertoire temporaire
    temp_status = "ok"
    try:
        if not os.path.exists(UPLOAD_DIR):
            temp_status = "not_found"
        elif not os.access(UPLOAD_DIR, os.W_OK):
            temp_status = "not_writable"
    except Exception as e:
        logger.error(f"Erreur lors de la vérification du répertoire temporaire: {str(e)}")
        temp_status = "error"

    return {
        "status": "ok",
        "version": "4.0.0",
        "ocr_engine": "tesseract",
        "languages": DEFAULT_CONFIG["languages"],
        "timestamp": datetime.now().isoformat(),
        "system": {
            "cpu_percent": cpu_percent,
            "memory": {
                "total": memory.total,
                "available": memory.available,
                "percent": memory.percent
            },
            "disk": {
                "total": disk.total,
                "free": disk.free,
                "percent": disk.percent
            }
        },
        "services": {
            "database": {
                "status": db_status,
                "records_count": row_count
            },
            "temp_directory": {
                "status": temp_status,
                "path": str(UPLOAD_DIR)
            }
        }
    }

@app.get("/api/metrics")
@limiter.limit("10/minute")
async def get_metrics(request: Request):
    """Endpoint pour récupérer des métriques d'utilisation"""
    cursor = db_conn.execute("""
        SELECT 
            COUNT(*) as total,
            SUM(success) as successful,
            SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) as failed,
            AVG(processing_time_ms) as avg_processing_time,
            MAX(processing_time_ms) as max_processing_time,
            MIN(processing_time_ms) as min_processing_time
        FROM history
    """)
    row = cursor.fetchone()

    # Récupérer les traitements des dernières 24h
    cursor = db_conn.execute("""
        SELECT COUNT(*) 
        FROM history 
        WHERE date_traitement >= datetime('now', '-1 day')
    """)
    last_24h = cursor.fetchone()[0]

    return {
        "total_processed": row[0] or 0,
        "successful": row[1] or 0,
        "failed": row[2] or 0,
        "avg_processing_time_ms": round(row[3], 2) if row[3] else 0,
        "max_processing_time_ms": row[4] or 0,
        "min_processing_time_ms": row[5] or 0,
        "last_24h_processed": last_24h,
        "timestamp": datetime.now().isoformat()
    }

@app.post("/api/ocr/process")
@limiter.limit("20/minute")
async def process_document(request: Request, file: UploadFile = File(...), template: str = Form("{type}_{numero}_{beneficiaire}_{annee}.pdf"), use_ai: bool = Form(False)):
    # Validation des inputs
    if not file.filename:
        logger.warning("Tentative de traitement sans fichier")
        raise HTTPException(400, detail="Aucun fichier fourni")

    if not file.filename.lower().endswith('.pdf'):
        logger.warning(f"Tentative de traitement de fichier non-PDF: {file.filename}")
        raise HTTPException(400, detail="Seuls les fichiers PDF sont acceptés")

    # Validation de la taille du fichier
    file.file.seek(0, 2)  # Seek to end
    file_size = file.file.tell()
    file.file.seek(0)  # Reset position

    if file_size > MAX_FILE_SIZE:
        max_size_mb = MAX_FILE_SIZE / (1024 * 1024)
        logger.warning(f"Fichier trop volumineux: {file.filename} ({file_size} octets)")
        raise HTTPException(413, detail=f"Le fichier dépasse la taille maximale de {max_size_mb}MB")

    start_time = datetime.now()
    temp_path = None

    logger.info(f"Début du traitement du fichier: {file.filename} ({file_size} octets)")

    try:
        suffix = f"_{file.filename}"
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix, dir=UPLOAD_DIR) as tmp:
            shutil.copyfileobj(file.file, tmp)
            temp_path = tmp.name

        logger.debug(f"Fichier temporaire créé: {temp_path}")

        images = pdf_to_images(temp_path, dpi=DEFAULT_CONFIG["dpi"], page_limit=DEFAULT_CONFIG["page_limit"])
        logger.info(f"Extraction de {len(images)} pages du PDF")

        raw_text = perform_ocr(images)
        logger.debug(f"OCR terminé, {len(raw_text)} caractères extraits")

        extracted_data = extract_data(raw_text)
        logger.info(f"Données extraites: {json.dumps(extracted_data, ensure_ascii=False)}")

        new_filename = generate_filename(template, extracted_data)
        processing_time = int((datetime.now() - start_time).total_seconds() * 1000)

        db_conn.execute(
            "INSERT INTO history (source_name, renamed_name, extraction_json, success, date_traitement, ai_used, processing_time_ms) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (file.filename, new_filename, json.dumps(extracted_data, ensure_ascii=False), 1, datetime.now().isoformat(), "none" if not use_ai else "pending", processing_time)
        )
        db_conn.commit()

        logger.info(f"Traitement terminé avec succès en {processing_time}ms")

        return JSONResponse(content={
            "success": True,
            "original_name": file.filename,
            "proposed_name": new_filename,
            "extracted_data": extracted_data,
            "raw_text_preview": raw_text[:1000] + "..." if len(raw_text) > 1000 else raw_text,
            "processing_time_ms": processing_time,
            "pages_processed": len(images),
            "template_used": template
        })
    except HTTPException:
        # Re-raise HTTPException as is
        raise
    except Exception as e:
        logger.error(f"Erreur lors du traitement du fichier {file.filename}: {str(e)}", exc_info=True)
        db_conn.execute(
            "INSERT INTO history (source_name, renamed_name, extraction_json, success, date_traitement, ai_used, processing_time_ms) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (file.filename, None, json.dumps({"error": str(e)}), 0, datetime.now().isoformat(), "none", 0)
        )
        db_conn.commit()
        raise HTTPException(500, detail=f"Erreur de traitement: {str(e)}")
    finally:
        if temp_path and os.path.exists(temp_path):
            try:
                os.unlink(temp_path)
                logger.debug(f"Fichier temporaire supprimé: {temp_path}")
            except:
                logger.warning(f"Impossible de supprimer le fichier temporaire: {temp_path}")

@app.get("/api/history")
@limiter.limit("30/minute")
async def get_history(request: Request, limit: int = 100, offset: int = 0):
    cursor = db_conn.execute("SELECT * FROM history ORDER BY id DESC LIMIT ? OFFSET ?", (limit, offset)); rows = cursor.fetchall(); results = []
    for row in rows: results.append({"id": row[0], "source_name": row[1], "renamed_name": row[2], "extraction": json.loads(row[3]) if row[3] else None, "success": bool(row[4]), "date": row[5], "ai_used": row[6], "processing_time_ms": row[7]})
    return {"total": len(results), "results": results}

@app.get("/api/stats")
async def get_stats(request: Request):
    cursor = db_conn.execute("SELECT COUNT(*), SUM(success), AVG(processing_time_ms) FROM history"); row = cursor.fetchone()
    return {"total_processed": row[0] or 0, "successful": row[1] or 0, "failed": (row[0] or 0) - (row[1] or 0), "avg_processing_time_ms": round(row[2], 2) if row[2] else 0}

@app.delete("/api/history/clear")
@limiter.limit("5/minute")
async def clear_history(request: Request): db_conn.execute("DELETE FROM history"); db_conn.commit(); return {"message": "Historique effacé"}

# Force reload - 2024-03-31

if __name__ == "__main__": import uvicorn; uvicorn.run(app, host="0.0.0.0", port=8000)
