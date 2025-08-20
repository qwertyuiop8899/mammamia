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
    python - <<PY
import json
fn='config.json'
with open(fn) as f: d=json.load(f)
d.setdefault('General',{})['PORT']=str(${PORT_ENV})
with open(fn,'w') as f: json.dump(d,f,indent=4)
print(f"Updated config.json PORT -> {PORT_ENV}")
PY
  fi
fi

# Start the FastAPI app via uvicorn (module: run:app)
exec uvicorn run:app --host 0.0.0.0 --port "$PORT_ENV" --log-level info
