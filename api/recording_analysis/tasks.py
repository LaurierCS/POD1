"""
NOTE: need to run following code in api directory
python3 manage.py process_tasks
"""

from background_task import background

import sys
import os

from openai import OpenAI

# Global Variables
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
API_KEY = os.getenv('OPEN_AI_KEY')

# Set up OpenAI connection
client = OpenAI(
    api_key=API_KEY,
)

@background
def transcribe_proofread(recording_id, recording_path):
    ## Transcribe
    audio_file = open(recording_path, "rb")

    transcript = client.audio.transcriptions.create(
        model="whisper-1",
        file=audio_file
    )

    #print(transcript.text)

    if os.path.exists(recording_path):      # Remove audio file once 
      os.remove(recording_path)             #   transcription is complete


    ## Proof read
    prompt = """The following text is a transcription of an audio recording. 
                It may contain errors in interpreted words and punctuation. 
                Your task is to state the corrected transcription, correcting 
                the punctuation and aligning the text with what was most likely 
                intended in the original audio. In your response, state only the
                 correct transcription:""" + transcript.text

    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {
                "role": "user", "content": prompt
            }
        ]
    )
    response = response.choices[0].message.content.strip()

    f = open("media/transcripts/" + recording_id, "a")      # Save proofread
    f.write(response)                                       #   final response
    f.close()