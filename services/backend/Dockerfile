FROM python:3.12-alpine

RUN adduser -D -u 1000 appuser
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 5002

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:5002/health || exit 1

CMD ["python", "app.py"]
