from django.db import models

# Create your models here.
class UploadedAudio(models.Model):
    recording = models.FileField()
    uploaded_on = models.DateTimeField(auto_now_add=True)   # NOTE: might not need

    def __str__(self):
        return self.uploaded_on.date()