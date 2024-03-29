from rest_framework import serializers
from .models import UploadedAudio

class AudioFileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UploadedAudio
        fields = ('id', 'recording', 'uploaded_on')