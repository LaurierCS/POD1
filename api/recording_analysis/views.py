from rest_framework import status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

import sys
import os

from .serializers import AudioFileSerializer
from .tasks import audio_transcribe_analyse
from .models import UploadedAudio

# Upload Audio (supports m4a, mp4, etc...)
class AudioUploadAPIView(APIView):
    parser_classes = (MultiPartParser, FormParser)
    serializer_class = AudioFileSerializer

    def post(self, request, *args, **kwargs):
        serializer = self.serializer_class(data=request.data)

        if serializer.is_valid():
            saved_recording = serializer.save()

            audio_transcribe_analyse(str(saved_recording.id), saved_recording.recording.path)

            return Response(
                serializer.data,
                status=status.HTTP_201_CREATED
            )

        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )


# Get Transcript
class AudioTranscriptAPIView(APIView):
    parser_classes = (MultiPartParser, FormParser)
    serializer_class = AudioFileSerializer

    def get(self, request, recording_id, *args, **kwargs):
        recording_id = str(recording_id)

        recording_path = "media/transcripts/" + recording_id

        if os.path.exists(recording_path):
            f = open(recording_path, "r")
            transcript = f.readlines()[0]

            # Remove transcript file
            os.remove(recording_path)

            entry_title = str(UploadedAudio.objects.get(id=recording_id).entry_title)
            emotions = str(UploadedAudio.objects.get(id=recording_id).emotions)

            return Response(
                {'transcript': transcript,
                'entry_title': entry_title,
                'emotions': emotions}
            )
        else:
            # Either recording no longer exists or transcript is still being
            #   processed
            return Response(
                {'transcript': ''},
                status=status.HTTP_404_NOT_FOUND
            )