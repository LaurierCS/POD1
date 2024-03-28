from rest_framework import serializers
from .models import UploadedAudio

class AudioFileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UploadedAudio
        fields = ('id', 'entry_title', 'emotions', 'recording', 'uploaded_on')