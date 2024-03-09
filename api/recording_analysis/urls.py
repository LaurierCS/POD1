from django.urls import path
from recording_analysis import views

from .views import AudioUploadAPIView, AudioTranscriptAPIView

urlpatterns = [
    path('/upload-audio/', AudioUploadAPIView.as_view(), name="upload-audio"),
    path('/get-transcript/<uuid:recording_id>/', AudioTranscriptAPIView.as_view(), name="get-transcript"),
]