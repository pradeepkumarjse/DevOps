#!/bin/bash

# Change directory to the project directory
cd /home/ubuntu/call

# Pull the latest changes from the main branch
git pull origin main

# Activate the virtual environment and load environment variables
source $(pipenv --venv)/bin/activate
source .env

# Install dependencies
pipenv install

# Generate and apply database schema updates
pipenv run alembic revision --autogenerate -m "Schema Updates"
pipenv run alembic merge heads
pipenv run alembic upgrade head

# Define the log file path
LOGFILE="/home/ubuntu/logs/uvicorn.log"


# Run uvicorn server with reload option and redirect output to a log file
nohup pipenv run uvicorn app.main:app --reload >> "$LOGFILE"  2>&1 &
