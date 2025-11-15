# API Documentation

METALlama.cpp sets up a local API server that's compatible with the OpenAI API format. This document describes how to use the API.

## Server Details

- Default host: 0.0.0.0 (accessible from network)
- Default port: 8080
- Health check endpoint: `/health`
- Base URL: `http://127.0.0.1:8080`

## API Endpoints

### Health Check

```
GET /health
```

Returns "ok" if the server is running properly.

Example:
```bash
curl http://127.0.0.1:8080/health
```

### Chat Completions

```
POST /v1/chat/completions
```

Endpoint for generating text completions based on conversation context.

Parameters:
- `model` (string): Model identifier (e.g., "Llama-3.2-1B-Instruct.Q4_K_M")
- `messages` (array): List of messages in the conversation
  - Each message has `role` (string) and `content` (string)
- `stream` (boolean, optional): Whether to stream the response (default: false)
- `temperature` (float, optional): Controls randomness (default: 0.8)
- `top_p` (float, optional): Controls diversity (default: 0.95)
- `max_tokens` (integer, optional): Maximum tokens to generate (default: 256)

Example request:

```bash
curl -X POST http://127.0.0.1:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Llama-3.2-1B-Instruct.Q4_K_M",
    "messages": [
      {"role": "user", "content": "What is the capital of France?"}
    ],
    "temperature": 0.7
  }'
```

Example response:

```json
{
  "id": "chatcmpl-123",
  "object": "chat.completion",
  "created": 1677858242,
  "model": "Llama-3.2-1B-Instruct.Q4_K_M",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "The capital of France is Paris."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 13,
    "completion_tokens": 7,
    "total_tokens": 20
  }
}
```

### Streaming Response

To receive streaming responses:

```bash
curl -X POST http://127.0.0.1:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Llama-3.2-1B-Instruct.Q4_K_M",
    "messages": [
      {"role": "user", "content": "Write a short poem about AI."}
    ],
    "stream": true
  }'
```

The response will be streamed as server-sent events.

## Using with Client Libraries

### Python (with OpenAI Library)

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://127.0.0.1:8080/v1",
    api_key="dummy"  # API key is required but not checked
)

response = client.chat.completions.create(
    model="Llama-3.2-1B-Instruct.Q4_K_M",
    messages=[
        {"role": "user", "content": "How does a transformer model work?"}
    ]
)

print(response.choices[0].message.content)
```

### JavaScript (with OpenAI SDK)

```javascript
import OpenAI from 'openai';

const openai = new OpenAI({
    apiKey: 'dummy',
    baseURL: 'http://127.0.0.1:8080/v1',
});

async function main() {
    const response = await openai.chat.completions.create({
        model: 'Llama-3.2-1B-Instruct.Q4_K_M',
        messages: [
            { role: 'user', content: 'Explain quantum computing in simple terms.' }
        ],
    });
    
    console.log(response.choices[0].message.content);
}

main();
```

## Limitations

- Not all OpenAI API parameters are supported
- Response format might slightly differ from the official OpenAI API
- Embedding endpoints are not implemented
- Function calling is not supported