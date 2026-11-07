FROM python:3.14-slim

# Python environment configuration
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies and create a non-root user
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc \
        python3-dev \
        libssl-dev && \
    rm -rf /var/lib/apt/lists/* && \
    python -m pip install --no-cache-dir --upgrade \
        pip \
        "setuptools>=78.1.1" \
        wheel && \
    groupadd -r appgroup && \
    useradd -r -g appgroup appuser

# Install Python dependencies
COPY requirements.txt .

RUN python -m pip install --no-cache-dir \
    -r requirements.txt

# Copy application source
COPY . .

# Set application directory permissions
RUN chown -R appuser:appgroup /app

# Run as non-root user
USER appuser

EXPOSE 8000

# Health check using Python (no curl dependency)
HEALTHCHECK --interval=30s --timeout=5s \
    --start-period=15s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=3)" || exit 1

# Start FastAPI
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]