# Step 09: Deploy Manifests

## Purpose
Generate Kubernetes deployment manifests in the requested format(s): raw K8s YAML, Helm charts, and/or Kustomize overlays.

## Subagent Instructions

You are the Deploy Manifests subagent. Generate production-grade deployment configurations.

### Inputs
- Architecture (services, ports, env vars, dependencies)
- Docker configuration (image names, health checks)
- Active flags: `--k8s`, `--helm`, `--kustomize`, or `--all-deploy`
- Environment strategy: srv4dev, test, prod

### Process

Generate ONLY the formats requested by the user's flags. For each format:

---

### A. Raw Kubernetes YAML (`--k8s`)

Create `deploy/k8s/` with per-environment structure:

```
deploy/k8s/
├── base/
│   ├── namespace.yaml
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   ├── ingress.yaml
│   ├── db-statefulset.yaml        # Only for dev — prod uses managed DB
│   ├── db-service.yaml
│   ├── redis-deployment.yaml      # If used
│   ├── redis-service.yaml
│   └── configmap.yaml
├── overlays/
│   ├── srv4dev/
│   │   ├── kustomization.yaml     # Even raw K8s benefits from kustomize for overlays
│   │   ├── patches/
│   │   └── configmap.yaml
│   ├── test/
│   │   ├── kustomization.yaml
│   │   ├── patches/
│   │   └── configmap.yaml
│   └── prod/
│       ├── kustomization.yaml
│       ├── patches/
│       ├── configmap.yaml
│       └── hpa.yaml               # HPA only in prod
```

Key manifests:

**Deployment** — for each service:
- Resource requests AND limits
- Liveness and readiness probes
- Security context (non-root, read-only FS where possible)
- Environment from ConfigMap and Secret refs
- Image pull policy
- Rolling update strategy

**Service** — ClusterIP for internal, LoadBalancer/NodePort as needed

**Ingress** — with annotations for your ingress controller (nginx-ingress default)

**ConfigMap** — non-sensitive configuration per environment

**Secrets** — referenced but NOT created (use sealed-secrets or external-secrets)

**HPA** (prod only) — horizontal pod autoscaler with sane defaults

---

### B. Helm Charts (`--helm`)

Create `deploy/helm/{project-name}/`:

```
deploy/helm/{project-name}/
├── Chart.yaml
├── values.yaml                    # Defaults (dev-oriented)
├── values-srv4dev.yaml
├── values-test.yaml
├── values-prod.yaml
├── templates/
│   ├── _helpers.tpl
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml                # Template, values from external
│   ├── hpa.yaml
│   ├── serviceaccount.yaml
│   └── NOTES.txt
└── .helmignore
```

**values.yaml** structure:
```yaml
global:
  namespace: "{project}-dev"
  imagePullPolicy: IfNotPresent

backend:
  replicaCount: 1
  image:
    repository: registry.example.com/{project}/backend
    tag: "latest"
  port: 3000
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
  env: {}
  probes:
    liveness:
      path: /health
      port: 3000
    readiness:
      path: /health
      port: 3000

frontend:
  replicaCount: 1
  image:
    repository: registry.example.com/{project}/frontend
    tag: "latest"
  port: 80
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 256Mi

database:
  # Set to false if using managed DB (RDS, Cloud SQL, Azure DB)
  enabled: true
  image: postgres:16-alpine
  storage: 5Gi
  storageClass: ""

redis:
  enabled: false
  image: redis:7-alpine

ingress:
  enabled: true
  className: nginx
  annotations: {}
  hosts:
    - host: "{project}.local"
      paths:
        - path: /api
          service: backend
        - path: /
          service: frontend
  tls: []

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 5
  targetCPUUtilization: 80
```

**Per-environment values** override only what changes:
- `values-srv4dev.yaml`: low resources, 1 replica, DB enabled
- `values-test.yaml`: moderate resources, 1-2 replicas
- `values-prod.yaml`: proper resources, HPA enabled, DB disabled (managed), TLS enabled

---

### C. Kustomize (`--kustomize`)

Create `deploy/kustomize/`:

```
deploy/kustomize/
├── base/
│   ├── kustomization.yaml
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   └── namespace.yaml
├── overlays/
│   ├── srv4dev/
│   │   ├── kustomization.yaml
│   │   ├── patches/
│   │   │   ├── backend-resources.yaml
│   │   │   └── replicas.yaml
│   │   └── configmap.yaml
│   ├── test/
│   │   ├── kustomization.yaml
│   │   ├── patches/
│   │   └── configmap.yaml
│   └── prod/
│       ├── kustomization.yaml
│       ├── patches/
│       │   ├── backend-resources.yaml
│       │   ├── replicas.yaml
│       │   └── hpa.yaml
│       └── configmap.yaml
```

Use Kustomize features properly:
- `namePrefix` / `nameSuffix` for environment isolation
- `commonLabels` for consistent labeling
- Strategic merge patches for environment-specific overrides
- `configMapGenerator` for ConfigMaps
- `secretGenerator` references (not inline secrets)

---

### Environment Differences

| Aspect | srv4dev | test | prod |
|--------|---------|------|------|
| Replicas | 1 | 1-2 | 2-5 (HPA) |
| Resources | Minimal | Moderate | Production |
| DB | In-cluster | In-cluster or managed | Managed (external) |
| Ingress TLS | Optional | Optional | Required |
| Image pull | IfNotPresent | Always | Always |
| HPA | No | No | Yes |
| PDB | No | No | Yes |
| Secrets | ConfigMap OK | External | External (sealed/vault) |

### Output

```markdown
# Phase: Deploy Manifests
# Timestamp: {ISO 8601}
# Status: PASS

## Formats Generated
- [x/] Raw K8s
- [x/] Helm
- [x/] Kustomize

## Structure
{tree of generated files}

## Deploy Commands

### Raw K8s
kubectl apply -k deploy/k8s/overlays/srv4dev/

### Helm
helm install {project} deploy/helm/{project} -f deploy/helm/{project}/values-srv4dev.yaml -n {namespace}

### Kustomize
kubectl apply -k deploy/kustomize/overlays/srv4dev/

## Per-Environment Notes
- srv4dev: {specifics}
- test: {specifics}
- prod: {specifics}

## Secrets Management
{how secrets should be managed — NOT included in manifests}
```

### Rules
- NEVER include real secrets or credentials in manifests
- Always set resource requests AND limits
- Always include health checks (liveness + readiness)
- Always use specific image tags, never `latest` in non-dev envs
- Security contexts: non-root, read-only root FS where possible
- Use namespaces for environment isolation
- Prod must have PodDisruptionBudget
- All labels must follow Kubernetes recommended labels
- Ingress annotations should be configurable (not hardcoded to one controller)
- StatefulSets for databases, Deployments for stateless services
