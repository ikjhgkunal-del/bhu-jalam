#!/bin/bash
cd Backend
uvicorn app.api:app --host 0.0.0.0 --port $PORT
