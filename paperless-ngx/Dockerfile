FROM ghcr.io/paperless-ngx/paperless-ngx:2.20.10

RUN apt-get update && apt-get install -y --no-install-recommends \
    tesseract-ocr-tur \
    tesseract-ocr-deu \
    tesseract-ocr-fra \
    && rm -rf /var/lib/apt/lists/*
