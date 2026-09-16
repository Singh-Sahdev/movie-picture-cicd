# Movie Picture App - CI/CD Pipeline Project

Hi there! Welcome to my DevOps project repository for the **Movie Picture** application. 

In this project, I built automated Continuous Integration (CI) and Continuous Deployment (CD) pipelines using **GitHub Actions** for a full-stack movie catalog application. The app consists of:
- **Frontend**: A React application written in TypeScript / JavaScript.
- **Backend**: A REST API built with Python and Flask.

---

## What I Built

I created 4 distinct GitHub Actions workflow files inside the `.github/workflows/` directory:

| Workflow File | Workflow Name | Trigger Event | What it Does |
|---|---|---|---|
| `.github/workflows/frontend-ci.yaml` | `Frontend Continuous Integration` | Pull request on `main` (frontend paths) & manual trigger | Runs `npm run lint` and `npm run test` in parallel. If both pass, it builds the Docker image. |
| `.github/workflows/backend-ci.yaml` | `Backend Continuous Integration` | Pull request on `main` (backend paths) & manual trigger | Runs `pipenv run lint` and `pipenv run test` in parallel. If both pass, it builds the Docker image. |
| `.github/workflows/frontend-cd.yaml` | `Frontend Continuous Deployment` | Push / merge to `main` (frontend paths) & manual trigger | Runs linting and tests. If they pass, builds Docker image with `REACT_APP_MOVIE_API_URL`, logs into AWS ECR, tags with Git SHA, pushes image, and deploys to EKS using `kustomize` & `kubectl`. |
| `.github/workflows/backend-cd.yaml` | `Backend Continuous Deployment` | Push / merge to `main` (backend paths) & manual trigger | Runs linting and tests. If they pass, builds Docker image, logs into AWS ECR, tags with Git SHA, pushes image, and deploys to EKS using `kustomize` & `kubectl`. |

---

## How the Pipelines Work (My Notes)

### 1. Parallel Job Execution for Speed
To make sure pull requests are checked quickly, both CI workflows run linting and testing at the same time (in parallel). 

### 2. Job Dependency (`needs` keyword)
I configured the `build` and `deploy` jobs to depend on the `lint` and `test` jobs using the `needs: [lint, test]` syntax. This ensures that we never waste time or cloud resources building or deploying broken code if linting or tests fail.

### 3. Dependency Caching
To speed up workflow execution times:
- For Frontend: I used `actions/cache@v3` targeting `~/.npm` keying on `package-lock.json`.
- For Backend: I used `actions/cache@v3` targeting `~/.local/share/virtualenvs` keying on `Pipfile.lock`.

### 4. Secure AWS Credentials (No Hardcoded Keys!)
All AWS credentials and sensitive configurations are stored securely inside GitHub Repository Secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `EKS_CLUSTER_NAME`
- `REACT_APP_MOVIE_API_URL`
- `ECR_REPOSITORY_FRONTEND` (optional, defaults to `mp-frontend`)
- `ECR_REPOSITORY_BACKEND` (optional, defaults to `mp-backend`)

The workflows log in using the official 3rd-party action `aws-actions/amazon-ecr-login@v1`. No secrets or keys are hardcoded anywhere in the YAML files.

### 5. Git SHA Tagging
When deploying to AWS ECR and Kubernetes, images are tagged with `${{ github.sha }}`. This ensures that every deployment is traceable back to the exact commit in Git.

---

## Local Development & Testing Guide

If you want to run or test the apps on your machine before pushing code, here are the commands I used:

### Frontend Local Setup & Tests
```bash
cd starter/frontend

# Install node dependencies
npm ci

# Run linter
npm run lint

# Run unit tests in non-interactive CI mode
CI=true npm test

# Build docker image locally
docker build --build-arg REACT_APP_MOVIE_API_URL=http://localhost:5000 --tag mp-frontend:latest .

# Run container locally
docker run --name mp-frontend -p 3000:3000 -d mp-frontend
```

### Backend Local Setup & Tests
```bash
cd starter/backend

# Install dependencies using pipenv
pipenv install --dev

# Run linter
pipenv run lint

# Run tests
pipenv run test

# Build docker image locally
docker build --tag mp-backend:latest .

# Run container locally
docker run -p 5000:5000 --name mp-backend -d mp-backend
```

---

## Deploying Infrastructure to AWS (EKS & ECR)

If you're deploying this app to AWS:

1. **Provision EKS Cluster with Terraform**:
   ```bash
   cd setup/terraform
   terraform init
   terraform apply
   ```
2. **Configure Kubernetes Auth**:
   ```bash
   cd setup
   ./init.sh
   ```
3. **Set Up GitHub Repository Secrets**:
   Go to your GitHub repository -> **Settings** -> **Secrets and variables** -> **Actions** -> **New repository secret** and add your AWS credentials (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`).

4. **Tear Down AWS Resources (Important!)**:
   Once you're done testing, remember to destroy all cloud infrastructure to prevent extra AWS charges:
   ```bash
   cd setup/terraform
   terraform destroy
   ```

---

Thank you for reviewing my project! Feel free to trigger the workflows manually from the **Actions** tab on GitHub or by creating pull requests.
