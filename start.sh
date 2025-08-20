#!/usr/bin/env bash
set -euo pipefail

# Allow dynamic port override (BeamUP / Render / Heroku style) default 8080
PORT_ENV="${PORT:-8080}"
# Ensure config port matches runtime if different
if [ -f config.json ]; then
  CURRENT_CFG_PORT=$(python - <<'PY'
import json
with open('config.json') as f:
  data=json.load(f)
print(data.get('General',{}).get('PORT',''))
PY
  )
  if [ "$CURRENT_CFG_PORT" != "$PORT_ENV" ] && [ -n "$CURRENT_CFG_PORT" ]; then
    APP_PORT="$PORT_ENV" python - <<'PY'
import json, os
fn='config.json'
with open(fn) as f: d=json.load(f)
port=os.environ.get('APP_PORT') or '8080'
d.setdefault('General',{})['PORT']=str(port)
with open(fn,'w') as f: json.dump(d,f,indent=4)
print(f"Updated config.json PORT -> {port}")
PY
  fi
fi

# Start the FastAPI app via uvicorn (module: run:app)
ACCESS_LOG=${ACCESS_LOG:-1}
LOG_LEVEL=${LOG_LEVEL:-info}
if [ "$ACCESS_LOG" = "1" ]; then
  ACCESS_FLAG="--access-log"
else
  ACCESS_FLAG="--no-access-log"
fi
exec uvicorn run:app --host 0.0.0.0 --port "$PORT_ENV" --log-level "$LOG_LEVEL" $ACCESS_FLAG --proxy-headers --forwarded-allow-ips="*"
