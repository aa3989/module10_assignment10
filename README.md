# Assignment 10 — Secure FastAPI Calculator API

A FastAPI calculator application extended with SQLAlchemy user accounts, Pydantic validation, bcrypt password hashing, JWT authentication, PostgreSQL integration testing, and automated testing and Docker image deployment workflows.


## Features

- Calculator API endpoints: `POST /add`, `/subtract`, `/multiply`, and `/divide`.
- SQLAlchemy `User` model with unique `username` and `email`, `password_hash`, and `created_at`.
- Pydantic `UserCreate` for input validation and `UserRead` for responses that omit password hashes.
- Password hashing and verification using Passlib/bcrypt; JWT token authentication.
- PostgreSQL-backed integration tests, unit tests, and Playwright end-to-end tests.
- `GET /health` endpoint for Docker health monitoring.
- GitHub Actions workflows for CI (`test.yml`) and build, Trivy scan, and Docker Hub publishing (`deploy.yml`).

## Technology

Python 3.14, FastAPI, Uvicorn, SQLAlchemy, Pydantic v2, PostgreSQL 16, psycopg2, Passlib/bcrypt, pytest, pytest-cov, Playwright, Docker Compose, GitHub Actions, and Trivy.

## Project structure

```text
assignment10/
├── .github/workflows/
│   ├── test.yml
│   └── deploy.yml
├── app/
│   ├── auth/
│   ├── models/user.py
│   ├── schemas/base.py
│   ├── schemas/user.py
│   ├── config.py
│   ├── database.py
│   └── database_init.py
├── templates/index.html
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── e2e/
│   └── conftest.py
├── .dockerignore
├── Dockerfile
├── docker-compose.yml
├── main.py
├── pytest.ini
└── requirements.txt
```

## Local setup (Ubuntu / WSL)

1. Install Python 3.14, Docker with Compose support, and Git.
2. Open a terminal in the project root and create a virtual environment:

   ```bash
   python3.14 -m venv .venv
   source .venv/bin/activate
   python -m pip install --upgrade pip
   python -m pip install -r requirements.txt
   python -m pip check
   ```

3. Create a local `.env` file. Do **not** commit this file. Generate your own signing key:

   ```bash
   python -c "import secrets; print(secrets.token_urlsafe(48))"
   ```

   Example `.env` contents (replace the placeholder):

   ```dotenv
   DATABASE_URL=postgresql://postgres:postgres@localhost:5432/fastapi_db
   SECRET_KEY=REPLACE_WITH_YOUR_GENERATED_SECRET
   ALGORITHM=HS256
   ACCESS_TOKEN_EXPIRE_MINUTES=30
   ```

   `.env` is for local development only. Production secrets belong in your deployment environment.

## Run with Docker Compose

Start the FastAPI application, PostgreSQL, and pgAdmin:

```bash
docker compose up -d --build
docker compose ps
```

Once ready, visit:

- FastAPI application: <http://localhost:8000/>
- API documentation: <http://localhost:8000/docs>
- Health check: <http://localhost:8000/health>
- pgAdmin: <http://localhost:5050/>

Verify health:

```bash
curl -i http://localhost:8000/health
# HTTP/1.1 200 OK
# {"status":"healthy"}
```

Stop services without deleting database volumes:

```bash
docker compose down
```

**Note:** The Compose setup uses local-development credentials and ports. Do not use these example credentials in production.

## Run tests locally

Integration tests use a **separate PostgreSQL database** named `fastapi_test_db`. The test setup can drop and recreate tables: **never point tests at the development or production database**.

1. Start PostgreSQL:

   ```bash
   docker compose up -d db
   ```

2. Create the test database once (skip if it already exists):

   ```bash
   docker compose exec db psql -U postgres -c "CREATE DATABASE fastapi_test_db;"
   ```

3. Set the test URL for pytest in your WSL terminal:

   ```bash
   export TEST_DATABASE_URL=postgresql://postgres:postgres@localhost:5432/fastapi_test_db
   ```

4. Start the FastAPI service for the Playwright end-to-end tests:

   ```bash
   docker compose up -d web
   ```

5. Run the complete suite, including the test marked slow:

   ```bash
   python -m pytest --run-slow -q --tb=short
   ```

   For an explicit coverage requirement:

   ```bash
   python -m pytest --run-slow -v --cov=app --cov-report=term-missing --cov-report=html --cov-fail-under=100
   ```

   Open `htmlcov/index.html` to review HTML coverage details. A single failing test can be isolated using `python -m pytest -x -q --tb=short`.

### Latest locally verified results

```text
78 passed in 17.32s
TOTAL: 188 statements, 0 missed, 100% statement coverage (app/)
Python 3.14.4
```

These are local results, not a claim that GitHub-hosted CI or deployment has already succeeded. Coverage refers to the configured `app/` package, not every file in the repository.

## CI/CD with GitHub Actions

- **`.github/workflows/test.yml` — Assignment 10 CI:** Runs on pushes and pull requests to `main` and on manual dispatch. Starts a PostgreSQL 16 service, installs Python 3.14 dependencies and Playwright Chromium, starts FastAPI, runs all tests, checks coverage, and uploads an HTML report.
- **`.github/workflows/deploy.yml` — Assignment 10 Docker Deployment:** Runs after successful push-triggered CI on `main`. Builds the tested commit's Docker image, scans with Trivy, logs into Docker Hub, and pushes `latest` and a commit-specific `sha-...` tag.

The Trivy gate checks configured high/critical vulnerabilities, with `ignore-unfixed` enabled. Passing this scan does not guarantee that an image has no vulnerabilities.

### GitHub repository configuration

In **Settings → Secrets and variables → Actions**, add:

| Type | Name | Meaning |
| --- | --- | --- |
| Repository variable | `DOCKERHUB_USERNAME` | Your Docker Hub username |
| Repository secret | `DOCKERHUB_TOKEN` | Docker Hub access token with repository push permission |

The test workflow generates a temporary JWT test secret. Do not put secrets in workflow YAML or Git commits.

## Docker Hub image

**Docker Hub repository:** [aby3989/assignment10](https://hub.docker.com/repository/docker/aby3989/assignment10/general)


After the first successful deployment, pull and run the image:

```bash
docker pull aby3989/assignment10:latest
```

The published API requires a reachable PostgreSQL database and a secure JWT secret. Provide `DATABASE_URL` and `SECRET_KEY` through your runtime environment (for example, Docker Compose or an environment file excluded from Git). An image alone does not start PostgreSQL.

