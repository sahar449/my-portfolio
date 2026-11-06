# slim (glibc), not alpine: the OpenTelemetry Python auto-instrumentation injected by the
# CloudWatch/OTel operator is built for glibc and breaks on musl.
FROM python:3.12-slim

RUN useradd -m -u 1000 appuser
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 5002

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5002/health', timeout=4)" || exit 1

CMD ["python", "app.py"]
