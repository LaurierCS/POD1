import uuid
from django.db import models

# Create your models here.
class UploadedAudio(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    entry_title = models.CharField(max_length=250, default="")
    emotions = models.CharField(max_length=250, default="")
    recording = models.FileField(upload_to="recordings")
    uploaded_on = models.DateTimeField(auto_now_add=True)   # NOTE: might not need

    def __str__(self):
        return self.entry_title