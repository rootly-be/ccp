# Step 10: GitLab CI

## Purpose
Generate a comprehensive GitLab CI pipeline for build, test, security, and multi-environment deployment.

## Subagent Instructions

You are the GitLab CI subagent. Create a production-grade `.gitlab-ci.yml`.

### Inputs
- Architecture (tech stack, services)
- Docker configuration (Dockerfiles)
- Deploy manifests (K8s/Helm/Kustomize — whichever was generated)
- Environment strategy: srv4dev → test → prod

### Process

Generate `.gitlab-ci.yml` with the following pipeline structure:

```yaml
stages:
  - validate
  - test
  - build
  - security
  - deploy-dev
  - deploy-test
  - deploy-prod

variables:
  # Registry
  REGISTRY: ${CI_REGISTRY}
  BACKEND_IMAGE: ${REGISTRY}/${CI_PROJECT_PATH}/backend
  FRONTEND_IMAGE: ${REGISTRY}/${CI_PROJECT_PATH}/frontend
  # Versioning
  IMAGE_TAG: ${CI_COMMIT_SHORT_SHA}
  # Kubernetes
  KUBE_NAMESPACE_DEV: "${CI_PROJECT_NAME}-srv4dev"
  KUBE_NAMESPACE_TEST: "${CI_PROJECT_NAME}-test"
  KUBE_NAMESPACE_PROD: "${CI_PROJECT_NAME}-prod"

# ============================================================
# Stage: Validate
# ============================================================
lint:backend:
  stage: validate
  image: node:20-alpine  # or python, go — match tech stack
  script:
    - cd backend
    - npm ci
    - npm run lint
  rules:
    - changes:
        - backend/**/*

lint:frontend:
  stage: validate
  image: node:20-alpine
  script:
    - cd frontend
    - npm ci
    - npm run lint
  rules:
    - changes:
        - frontend/**/*

typecheck:
  stage: validate
  image: node:20-alpine
  script:
    - cd backend && npm ci && npm run typecheck
    - cd ../frontend && npm ci && npm run typecheck
  rules:
    - changes:
        - backend/**/*
        - frontend/**/*

# ============================================================
# Stage: Test
# ============================================================
test:backend:
  stage: test
  image: node:20-alpine
  services:
    - postgres:16-alpine
    - redis:7-alpine  # if used
  variables:
    POSTGRES_DB: test_db
    POSTGRES_USER: test_user
    POSTGRES_PASSWORD: test_pass
    DATABASE_URL: "postgresql://test_user:test_pass@postgres:5432/test_db"
    REDIS_URL: "redis://redis:6379"
  script:
    - cd backend
    - npm ci
    - npm run migrate:test  # or equivalent
    - npm run test -- --coverage
  coverage: '/Lines\s*:\s*(\d+\.?\d*)%/'
  artifacts:
    reports:
      junit: backend/test-results.xml
      coverage_report:
        coverage_format: cobertura
        path: backend/coverage/cobertura-coverage.xml
  rules:
    - changes:
        - backend/**/*

test:frontend:
  stage: test
  image: node:20-alpine
  script:
    - cd frontend
    - npm ci
    - npm run test -- --coverage
  artifacts:
    reports:
      junit: frontend/test-results.xml
  rules:
    - changes:
        - frontend/**/*

# ============================================================
# Stage: Build (Kaniko)
# ============================================================
.build_template: &build_template
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:v1.23.2-debug
    entrypoint: [""]
  script:
    - mkdir -p /kaniko/.docker
    - echo "{\"auths\":{\"${CI_REGISTRY}\":{\"auth\":\"$(printf '%s:%s' "${CI_REGISTRY_USER}" "${CI_REGISTRY_PASSWORD}" | base64 | tr -d '\n')\"}}}" > /kaniko/.docker/config.json
    - /kaniko/executor
      --context "${CI_PROJECT_DIR}/${SERVICE_DIR}"
      --dockerfile "${CI_PROJECT_DIR}/${SERVICE_DIR}/Dockerfile"
      --destination "${IMAGE_NAME}:${IMAGE_TAG}"
      --destination "${IMAGE_NAME}:latest"
      --cache=true
      --cache-repo="${IMAGE_NAME}/cache"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_MERGE_REQUEST_IID

build:backend:
  <<: *build_template
  variables:
    SERVICE_DIR: backend
    IMAGE_NAME: ${BACKEND_IMAGE}
  rules:
    - changes:
        - backend/**/*

build:frontend:
  <<: *build_template
  variables:
    SERVICE_DIR: frontend
    IMAGE_NAME: ${FRONTEND_IMAGE}
  rules:
    - changes:
        - frontend/**/*

# ============================================================
# Stage: Security
# ============================================================
sast:
  stage: security
  image: node:20-alpine
  script:
    - cd backend && npm audit --audit-level=high || true
    - cd ../frontend && npm audit --audit-level=high || true
  allow_failure: true
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

container_scanning:
  stage: security
  image:
    name: aquasec/trivy:latest
    entrypoint: [""]
  script:
    - trivy image --exit-code 1 --severity HIGH,CRITICAL "${BACKEND_IMAGE}:${IMAGE_TAG}" || true
    - trivy image --exit-code 1 --severity HIGH,CRITICAL "${FRONTEND_IMAGE}:${IMAGE_TAG}" || true
  allow_failure: true
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

# ============================================================
# Stage: Deploy
# ============================================================
# Adapt deploy commands based on which deploy format was generated:
# - Helm: helm upgrade --install
# - Kustomize: kubectl apply -k
# - Raw K8s: kubectl apply -f

.deploy_template: &deploy_template
  stage: deploy-dev  # Overridden per environment
  image: bitnami/kubectl:latest  # or dtzar/helm-client if using Helm
  before_script:
    - echo "Deploying to ${DEPLOY_ENV}..."

# --- srv4dev: auto-deploy on main branch ---
deploy:srv4dev:
  <<: *deploy_template
  stage: deploy-dev
  variables:
    DEPLOY_ENV: srv4dev
    KUBE_NAMESPACE: ${KUBE_NAMESPACE_DEV}
  script:
    # HELM example:
    # - helm upgrade --install ${CI_PROJECT_NAME} deploy/helm/${CI_PROJECT_NAME}
    #     -f deploy/helm/${CI_PROJECT_NAME}/values-srv4dev.yaml
    #     --set backend.image.tag=${IMAGE_TAG}
    #     --set frontend.image.tag=${IMAGE_TAG}
    #     -n ${KUBE_NAMESPACE} --create-namespace
    #
    # KUSTOMIZE example:
    # - cd deploy/kustomize/overlays/srv4dev
    # - kustomize edit set image backend=${BACKEND_IMAGE}:${IMAGE_TAG}
    # - kustomize edit set image frontend=${FRONTEND_IMAGE}:${IMAGE_TAG}
    # - kubectl apply -k . -n ${KUBE_NAMESPACE}
    #
    # Uncomment the appropriate section based on deploy format
    - echo "TODO: Uncomment deploy commands for your chosen format"
  environment:
    name: srv4dev
    url: https://${CI_PROJECT_NAME}-dev.example.com
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: on_success

# --- test: auto-deploy after srv4dev ---
deploy:test:
  <<: *deploy_template
  stage: deploy-test
  variables:
    DEPLOY_ENV: test
    KUBE_NAMESPACE: ${KUBE_NAMESPACE_TEST}
  script:
    - echo "TODO: Uncomment deploy commands"
  environment:
    name: test
    url: https://${CI_PROJECT_NAME}-test.example.com
  needs:
    - deploy:srv4dev
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: on_success

# --- prod: MANUAL deploy ---
deploy:prod:
  <<: *deploy_template
  stage: deploy-prod
  variables:
    DEPLOY_ENV: prod
    KUBE_NAMESPACE: ${KUBE_NAMESPACE_PROD}
  script:
    - echo "TODO: Uncomment deploy commands"
  environment:
    name: production
    url: https://${CI_PROJECT_NAME}.example.com
  needs:
    - deploy:test
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual  # ALWAYS manual for prod
```

