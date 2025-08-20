###########################
# Base image
###########################
FROM python:3.10-slim-bullseye AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
	PYTHONUNBUFFERED=1 \
	PIP_NO_CACHE_DIR=1 \
	PATH="/home/appuser/.local/bin:$PATH" \
	PORT=8081

WORKDIR /app

###########################
# System deps
###########################
RUN apt-get update \
	&& apt-get install -y --no-install-recommends curl ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

###########################
# Install Python deps first (better layer caching)
###########################
COPY requirements.txt ./
RUN pip install --upgrade pip \
	&& pip install -r requirements.txt

###########################
# Copy application source (includes start.sh)
###########################
COPY . .

###########################
# Ensure start.sh is executable before dropping privileges
###########################
RUN chmod +x /app/start.sh

###########################
# Non-root user
###########################
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8081

###########################
# Healthcheck (FastAPI /healthz)
###########################
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD curl -fsS http://127.0.0.1:${PORT:-8081}/healthz || exit 1

###########################
# Entrypoint
###########################
CMD ["/app/start.sh"]
