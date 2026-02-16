from fastapi import FastAPI, UploadFile, File, Form, BackgroundTasks
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import shutil
import os
import base64
from .core.vision import VisionProcessor
from .database import init_db

app = FastAPI(title="Smart Blind Assistant API",
              description="Backend API for Vision and Voice processing", version="1.0.0")

# Allow all limits for demo purposes
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize
vision_processor = VisionProcessor()

@app.on_event("startup")
async def startup_event():
    init_db()

@app.get("/")
def read_root():
    return {
        "status": "online", 
        "message": "Smart Blind Assistant Backend is Ready",
        "docs": "/docs"
    }

@app.post("/api/v1/vision/detect")
async def detect_objects(file: UploadFile = File(...)):
    """
    Endpoint to process an image frame for objects and faces.
    Used when on-device model is unsure or for detailed analysis.
    """
    try:
        contents = await file.read()
        # Convert bytes to base64 string for the existing processor logic
        # Or ideally, refactor processor to take bytes. 
        # For now, let's keep it simple:
        b64_image = base64.b64encode(contents).decode('utf-8')
        
        results = vision_processor.detect_objects_and_faces(b64_image)
        return JSONResponse(content=results)
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)

@app.post("/api/v1/voice/command")
async def process_voice_command(command: str = Form(...)):
    """
    Process text command (from STT on device) or audio file.
    For now, receiving text command.
    """
    # Simple rule-based intent
    command = command.lower()
    response_text = ""
    
    if "where is" in command:
        obj = command.replace("where is", "").strip()
        response_text = f"Searching for {obj}. Please pan your camera slowly."
    elif "navigate" in command or "take me" in command:
        response_text = "Getting directions. Please wait."
    elif "remember" in command:
        response_text = "I will remember this person. What is their name?"
    else:
        response_text = "I heard you, but I'm not sure how to help with that yet."
        
    return {"response_text": response_text, "action": "speak"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
