from background_task import background

##############################TRANSCRIPTION####################################

import sys
import os

from openai import OpenAI

from .models import UploadedAudio

# Global Variables
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
API_KEY = os.getenv('OPEN_AI_KEY')

# Set up OpenAI connection
client = OpenAI(
    api_key=API_KEY,
)

def transcribe_proofread(recording_id, recording_path):
    ## Transcribe
    if os.path.exists(recording_path):
        audio_file = open(recording_path, "rb")

        transcript = client.audio.transcriptions.create(
            model="whisper-1",
            file=audio_file
        )

        # Remove audio file once transcription is complete
        os.remove(recording_path)

        ## Proof read
        transcription_prompt = """The following text is a transcription of an audio recording. 
                    It may contain errors in interpreted words and punctuation. 
                    Your task is to state the corrected transcription, correcting 
                    the punctuation and aligning the text with what was most likely 
                    intended in the original audio. In your response, state only the
                     correct transcription:""" + transcript.text
        message_history = [
            {
                "role": "user", "content": transcription_prompt
            }
        ]

        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=message_history
        )
        transcript = response.choices[0].message.content.strip()

        ## Produce entry title
        title_creation_prompt = """State a journal entry title name no longer 
                                    than 10 words, given the following text:""" + transcript

        message_history = [
            {
                "role": "user", "content": title_creation_prompt
            }
        ]
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=message_history
        )
        entry_title = response.choices[0].message.content.strip()

        f = open("media/transcripts/" + recording_id, "a")      # Save proofread
        f.write(transcript)                                     # Final response
        f.close()

        return transcript, entry_title



#############################EMOTION ANALYSIS###################################

from transformers import pipeline, AutoTokenizer

EMOTION_GROUP_THRESHOLD = 0.80

EMOTION_IDS = {'happiness': 0, 'sadness': 1, 'anger': 2, 
                'fear': 3, 'disgust': 4, 'surprise': 5}

# Organized as 'individual_emotion': 'its_corresponding_group'
GROUPED_EMOTIONS = {'sadness': 'sadness',
                    'pessimism': 'sadness',
                    'joy': 'happiness',
                    'love': 'happiness',
                    'optimism': 'happiness',
                    'anticipation': 'happiness',
                    'trust': 'happiness',
                    'fear': 'fear',
                    'surprise': 'surprise',
                    'anger': 'anger',
                    'disgust': 'disgust'}

# Load tokenizer
tokenizer = AutoTokenizer.from_pretrained("ayoubkirouane/BERT-Emotions-Classifier")

# Load the pre-trained sentiment analysis model
model = pipeline("text-classification", model="ayoubkirouane/BERT-Emotions-Classifier", top_k=None)


def estimate_tensor_size(tokenizer, text):
    # Tokenize the text
    tokens = tokenizer.tokenize(text)
    
    # Estimate tensor size based on the number of tokens
    tensor_size = len(tokens)  # This is a rough estimate
    
    return tensor_size


def final_selection(emotion_scores):
    final_results_list = []
    final_results_count = 0        # Want to limit to at most 3 returned emotions

    for emotion in emotion_scores:
        if emotion_scores[emotion] == 0 or final_results_count == 3:
            break

        final_results_list.append(EMOTION_IDS[emotion])   # list with emotion id 

        final_results_count += 1

    return final_results_list

def text_block_analysis(text, model, results):
    raw_result = model(text)[0]

    block_result = dict()   # Holds grouped emotional results for text block

    print("\nBlock:", text)

    print("\n*Raw emotional results:", raw_result)

    for emotion_record in raw_result:
        # retain_method
        emotion = GROUPED_EMOTIONS[emotion_record["label"]]

        if emotion in block_result:
            block_result[emotion] += emotion_record["score"]
        else:
            block_result[emotion] = emotion_record["score"]

    print("\n*Grouped emotions (with sum surpassing threshold of {0:f}):".format(EMOTION_GROUP_THRESHOLD))
    for emotion in block_result:
        # Filter and keep emotional scores that satisfy threshold
        if block_result[emotion] >= EMOTION_GROUP_THRESHOLD:
            print("\nEmotion: ", emotion)
            print(" Score: ", block_result[emotion])

            results[emotion] += block_result[emotion]

    return results

def emotion_analysis(text):
    sentences = text.split(".")

    text_block = ""
    results = {'sadness': 0, 'happiness': 0, 'fear': 0, 'surprise': 0,
                'anger': 0, 'disgust': 0}

    for sentence in sentences:
        tensor_size = estimate_tensor_size(tokenizer, text_block + "." + sentence)

        # Limit size of text to run model analysis
        if (tensor_size >= 500):
            results = text_block_analysis(text_block, model, results)

            text_block = sentence
        else:
            text_block += "." + sentence
    results = text_block_analysis(text_block, model, results)   # Analysis for final block

    full_text_emotion_results = dict(sorted(results.items(), key=lambda item: item[1], reverse=True))
    print("\n***Final results sorted:", full_text_emotion_results)

    result = final_selection(full_text_emotion_results)         # Want to keep at most 3
    print("\n*******************Final results:", result)
    return result




###############################BACKGROUND TASK##################################

@background
def audio_transcribe_analyse(recording_id, recording_path):
    transcript, entry_title = transcribe_proofread(recording_id, recording_path)
    emotions = emotion_analysis(transcript)

    print("\n\n\n\n\n\n")
    print("##########################EMOTIONS##############################")
    print(emotions)
    print("\n\n\n\n\n\n")
    print("##########################TRANSCRIPT##############################")
    print(transcript)

    # Update database entry
    entry = UploadedAudio.objects.get(id=recording_id)

    entry.entry_title = entry_title
    entry.emotions = ','.join(map(str, emotions))
    entry.save()