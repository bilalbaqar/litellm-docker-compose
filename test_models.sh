#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "${ROOT_DIR}/.env" ]; then
  echo "Missing .env at ${ROOT_DIR}/.env" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
. "${ROOT_DIR}/.env"
set +a

if [ -z "${VIRTUAL_KEY:-}" ]; then
  echo "VIRTUAL_KEY is not set in .env" >&2
  exit 1
fi

show_usage() {
  cat <<'EOF'
Usage: ./test_models.sh [--openai] [--google]

By default, tests all configured models.
EOF
}

run_openai=false
run_google=false

for arg in "$@"; do
  case "${arg}" in
    --openai) run_openai=true ;;
    --google) run_google=true ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    *)
      echo "Unknown option: ${arg}" >&2
      show_usage >&2
      exit 1
      ;;
  esac
done

if [ "${run_openai}" = false ] && [ "${run_google}" = false ]; then
  run_openai=true
  run_google=true
fi

openai_models=(
  "gpt-5"
  "gpt-5-mini"
  "gpt-5-nano"
  "gpt-5-pro"
  "gpt-5.2"
  "gpt-5.2-pro"
  "gpt-5.1"
  "gpt-5.1-codex"
  "gpt-4.1"
  "gpt-4.1-mini"
  "gpt-4.1-nano"
)

google_models=(
  "gemini-3-pro-preview"
  "gemini-3-flash-preview"
  "gemini-2.5-flash"
  "gemini-2.5-flash-lite"
)

test_model() {
  local model="$1"
  local safe_name
  safe_name="$(echo "${model}" | tr '/:' '__')"

  echo "Testing ${model}..."
  http_code="$(
    curl -sS -o "/tmp/litellm_test_${safe_name}.json" -w "%{http_code}" \
      http://localhost:4000/v1/chat/completions \
      -H "Authorization: Bearer ${VIRTUAL_KEY}" \
      -H "Content-Type: application/json" \
      -d "{
        \"model\": \"${model}\",
        \"messages\": [
          {\"role\": \"user\", \"content\": \"Say hello in one short sentence.\"}
        ]
      }"
  )"

  if [ "${http_code}" != "200" ]; then
    echo "Failed: ${model} (HTTP ${http_code})" >&2
    echo "Response saved to /tmp/litellm_test_${safe_name}.json" >&2
    echo "Response body:" >&2
    sed -n '1,200p' "/tmp/litellm_test_${safe_name}.json" >&2
    exit 1
  fi

  echo "OK: ${model}"
}

if [ "${run_google}" = true ]; then
  for model in "${google_models[@]}"; do
    test_model "${model}"
  done
fi

if [ "${run_openai}" = true ]; then
  for model in "${openai_models[@]}"; do
    test_model "${model}"
  done
fi

echo "All requested models responded successfully."
