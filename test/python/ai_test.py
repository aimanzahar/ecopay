import requests

BASE_URL = 'http://zahar.my:11434'
MODEL_NAME = 'Gemma3:latest'

def ask_ollama(prompt):
    url = f'{BASE_URL}/api/generate'
    payload = {
        'model': MODEL_NAME,
        'prompt': prompt,
        'stream': False
    }

    try:
        response = requests.post(url, json=payload, timeout=60)
        response.raise_for_status()
        data = response.json()
        return data.get('response', 'No response from model.')
    except requests.exceptions.RequestException as e:
        return f"❌ Error communicating with Ollama: {e}"

if __name__ == "__main__":
    print("🔗 Connected to Ollama at:", BASE_URL)
    while True:
        user_input = input("You: ")
        if user_input.lower() in ['exit', 'quit']:
            break
        reply = ask_ollama(user_input)
        print("Gemma3:", reply)
