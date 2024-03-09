from django.http import HttpResponse, JsonResponse
from rest_framework import status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView
from django.core.files.storage import default_storage    
from django.core.files.base import ContentFile

from .serializers import AudioFileSerializer
from .models import UploadedAudio

import sys
import speech_recognition as sr
import os

from .tasks import transcribe_proofread

def transcribe_local_file(filename):
    AUDIO_FILE = os.path.join(BASE_DIR, 'media', filename)
    with sr.AudioFile(AUDIO_FILE) as source:
        audio = r.record(source)    # Transcribe with free google service
        return r.recognize_google(audio)

def transcribe_audio(request):
    result = ""

    # NOTE: Need to change to uploaded file!!!
    result += transcribe_local_file('i_have_a_dream.wav') # Should end with "I have a dream." (doesn't due to 30 second time cap)

    #    return JsonResponse({"old-transcript": result, "new-transcript": response.choices[0].message.content.strip()})

    return JsonResponse({"result": "success"})




class AudioUploadAPIView(APIView):
    parser_classes = (MultiPartParser, FormParser)
    serializer_class = AudioFileSerializer

    def post(self, request, *args, **kwargs):
        # NOTE: might need to assert that only 1 file is passed in

        serializer = self.serializer_class(data=request.data)

        # Audio file given
        # NOTE: might need to convert to wav first
        if serializer.is_valid():
            saved_recording = serializer.save()

            transcribe_proofread(str(saved_recording.id))

            return Response(
                serializer.data,
                status=status.HTTP_201_CREATED
            )

        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )


class AudioTranscriptAPIView(APIView):
    parser_classes = (MultiPartParser, FormParser)
    serializer_class = AudioFileSerializer

    def get(self, request, format=None):
        print("Called:):):)")
        # NOTE: might need to assert that only 1 file is passed in

        transcript = UploadedAudio.objects.get(id="a5f6aa7d-a76d-4491-b48d-4085628dbdf8")
        print(transcript.recording)


        return Response(
            status=status.HTTP_201_CREATED
        )

        """
        if serializer.is_valid():
            saved_recording = serializer.save()

            return Response(
                serializer.data,
                status=status.HTTP_201_CREATED
            )

        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )
        """

