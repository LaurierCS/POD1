from rest_framework import serializers
from .models import UploadedAudio, TestModel

class AudioFileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UploadedAudio
        fields = ('recording', 'uploaded_on')

class TestSerializer(serializers.ModelSerializer):
    class Meta:
        model = TestModel 
        fields = ('sometext',)