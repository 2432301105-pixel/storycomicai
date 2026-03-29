SHELL := /bin/bash
PYTHON ?= python3
VENV ?= .venv
PIP := $(VENV)/bin/pip
PYTEST := $(VENV)/bin/pytest
RUFF := $(VENV)/bin/ruff
MYPY := $(VENV)/bin/mypy

.PHONY: setup api-dev worker-dev migrate makemigrations lint format test ios-ci clean-ios-artifacts

setup:
	$(PYTHON) -m venv $(VENV)
	$(PIP) install --upgrade pip
	$(PIP) install -r api/requirements.txt -r workers/requirements.txt -r requirements-dev.txt

api-dev:
	PYTHONPATH=. $(VENV)/bin/uvicorn api.app.main:app --reload --host 0.0.0.0 --port 8000

worker-dev:
	PYTHONPATH=. $(VENV)/bin/celery -A workers.app.celery_app:celery_app worker -Q hero_preview,default --loglevel=INFO

migrate:
	cd api && PYTHONPATH=.. ../$(VENV)/bin/alembic upgrade head

makemigrations:
	@if [ -z "$(m)" ]; then echo "Usage: make makemigrations m=message"; exit 1; fi
	cd api && PYTHONPATH=.. ../$(VENV)/bin/alembic revision --autogenerate -m "$(m)"

lint:
	$(RUFF) check .
	$(MYPY) api workers

format:
	$(RUFF) format .
	$(RUFF) check . --fix

test:
	PYTHONPATH=. $(PYTEST)

ios-ci:
	./ios-app/scripts/ci_ios_checks.sh

clean-ios-artifacts:
	rm -rf .deriveddata-ios .deriveddata-ios-ci .deriveddata-ios-test
