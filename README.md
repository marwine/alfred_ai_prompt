# Alfred AI Prompt Workflow

A workflow for Alfred that provides quick access to AI assistants like ChatGPT, Claude, Copilot, etc.

## Usage

Type `ask` followed by:
- `co`: GitHub Copilot
- `gpt`: ChatGPT
- `cl`: Claude
- `px`: Perplexity
- `ms`: Mistral

Example: `ask gpt how do I center a div?`

## Configuration

You can customize the services by setting the `SERVICES_JSON` environment variable in Alfred. Format:
json
[
  {
    "name": "Copilot",
    "code": "co",
    "urlTemplate": "https://github.com/copilot?prompt=${prompt}"
  },
  {
    "name": "ChatGPT",
    "code": "gpt",
    "urlTemplate": "https://chatgpt.com/?prompt=${prompt}"
  },
  {
    "name": "Claude",
    "code": "cl",
    "urlTemplate": "https://claude.ai/new?q=${prompt}"
  },
  {
    "name": "Perplexity",
    "code": "px",
    "urlTemplate": "https://www.perplexity.ai/search/new?q=${prompt}"
  },
  {
    "name": "Mistral",
    "code": "ms",
    "urlTemplate": "https://chat.mistral.ai/chat?q=${prompt}"
  }
]

Each service requires:
- `name`: Display name in Alfred
- `code`: Short code to trigger the service (e.g., `gpt`, `cl`)
- `urlTemplate`: URL with `${prompt}` placeholder for the query

If no configuration is provided, the workflow uses these default services.