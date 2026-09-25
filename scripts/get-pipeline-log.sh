#!/usr/bin/env bash
set -euo pipefail

mkdir -p .pipeline

RUN_ID="$(az pipelines runs list --top 1 --query "[0].id" -o tsv)"
if [ -z "$RUN_ID" ]; then
  echo "No Azure pipeline runs found. Ensure the pipeline is created in Azure DevOps and az devops configure has been run." >&2
  exit 1
fi

az pipelines runs show \
  --id "$RUN_ID" \
  --query '{id:id, name:name, sourceBranch:sourceBranch, state:state, result:result, queueTime:queueTime, finishTime:finishTime, logs:logs}' \
  -o json > .pipeline/latest-run.json

python3 - <<'PY'
import json
from pathlib import Path

json_path = Path('.pipeline/latest-run.json')
text_path = Path('.pipeline/latest-run.log')
obj = json.loads(json_path.read_text(encoding='utf-8'))

lines = [
    f"Run ID: {obj.get('id')}",
    f"Name: {obj.get('name') or 'unknown'}",
    f"Branch: {obj.get('sourceBranch') or 'unknown'}",
    f"State: {obj.get('state') or 'unknown'}",
    f"Result: {obj.get('result') or 'unknown'}",
    f"Queued: {obj.get('queueTime') or 'unknown'}",
    f"Finished: {obj.get('finishTime') or 'unknown'}",
    f"Logs URL: {obj.get('logs', {}).get('url') or 'unknown'}",
    "",
    "This file is a generated Azure DevOps run summary for Copilot review.",
    "It intentionally avoids committing raw pipeline logs.",
]

text_path.write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(f"Saved {json_path} and {text_path}")
PY
