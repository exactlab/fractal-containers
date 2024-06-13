#!/bin/bash

fractalctl set-db

gunicorn fractal_server.main:app \
    --workers 2 \
    --timeout 20 \
    --bind 0.0.0.0:8000 \
    --access-logfile logs-fractal-server.access \
    --error-logfile logs-fractal-server.error \
    --worker-class uvicorn.workers.UvicornWorker \
    --logger-class fractal_server.logger.gunicorn_logger.FractalGunicornLogger
