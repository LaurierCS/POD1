"""
NOTE: need to run following code in api directory
python3 manage.py process_tasks
"""



from background_task import background

import sys
import speech_recognition as sr
import os

from openai import OpenAI

# Global Variables
USING_OPENAI = True # Set to False by default, minimizing OpenAI API calls
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
API_KEY = os.getenv('OPEN_AI_KEY')

# Set up transcriber
r = sr.Recognizer()

# Set up OpenAI connection
client = OpenAI(
    api_key=API_KEY,
)

@background
def transcribe_proofread(recording_id):
    """
    print(recording_id)
    f = open("media/transcripts/" + recording_id, "a")
    f.write("Hi")
    f.close()
    """

    result = "hallo, me name's j :)"

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

        response = response.choices[0].message.content.strip()

        f = open("media/transcripts/" + recording_id, "a")
        f.write(response)
        f.close()