### Customization

The template above is a starting point. The subagent MUST:

1. **Adapt to the actual tech stack** — replace Node.js commands with Python/Go equivalents if needed
2. **Uncomment the correct deploy commands** based on which format was generated (Helm/Kustomize/raw K8s)
3. **Adjust service dependencies** in test jobs (add/remove postgres, redis, etc.)
4. **Set correct coverage regex** for the test framework
5. **Add any tech-specific jobs** (e.g., migration job for DB changes)

### Output

```markdown
# Phase: GitLab CI
# Timestamp: {ISO 8601}
# Status: PASS

## Pipeline Structure
| Stage | Jobs | Trigger |
|-------|------|---------|
| validate | lint:backend, lint:frontend, typecheck | changes |
| test | test:backend, test:frontend | changes |
| build | build:backend, build:frontend | main/MR |
| security | sast, container_scanning | main |
| deploy-dev | deploy:srv4dev | main (auto) |
| deploy-test | deploy:test | main (auto, after dev) |
| deploy-prod | deploy:prod | main (MANUAL) |

## Files Created
- `.gitlab-ci.yml`

## Environment URLs
- srv4dev: https://{project}-dev.example.com
- test: https://{project}-test.example.com
- prod: https://{project}.example.com

## Required CI/CD Variables (set in GitLab UI)
- `KUBE_CONFIG` — Kubernetes config for deployments
- {other variables as needed}

## Notes
{any pipeline-specific notes or TODO items}
```

### Rules
- Production deploy is ALWAYS manual — never auto-deploy to prod
- Use `rules:` not `only:/except:` (deprecated)
- Use `needs:` for DAG optimization
- Cache dependencies between jobs
- Use Kaniko for Docker builds (no Docker-in-Docker)
- Security scanning should `allow_failure: true` to not block pipeline
- Include coverage reporting
- Include test artifacts (junit reports)
- All sensitive values via CI/CD variables, never in the YAML
