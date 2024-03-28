
### Purpose of this file is to test emotional analysis on large blocks of text.
### Program involves limiting the size (in terms of tensors) of text blocks
###     and includes a large text example

from transformers import pipeline, AutoTokenizer

DEBUG = False 

EMOTION_GROUP_THRESHOLD = 0.80

EMOTION_IDS = {'sadness': 0, 'happiness': 1, 'fear': 2, 'surprise': 3,
                'anger': 4, 'disgust': 5}

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
    final_results_dict = dict()
    final_results_list = []
    final_results_count = 0                 # Limit to at most 3 returned emotions

    for emotion in emotion_scores:
        if emotion_scores[emotion] == 0 or final_results_count == 3:
            break

        final_results_dict[emotion] = emotion_scores[emotion]

        #final_results_list.append(emotion)               # list with emotion names
        final_results_list.append(EMOTION_IDS[emotion])   # list with emotion id 

        final_results_count += 1

    if DEBUG:
        return final_results_dict
    else:
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

############# Test emotional analysis ############
# Happiness
text = """Once upon a time in a quaint little town nestled between rolling hills and babbling brooks, there lived a young girl named Lily. With eyes as bright as the morning sun and a smile that could light up the darkest of days, Lily was known throughout the town for her boundless joy and kindness.
Every morning, Lily would skip through the cobblestone streets, greeting neighbors with a cheerful "Good morning!" and stopping to admire the blooming flowers that adorned the windowsills. She radiated positivity wherever she went, spreading happiness like wildflowers in the wind.
One sunny afternoon, as Lily danced through the town square, she stumbled upon a lost puppy whimpering beneath a bench. Without hesitation, Lily scooped up the furry ball of fur and held it close to her heart. With a giggle, she whispered words of comfort, promising to help the little pup find its way home.
Determined to reunite the puppy with its owner, Lily embarked on a heartwarming adventure through the town, knocking on doors and asking everyone she met if they knew who the puppy belonged to. Along the way, she made new friends and shared laughs with strangers, her contagious enthusiasm melting away any worries or troubles they carried.
After hours of searching, just as the sun began to dip below the horizon, Lily stumbled upon a small cottage at the edge of town. There, sitting on the front porch, was a tearful little boy frantically calling out for his lost puppy. With a joyful cry, Lily rushed forward, the puppy wagging its tail in excitement as it bounded into the boy's arms.
Tears of gratitude streamed down the boy's cheeks as he hugged Lily tightly, thanking her for bringing his beloved pet home. And in that moment, surrounded by the warmth of friendship and love, Lily felt a happiness so pure and profound that it seemed to shimmer in the air around her.
From that day forward, Lily became known as the town's guardian angel, always ready to lend a helping hand or a listening ear to those in need. And though her days were filled with countless adventures and acts of kindness, her greatest joy came from the simple moments of connection and compassion that bound her community together.
And so, in the little town nestled between the hills and the brooks, happiness bloomed like wildflowers, nourished by the boundless love and generosity of a young girl named Lily. And as the years passed, her legacy lived on, a beacon of hope and light for generations to come.
"""
# Sadness
text += """Years passed, and the little town that once buzzed with laughter and joy fell into a somber silence. Lily's absence left a void that no one could fill, and the memory of her boundless spirit lingered like a bittersweet melody in the hearts of those who had known her.
The streets that were once alive with the sound of children playing now echoed with the hollow footsteps of weary souls, each burdened with the weight of their own sorrows. The laughter that once filled the air was replaced by the soft whisper of melancholy, a haunting reminder of the happiness that had slipped away.
The lost puppy, now old and gray, lay curled up on the porch of the cottage, its eyes clouded with age as it waited patiently for a friend who would never return. The boy who had once hugged Lily tightly now gazed out at the horizon with a sadness that seemed to stretch beyond the bounds of time, his heart heavy with the ache of longing.
And in the town square, where Lily had once danced with abandon, there stood a statue carved from stone, a solemn tribute to the girl who had brought light into the lives of so many. But even as the townsfolk gathered to pay their respects, their tears mingling with the rain that fell from the gray skies above, they knew that no monument could ever capture the essence of the joy that had once filled their hearts.
For in the end, the saddest part of all was not the loss of Lily herself, but the realization that the world would never again be as bright or as beautiful without her in it. And so, as the sun set on the once-thriving town, it cast a shadow that seemed to stretch on into eternity, a silent reminder of a happiness that had slipped through their fingers like grains of sand.
"""
# Fear
text += """Years had passed since Lily's disappearance, yet the memory of her mysterious vanishing lingered like a ghost haunting the once vibrant town. The cobblestone streets now seemed to whisper tales of dread, and the once-cheerful townsfolk walked with a cautious gait, their eyes darting nervously at every shadow.
In the eerie silence that had settled over the town, strange occurrences became commonplace. Whispers of unseen figures lurking in the shadows and ghostly apparitions haunting the abandoned streets spread like wildfire, sending shivers down the spines of those who dared to remain.
The lost puppy, now a spectral presence, roamed the deserted alleys, its mournful howls echoing through the night like a lament for the happiness that had been lost. The boy who had once held Lily's hand now wandered the town square, his eyes hollow and vacant, as if searching for a glimmer of hope in the darkness that surrounded him.
And in the depths of the forest that bordered the town, a sinister presence stirred. Dark whispers floated on the chill wind, carrying tales of a malevolent force that had taken root in the heart of the woods, its hunger insatiable, its thirst for blood unquenchable.
As the nights grew longer and the shadows deeper, fear gripped the town in its icy embrace. Doors were bolted shut, windows boarded up, and prayers whispered into the night in the hopes of warding off whatever evil lurked in the darkness.
But despite their best efforts, the sinister force that had taken hold of the town could not be contained. Each night, the whispers grew louder, the shadows darker, until it seemed as though the very air itself was alive with malevolence.
And then, one fateful night, the town was plunged into darkness as a thick fog descended, obscuring everything in its path. In the midst of the swirling mist, a figure emerged, its form twisted and contorted, its eyes burning with a malevolent fire.
With a bloodcurdling scream, the figure descended upon the town, unleashing a wave of terror unlike anything the townsfolk had ever known. Houses crumbled, screams pierced the night, and the once-thriving town was reduced to a desolate wasteland, its streets stained with the blood of the innocent.
And as the first light of dawn broke over the horizon, casting long shadows across the devastated landscape, the townsfolk emerged from their hiding places, their faces pale and drawn with horror. For in the aftermath of the nightmarish onslaught, they knew that their once-peaceful town would never be the same again.
And so, as the sun rose higher in the sky, casting its warm rays over the shattered ruins of the town, a sense of dread settled over the land, a grim reminder of the darkness that lurked just beyond the edge of sight. And in the hearts of those who had survived the night, a haunting question lingered: Would the nightmare ever truly end, or had they become prisoners of the darkness forevermore?
"""

print(emotion_analysis(input_text))