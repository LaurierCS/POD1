import uuid
from django.db import models

# Create your models here.
class UploadedAudio(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    recording = models.FileField(upload_to="recordings")
    uploaded_on = models.DateTimeField(auto_now_add=True)   # NOTE: might not need