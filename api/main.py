from fastapi import FastAPI
app = FastAPI(title="OCR UVT API", version="4.0")

@app.get("/api/health")
def health():
    return {"status": "ok", "version": "4.0", "ocr_engine": "tesseract"}

@app.get("/")
def root():
    return {"message": "OCR Enhanced API UVT"}

