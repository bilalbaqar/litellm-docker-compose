# LiteLLM + Postgres (Docker Compose)

This repo runs LiteLLM Proxy with Postgres using Docker Compose and includes basic test scripts.

## What is here
- `docker-compose.yml`: LiteLLM + Postgres services
- `litellm_config.yaml`: LiteLLM configuration and model list
- `.env.example`: Environment variable template (copy to `.env`)
- `test_models.sh`: Model smoke tests with flags

## Quick start
1) Create your env file:
   ```bash
   cp .env.example .env
   ```
2) Fill in required values in `.env`:
   - `POSTGRES_PASSWORD`
   - `GEMINI_API_KEY`
   - `OPENAI_API_KEY`
   - `LITELLM_MASTER_KEY`
   - `VIRTUAL_KEY` (from LiteLLM admin UI)
3) Start the stack:
   ```bash
   docker compose up -d
   ```
4) Apply config or env changes:
   ```bash
   docker compose up -d --force-recreate litellm
   ```

## Test the proxy
All models:
```bash
chmod +x test_models.sh
./test_models.sh
```

OpenAI only:
```bash
./test_models.sh --openai
```

Google only:
```bash
./test_models.sh --google
```

On failure, response bodies are saved to `/tmp/litellm_test_<model>.json`.

## Notes
- `.env` is gitignored. Use `.env.example` as the template.
- The model list is managed in `litellm_config.yaml`.
- If the admin UI or virtual keys fail, ensure `DATABASE_URL` matches the Postgres credentials and the container was recreated after `.env` changes.
