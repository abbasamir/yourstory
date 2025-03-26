import torch
from transformers import GPT2Tokenizer, GPT2LMHeadModel
import random
import re

# Set Hugging Face cache directory
CACHE_DIR = "/tmp/huggingface"

# ------------------------
# Load Story Generation Model
# ------------------------
STORY_MODEL_NAME = "abdalraheemdmd/story-api"
story_tokenizer = GPT2Tokenizer.from_pretrained(STORY_MODEL_NAME, cache_dir=CACHE_DIR)
story_model = GPT2LMHeadModel.from_pretrained(STORY_MODEL_NAME, cache_dir=CACHE_DIR)

# ------------------------
# Load Question Generation Model
# ------------------------
QUESTION_MODEL_NAME = "abdalraheemdmd/question-gene"
question_tokenizer = GPT2Tokenizer.from_pretrained(QUESTION_MODEL_NAME, cache_dir=CACHE_DIR)
question_model = GPT2LMHeadModel.from_pretrained(QUESTION_MODEL_NAME, cache_dir=CACHE_DIR)

# Ensure tokenizers have a pad token
if story_tokenizer.pad_token_id is None:
    story_tokenizer.pad_token_id = story_tokenizer.eos_token_id
if question_tokenizer.pad_token_id is None:
    question_tokenizer.pad_token_id = question_tokenizer.eos_token_id

def generate_story(theme, reading_level, max_new_tokens=400, temperature=0.7):
    """Generates a story based on the provided theme and reading level."""
    prompt = f"A {reading_level} story about {theme}:"
    input_ids = story_tokenizer(prompt, return_tensors="pt").input_ids
    with torch.no_grad():
        output = story_model.generate(
            input_ids,
            max_new_tokens=max_new_tokens,
            temperature=temperature,
            top_k=20,
            top_p=0.7,
            do_sample=True,
            early_stopping=True,
            pad_token_id=story_tokenizer.pad_token_id,
            eos_token_id=story_tokenizer.eos_token_id,
            attention_mask=input_ids.ne(story_tokenizer.pad_token_id)
        )
    return story_tokenizer.decode(output[0], skip_special_tokens=True)

def extract_protagonist(story):
    """
    Attempts to extract the protagonist from the first sentence by searching for the pattern "named <Name>".
    Returns the first matched name, if available.
    """
    sentences = re.split(r'\.|\n', story)
    if sentences:
        m = re.search(r"named\s+([A-Z][a-z]+)", sentences[0])
        if m:
            return m.group(1)
    return None

def extract_characters(story):
    """
    Extracts potential character names from the story using a frequency count on capitalized words.
    Filters out common stopwords so that the most frequently mentioned name is likely the main character.
    """
    words = re.findall(r'\b[A-Z][a-zA-Z]+\b', story)
    stopwords = {"The", "A", "An", "And", "But", "Suddenly", "Quickly", "However", "Well",
                 "They", "I", "He", "She", "It", "When", "Where", "Dr", "Mr"}
    filtered = [w for w in words if w not in stopwords and len(w) > 2]
    if not filtered:
        return []
    freq = {}
    for word in filtered:
        freq[word] = freq.get(word, 0) + 1
    sorted_chars = sorted(freq.items(), key=lambda x: x[1], reverse=True)
    return [item[0] for item in sorted_chars]

def extract_themes(story):
    """Extracts themes from the story based on keyword matching."""
    themes = []
    story_lower = story.lower()
    if "space" in story_lower:
        themes.append("space")
    if "adventure" in story_lower:
        themes.append("adventure")
    if "friend" in story_lower:
        themes.append("friendship")
    if "learn" in story_lower or "lesson" in story_lower:
        themes.append("learning")
    return themes

def extract_lesson(story):
    """
    Attempts to extract a lesson or moral from the story by finding sentences
    containing keywords like "learn" or "lesson". Returns the last matching sentence.
    """
    sentences = re.split(r'\.|\n', story)
    lesson_sentences = [
        s.strip() for s in sentences
        if ("learn" in s.lower() or "lesson" in s.lower()) and len(s.strip()) > 20
    ]
    if lesson_sentences:
        return lesson_sentences[-1]
    else:
        return "No explicit lesson found."

def format_question(question_prompt, correct_answer, distractors):
    """
    Combines the correct answer with three distractors, shuffles the options,
    and formats the question as a multiple-choice question.
    """
    # Ensure exactly 3 distractors are available
    if len(distractors) < 3:
        default_distractors = ["Option X", "Option Y", "Option Z"]
        while len(distractors) < 3:
            distractors.append(default_distractors[len(distractors) % len(default_distractors)])
    else:
        distractors = random.sample(distractors, 3)
    options = distractors + [correct_answer]
    random.shuffle(options)
    letters = ["A", "B", "C", "D"]
    correct_letter = letters[options.index(correct_answer)]
    options_text = "\n".join(f"{letters[i]}) {option}" for i, option in enumerate(options))
    question_text = f"{question_prompt}\n{options_text}\nCorrect Answer: {correct_letter}"
    return question_text

def dynamic_fallback_questions(story):
    """
    Generates three multiple-choice questions based on dynamic story content.
    Each question uses a randomly chosen template and shuffles its options.
    """
    protagonist = extract_protagonist(story)
    characters = extract_characters(story)
    themes = extract_themes(story)
    lesson = extract_lesson(story)
    
    # --- Question 1: Theme ---
    theme_templates = [
        "What is the main theme of the story?",
        "Which theme best represents the narrative?",
        "What subject is central to the story?"
    ]
    q1_prompt = random.choice(theme_templates)
    correct_theme = " and ".join(themes) if themes else "learning"
    q1_distractors = ["sports and competition", "cooking and baking", "weather and seasons", "technology and innovation"]
    q1 = format_question(q1_prompt, correct_theme, q1_distractors)
    
    # --- Question 2: Primary Character ---
    character_templates = [
        "Who is the primary character in the story?",
        "Which character drives the main action in the narrative?",
        "Who is the central figure in the story?"
    ]
    q2_prompt = random.choice(character_templates)
    if protagonist:
        correct_character = protagonist
    elif characters:
        correct_character = characters[0]
    else:
        correct_character = "The main character"
    q2_distractors = ["a mysterious stranger", "an unknown visitor", "a supporting character", "a sidekick"]
    q2 = format_question(q2_prompt, correct_character, q2_distractors)
    
    # --- Question 3: Lesson/Moral ---
    lesson_templates = [
        "What lesson did the characters learn by the end of the story?",
        "What moral can be inferred from the narrative?",
        "What is the key takeaway from the story?"
    ]
    q3_prompt = random.choice(lesson_templates)
    if lesson and lesson != "No explicit lesson found.":
        correct_lesson = lesson  # full sentence without truncation
    else:
        correct_lesson = "understanding and growth"
    q3_distractors = ["always be silent", "never try new things", "do nothing", "ignore opportunities"]
    q3 = format_question(q3_prompt, correct_lesson, q3_distractors)
    
    return f"{q1}\n\n{q2}\n\n{q3}"

def generate_story_and_questions(theme, reading_level):
    """
    Generates a story using the story generation model and then creates dynamic,
    multiple-choice questions based on that story.
    """
    story = generate_story(theme, reading_level)
    questions = dynamic_fallback_questions(story)
    return {"story": story, "questions": questions}

# Alias for backward compatibility
create_fallback_questions = dynamic_fallback_questions
