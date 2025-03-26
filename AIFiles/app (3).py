import os
import time
import torch
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import story_generator
from diffusers import DiffusionPipeline
from PIL import Image
import io
import base64

app = FastAPI()

# Set Hugging Face cache directories
os.environ["HF_HOME"] = "/tmp/huggingface"
os.environ["TRANSFORMERS_CACHE"] = "/tmp/huggingface"  # Deprecated but still used for now
os.environ["HF_HUB_CACHE"] = "/tmp/huggingface"

# Enable GPU if available
device = "cuda" if torch.cuda.is_available() else "cpu"

# Load image generation model
IMAGE_MODEL = "lykon/dreamshaper-8"
pipeline = DiffusionPipeline.from_pretrained(
    IMAGE_MODEL,
    torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32
).to(device)

# Define request schema
class StoryRequest(BaseModel):
    theme: str
    reading_level: str

def generate_images(prompts, max_retries=3, delay=2):
    """
    Attempts to generate images in batch. If an error related to 
    "index 16 is out of bounds" occurs, it retries for up to max_retries.
    If all attempts fail, it falls back to generating images sequentially.
    """
    for attempt in range(max_retries):
        try:
            print(f"Batched image generation attempt {attempt+1}...")
            results = pipeline(
                prompt=prompts,
                num_inference_steps=15,
                height=768,
                width=768
            ).images
            return results
        except Exception as e:
            if "index 16 is out of bounds" in str(e):
                print(f"Attempt {attempt+1} failed with error: {e}")
                time.sleep(delay)
            else:
                raise e
    # Fallback to sequential generation
    print("Falling back to sequential image generation...")
    images = []
    for i, prompt in enumerate(prompts):
        try:
            print(f"Sequential generation for prompt {i+1}...")
            image = pipeline(
                prompt=prompt,
                num_inference_steps=15,
                height=768,
                width=768
            ).images[0]
            images.append(image)
        except Exception as e:
            print(f"Error in sequential generation for prompt {i+1}: {e}")
            raise e
    return images

@app.post("/generate_story_questions_images")
def generate_story_questions_images(request: StoryRequest):
    """
    Generates a story, dynamic questions, and cartoonish storybook images.
    """
    try:
        print(f"🎭 Generating story for theme: {request.theme} and level: {request.reading_level}")
        # Generate story and questions using the story_generator module
        story_result = story_generator.generate_story_and_questions(request.theme, request.reading_level)
        story_text = story_result.get("story", "").strip()
        questions = story_result.get("questions", "").strip()
        if not story_text:
            raise HTTPException(status_code=500, detail="Story generation failed.")
        
        # Split the story into up to 6 paragraphs
        paragraphs = [p.strip() for p in story_text.split("\n") if p.strip()][:6]
        
        # Build a list of prompts for batched image generation
        prompts = [
            (
                f"Children's storybook illustration of: {p}. "
                "Soft pastel colors, hand-drawn style, friendly characters, warm lighting, "
                "fantasy setting, watercolor texture, storybook illustration, beautiful composition."
            )
            for p in paragraphs
        ]
        print(f"Generating images for {len(prompts)} paragraphs concurrently...")
        
        # Use the retry mechanism for image generation
        results = generate_images(prompts, max_retries=3, delay=2)
        
        # Convert each generated image to Base64
        images = []
        for image in results:
            img_byte_arr = io.BytesIO()
            image.save(img_byte_arr, format="PNG")
            img_byte_arr.seek(0)
            base64_image = base64.b64encode(img_byte_arr.getvalue()).decode("utf-8")
            images.append(base64_image)
        
        return JSONResponse(content={
            "theme": request.theme,
            "reading_level": request.reading_level,
            "story": story_text,
            "questions": questions,
            "images": images
        })
    except Exception as e:
        print(f"❌ Error generating story/questions/images: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
def home():
    return {"message": "🎉 Welcome to the Story, Question & Image API!"}
