from datetime import datetime
from typing import Optional, Dict
from pydantic import BaseModel, Field

class ProgressBase(BaseModel):
    course_id: Optional[str] = None
    topic_id: Optional[str] = None
    subtopic_id: Optional[str] = None
    material_id: Optional[str] = None
    quiz_id: Optional[str] = None
    question_id: Optional[str] = None
    score: Optional[float] = None
    status: str  # 'incomplete', 'complete'
    activity_type: str  # 'view', 'quiz_attempt', 'discussion'
    metadata: Dict = Field(default_factory=dict)  # Ensure metadata is always a dict
    timestamp: datetime = Field(default_factory=datetime.utcnow)  # Corrected timestamp handling

class ProgressCreate(ProgressBase):
    pass

class ProgressUpdate(BaseModel):
    status: Optional[str] = None
    score: Optional[float] = None
    metadata: Optional[Dict] = Field(default_factory=dict)

class ProgressVisualResponse(BaseModel):
    visual_data: dict
