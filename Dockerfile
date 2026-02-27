FROM python:3.13-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY src .

EXPOSE 8000

CMD ["python", "app.py"]