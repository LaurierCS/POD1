from django.urls import path
from recording_analysis import views

from .views import AudioUploadAPIView

urlpatterns = [
    path('', views.transcribe_audio, name="transcribe-audio"),
    path('/upload-audio/', AudioUploadAPIView.as_view(), name="upload-audio"),
]