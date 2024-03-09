from rest_framework import status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

import sys
import speech_recognition as sr
import os

from .serializers import AudioFileSerializer
from .tasks import transcribe_proofread

# Upload Audio (supports m4a, mp4, etc...)
class AudioUploadAPIView(APIView):
    parser_classes = (MultiPartParser, FormParser)
    serializer_class = AudioFileSerializer

    def post(self, request, *args, **kwargs):
        # NOTE: might need to assert that only 1 file is passed in

        serializer = self.serializer_class(data=request.data)

        # NOTE: might need to convert to wav first
        if serializer.is_valid():
            saved_recording = serializer.save()

            transcribe_proofread(str(saved_recording.id), saved_recording.recording.path)

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

        f = open("media/transcripts/" + recording_id, "r")
        recording_path = f.name
        transcript = f.readlines()

        if os.path.exists(recording_path):      # Remove transcript file once 
          os.remove(recording_path)

        return Response(
            {'transcript': transcript}
        )