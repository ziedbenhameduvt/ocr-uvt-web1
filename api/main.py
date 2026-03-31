from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import pytesseract
from PIL import Image
import io
import os
import tempfile
from typing import Optional
from pydantic import BaseSettings

class Settings(BaseSettings):
    default_language: str = "eng+fra+ara"
    log_level: str = "INFO"
    temp_uploads_dir: str = "/app/temp_uploads"
    
    class Config:
        env_file = ".env"

settings = Settings()

app = FastAPI(title="OCR UVT API", version="4.0")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Ensure temp directory exists
os.makedirs(settings.temp_uploads_dir, exist_ok=True)

@app.get("/api/health")
def health():
    return {"status": "ok", "version": "4.0", "ocr_engine": "tesseract"}

@app.get("/")
def root():
    return {"message": "OCR Enhanced API UVT"}

@app.post("/api/ocr")
async def perform_ocr(
    file: UploadFile = File(...),
    language: str = settings.default_language
):
    """
    Perform OCR on an uploaded image file.
    Supported languages: eng (English), fra (French), ara (Arabic)
    You can combine languages with + sign, e.g., "eng+fra"
    """
    try:
        # Read the file content
        contents = await file.read()
        
        # Create a temporary file
        with tempfile.NamedTemporaryFile(delete=False, suffix=".png", dir=settings.temp_uploads_dir) as temp_file:
            temp_file.write(contents)
            temp_file_path = temp_file.name
        
        try:
            # Open the image with PIL
            image = Image.open(temp_file_path)
            
            # Perform OCR
            text = pytesseract.image_to_string(image, lang=language)
            
            return {
                "success": True,
                "text": text,
                "language": language,
                "filename": file.filename
            }
        finally:
            # Clean up the temporary file
            if os.path.exists(temp_file_path):
                os.unlink(temp_file_path)
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"OCR processing failed: {str(e)}")

@app.get("/api/languages")
def get_supported_languages():
    """
    Get the list of supported languages for OCR
    """
    return {
        "languages": {
            "eng": "English",
            "fra": "French",
            "ara": "Arabic"
        },
        "combinations": [
            "eng+fra",
            "eng+ara",
            "fra+ara",
            "eng+fra+ara"
        ]
    }

