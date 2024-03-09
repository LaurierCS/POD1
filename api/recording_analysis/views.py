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

from openai import OpenAI

# Global Variables
USING_OPENAI = False # Set to False by default, minimizing OpenAI API calls
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
API_KEY = os.getenv('OPEN_AI_KEY')

# Set up transcriber
r = sr.Recognizer()

# Set up OpenAI connection
client = OpenAI(
    api_key=API_KEY,
)

def transcribe_local_file(filename):
    AUDIO_FILE = os.path.join(BASE_DIR, 'media', filename)
    with sr.AudioFile(AUDIO_FILE) as source:
        audio = r.record(source)    # Transcribe with free google service
        return r.recognize_google(audio)

def transcribe_audio(request):
    result = ""

    # NOTE: Need to change to uploaded file!!!
    result += transcribe_local_file('i_have_a_dream.wav') # Should end with "I have a dream." (doesn't due to 30 second time cap)

    # Can also specify multiple roles (e.g: system, and build context using user
    #    and assistant): 
    #https://platform.openai.com/docs/guides/text-generation/chat-completions-api

    prompt = """The following text is a transcription of an audio recording. 
                It may contain errors in interpreted words and punctuation. 
                Your task is to state the corrected transcription, correcting 
                the punctuation and aligning the text with what was most likely 
                intended in the original audio. In your response, state only the
                 correct transcription:""" + result

    if (USING_OPENAI):
        # Result:
        '''
            {
                "transcript": "Even though we face the difficulties of today and
                                 tomorrow, I still have a dream. It is a dream 
                                 deeply rooted in the American dream. I have a 
                                 dream that one day this nation will rise up."
            }
        '''

        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {
                    "role": "user", "content": prompt
                }
            ]
        )

        return JsonResponse({"old-transcript": result, "new-transcript": response.choices[0].message.content.strip()})

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

            return Response(
                serializer.data,
                status=status.HTTP_201_CREATED
            )

        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )