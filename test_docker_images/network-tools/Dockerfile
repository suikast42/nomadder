# Use the lightweight Alpine Linux as the base image
FROM python:3.9-alpine

# Install networking tools
RUN apk add --no-cache curl bind-tools netcat-openbsd dos2unix

# Set the working directory
WORKDIR /app

# Copy the requirements file
COPY requirements.txt requirements.txt

# Install Python dependencies
RUN pip install -r requirements.txt

# Copy the rest of the application
COPY app.py app.py
RUN dos2unix app.py

COPY app2.py app2.py
RUN dos2unix app2.py
COPY start.sh start.sh

# Expose port 5000
EXPOSE 5000
EXPOSE 5001
# Set the entrypoint to start the Flask app
#CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0"]
ENTRYPOINT  ["sh", "/app/start.sh"]