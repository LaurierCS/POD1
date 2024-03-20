
### Purpose of this file was to test the effects of doing sentence-by-sentence
###     analysis vs full text block sentence, and is not actually used when
###     running the server.
### Result: full text block is better.




from transformers import pipeline, AutoTokenizer

RETAIN_THRESHOLD = 0.55                 # Emotion kept per sentence if meets threshold
NORMALIZE_LARGEST_VAL_THRESH = 0.30     # Prominent emotion normalized if avg score meets threshold
NORMALIZED_THRESHOLD = 0.50             # Emotion kept if final normalized value meets threshold

ALL = 1
ALL_THRESHOLD = 2

DEBUG = False

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


def estimate_tensor_size(tokenizer, text):
    # Tokenize the text
    tokens = tokenizer.tokenize(text)
    
    # Estimate tensor size based on the number of tokens
    tensor_size = len(tokens)  # This is a rough estimate
    
    return tensor_size


def normalize(max_val, emotion_scores):
    final_results_dict = dict()
    final_results_list = []
    final_results_count = 0                 # Limit to at most 3 returned emotions
    for emotion in emotion_scores:
        emotion_scores[emotion] /= max_val

        if emotion_scores[emotion] < NORMALIZED_THRESHOLD or final_results_count == 3:
            break

        final_results_dict[emotion] = emotion_scores[emotion]

        #final_results_list.append(emotion)               # list with emotion names
        final_results_list.append(EMOTION_IDS[emotion])   # list with emotion id 

        final_results_count += 1

    if DEBUG:
        return final_results_dict
    else:
        return final_results_list


def per_sentence_analysis(text, model, retain_method):
    """
        How it works:
            1. Take individual sentences and sum up emotion scores according to
               retain_method
            2. Normalize final sum scores
            3. Return up to three emotions that meet a threshold value
    """

    sentences = text.split(".")

    results = dict()
    sentence_count = 0

    for sentence in sentences:
        analysis = model(sentence)[0]
        sentence_count += 1

        for emotion_record in analysis:
            # retain_method
            if (((retain_method == ALL_THRESHOLD) and 
                    (emotion_record["score"] >= RETAIN_THRESHOLD)) or
                (retain_method != ALL_THRESHOLD)):

                emotion = GROUPED_EMOTIONS[emotion_record["label"]]
                if emotion in results:
                    results[emotion] += emotion_record["score"]
                else:
                    results[emotion] = emotion_record["score"]

    # Sort emotions by scores
    results = dict(sorted(results.items(), key=lambda item: item[1], reverse=True))

    # Process emotion score sums
    if results == {}:                       # No emotions detected, rare case
        return dict()

    max_val = list(results.values())[0]     # The highest emotional score sum

    # No emotions detected or top emotion's occurence is insignificant 
    #   (no point in normalizing insignificantly detected emotions)
    if max_val == 0 or (max_val / sentence_count < NORMALIZE_LARGEST_VAL_THRESH):    
        return dict()

    # Return up to 3 emotions that meet a threshold value
    return normalize(max_val, results)

def full_text_analysis(text, model):
    raw_result = model(text)[0]

    results = dict()

    for emotion_record in raw_result:
        # retain_method
        emotion = GROUPED_EMOTIONS[emotion_record["label"]]
        if emotion in results:
            results[emotion] += emotion_record["score"]
        else:
            results[emotion] = emotion_record["score"]

    results = dict(sorted(results.items(), key=lambda item: item[1], reverse=True))
    max_val = list(results.values())[0]     # The highest emotional score sum

    return normalize(max_val, results)



# Load tokenizer
tokenizer = AutoTokenizer.from_pretrained("ayoubkirouane/BERT-Emotions-Classifier")

# Load the pre-trained sentiment analysis model
model = pipeline("text-classification", model="ayoubkirouane/BERT-Emotions-Classifier", top_k=None)

while True:
    input_text = input("*************************************************************************\nInput a text to analyze. (Enter 'quit' to exit): ")

    if input_text == "quit":
        print("Exiting program...")
        break

    tensor_size = estimate_tensor_size(tokenizer, input_text)
    print("Estimated tensor size:", tensor_size)

    # Perform sentiment analysis on the input text
    full_text_result = full_text_analysis(input_text, model)
    sentence_by_sentence_result = per_sentence_analysis(input_text, model, ALL)

    # Print the result
    print("\n~~~~~~~~~~~~~~RESULTS~~~~~~~~~~~~~~~")
    print("Result on whole paragraph:", full_text_result)
    print("--------------------------")
    print("Results based on per sentence analysis", sentence_by_sentence_result)
