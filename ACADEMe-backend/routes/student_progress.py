from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.encoders import jsonable_encoder
from services.progress_service import log_progress, get_student_progress_list, update_progress_status
from models.progress_model import ProgressCreate, ProgressUpdate
from utils.auth import get_current_user

router = APIRouter(prefix="/progress", tags=["Student Progress"])

target_languages = ["fr", "es", "de", "zh", "ar", "hi", "en"]

@router.post("/", status_code=status.HTTP_201_CREATED)
async def track_progress(progress_data: ProgressCreate, user: dict = Depends(get_current_user)):
    """Logs student progress in Firestore with translations."""
    progress_dict = jsonable_encoder(progress_data.dict())  # Ensure serialization
    response = await log_progress(user["id"], progress_dict)
    return {"message": "Progress logged successfully", "progress": response}

@router.get("/")
async def fetch_student_progress(target_language: str = "en", user: dict = Depends(get_current_user)):
    """Fetches all progress records in the requested language."""
    target_language = target_language.lower()  # Normalize input

    if target_language not in target_languages:
        raise HTTPException(status_code=400, detail=f"Invalid target language: {target_language}")

    progress = await get_student_progress_list(user["id"], target_language)
    
    if not progress:
        raise HTTPException(status_code=404, detail="No progress records found")

    return {"message": "Progress records fetched successfully", "progress": progress}

@router.put("/{progress_id}")
async def update_progress(progress_id: str, progress_update: ProgressUpdate, user: dict = Depends(get_current_user)):
    """Updates a student's progress record in Firestore and translates updates."""
    update_data = jsonable_encoder(progress_update.dict(exclude_unset=True))  # Ensure proper serialization

    updated_progress = await update_progress_status(user["id"], progress_id, update_data)
    if not updated_progress:
        raise HTTPException(status_code=404, detail="Progress record not found or not updated")

    return {"message": "Progress updated successfully", "progress": updated_progress}
