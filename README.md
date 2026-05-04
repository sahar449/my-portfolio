# My Portfolio — DevOps on AWS EKS

Personal portfolio deployed as two Flask microservices on Amazon EKS, with full GitOps via ArgoCD and automated CI/CD through GitHub Actions.

---

## Architecture

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'fontSize': '14px'}}}%%
flowchart TB
    classDef aws  fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#000,font-weight:bold
    classDef k8s  fill:#326CE5,stroke:#1E4DB7,stroke-width:2px,color:#fff,font-weight:bold
    classDef gh   fill:#161b22,stroke:#30363d,stroke-width:2px,color:#fff,font-weight:bold
    classDef tf   fill:#7B42BC,stroke:#5a2d8a,stroke-width:2px,color:#fff,font-weight:bold
    classDef mon  fill:#E6522C,stroke:#bf3a1a,stroke-width:2px,color:#fff,font-weight:bold
    classDef user fill:#00a86b,stroke:#007a4d,stroke-width:2px,color:#fff,font-weight:bold

    User(["👤 User\nwww.saharbittman.com"]):::user

    subgraph GH["🐙 GitHub"]
        Repo["📁 my-portfolio"]:::gh
        subgraph Pipeline["⚙️ GitHub Actions"]
            direction LR
            BS["🏗️ bootstrap.yml\nTerraform · Trivy IaC"]:::gh
            CI["🔨 ci.yml\nTrivy · Build · SBOM · Push"]:::gh
            CD["🚀 cd.yml\nTrivy · ArgoCD · Smoke Test"]:::gh
            BS --> CI --> CD
        end
    end

    TF["🏗️ Terraform\nVPC · EKS · RDS · IAM\nSSL · ECR · CloudWatch"]:::tf

    subgraph AWS["☁️ AWS — us-west-2"]
        ECR["📦 ECR\nfrontend · backend"]:::aws
        ACM["🔒 ACM\n*.saharbittman.com"]:::aws
        CW["📊 CloudWatch\nContainer Insights · Logs"]:::mon

        subgraph VPC["🌐 VPC"]
            ALB["⚖️ ALB\nHTTPS · SSL Redirect"]:::aws

            subgraph EKS["⎈ EKS 1.34"]
                ArgoCD["🐙 ArgoCD\nargocd.saharbittman.com"]:::k8s

                subgraph PubNodes["🟢 Public Nodes"]
                    FE["🖥️ Frontend :5000\nHPA · PDB · NetworkPolicy"]:::k8s
                end

                subgraph PrvNodes["🔒 Private Nodes"]
                    BE["⚙️ Backend :5002\nHPA · PDB · NetworkPolicy"]:::k8s
                end
            end

            RDS[("🗄️ RDS MySQL\nMulti-AZ")]:::aws
        end
    end

    style GH       fill:#0d1117,stroke:#30363d,color:#fff
    style Pipeline fill:#161b22,stroke:#21262d,color:#c9d1d9
    style AWS      fill:#fffbf0,stroke:#FF9900,color:#232F3E
    style VPC      fill:#fff8e6,stroke:#e67e22,color:#232F3E
    style EKS      fill:#eff6ff,stroke:#326CE5,color:#1E4DB7
    style PubNodes fill:#f0fdf4,stroke:#16a34a,color:#15803d
    style PrvNodes fill:#fff1f2,stroke:#e11d48,color:#be123c

    Repo --> Pipeline
    BS --> TF
    CI -->|"push :sha"| ECR
    CD -->|"ApplicationSet"| ArgoCD
    ArgoCD -->|"Helm sync"| FE & BE
    FE & BE -.->|"pull image"| ECR
    ACM --> ALB
    User -->|"HTTPS"| ALB
    ALB -->|"/"| FE
    ALB -->|"/api/backend"| BE
    FE -->|"internal"| BE
    BE -->|"3306"| RDS
    FE & BE -.->|"logs · metrics"| CW
```

---

## Request Trace

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'fontSize': '14px', 'actorBkg': '#326CE5', 'actorTextColor': '#fff', 'actorBorderColor': '#1E4DB7', 'activationBkgColor': '#eff6ff', 'signalColor': '#555', 'signalTextColor': '#333', 'noteBkgColor': '#fffbf0', 'noteTextColor': '#232F3E'}}}%%
sequenceDiagram
    actor User as 👤 User
    participant ALB as ⚖️ ALB
    participant FE  as 🖥️ Frontend
    participant BE  as ⚙️ Backend
    participant RDS as 🗄️ RDS

    User->>ALB: GET https://www.saharbittman.com
    ALB->>FE: GET /
    FE-->>User: 200 HTML + images

    User->>ALB: GET /api/backend/profile
    ALB->>BE: GET /profile
    BE->>RDS: SELECT * FROM profile
    RDS-->>BE: row data
    BE-->>User: 200 JSON

    User->>ALB: GET /api/backend/certificates
    ALB->>BE: GET /certificates
    BE->>RDS: SELECT * FROM certificates
    RDS-->>BE: rows
    BE-->>User: 200 JSON
```

---

## Tech Stack

| Layer | Tools |
|-------|-------|
| **Cloud** | AWS EKS 1.34 · RDS MySQL · ECR · ACM · VPC |
| **IaC** | Terraform (VPC · EKS · IAM · RDS · SSL · CloudWatch) |
| **GitOps** | ArgoCD · ApplicationSet · Helm · sync-waves |
| **CI/CD** | GitHub Actions · matrix builds · OIDC auth |
| **Security** | Trivy · IRSA · Secrets Manager · NetworkPolicy · seccomp |
| **Observability** | CloudWatch Container Insights · CloudWatch Logs |
| **App** | Python Flask · Docker (Alpine) · non-root UID 1000 |

---

## Project Structure

```
.
├── .github/workflows/
│   ├── bootstrap.yml        # Terraform apply/destroy (manual trigger)
│   ├── ci.yml               # Build, Trivy scan, push to ECR, SBOM
│   └── cd.yml               # Trivy scan ArgoCD manifests, deploy
├── ArgoCD/
│   ├── applicationset.yaml  # Deploys both services via sync-waves
│   ├── frontend/helm_chart/ # Deployment, Service, Ingress, HPA, PDB, NetworkPolicy
│   └── backend/helm_chart/  # Deployment, Service, HPA, PDB, NetworkPolicy
├── infra/
│   ├── main.tf
│   └── modules/
│       ├── vpc/             # VPC, subnets, NAT, IGW
│       ├── eks/             # EKS cluster + managed addons
│       ├── iam/             # IRSA roles (ALB, external-dns, secrets)
│       ├── ecr/             # Container registries
│       ├── rds/             # MySQL Multi-AZ
│       ├── ssl/             # ACM wildcard certificate
│       └── monitoring/      # CloudWatch Container Insights + Log Groups
└── services/
    ├── frontend/            # Flask :5000 — HTML + images
    └── backend/             # Flask :5002 — profile + certificates from RDS
```

---

## CI/CD Pipeline

```
 bootstrap.yml        ci.yml                   cd.yml
 (manual)             (auto after bootstrap)   (auto after CI)
┌─────────────┐      ┌──────────────────────┐  ┌─────────────────────┐
│ Trivy IaC   │      │ Trivy fs scan        │  │ Trivy ArgoCD scan   │
│ scan infra/ │ ───► │ Build & push to ECR  │  │ Deploy ApplicationSet│
│             │      │ Trivy image scan     │  │ Smoke test          │
│ terraform   │      │ Generate SBOM        │  │                     │
│ apply       │      │ Smoke test container │  │                     │
└─────────────┘      └──────────────────────┘  └─────────────────────┘
```

### bootstrap.yml — Terraform
- Trivy IaC scan (`config + secret`) on `infra/`
- `terraform apply` → VPC, EKS, RDS, IAM, SSL, ECR, CloudWatch, ArgoCD addon
- Auto-destroys on apply failure

### ci.yml — Build & Test
| Step | Details |
|------|---------|
| Trivy filesystem | `vuln + secret + config` on source code |
| Build & push | Docker image tagged with commit SHA pushed to ECR |
| Trivy image | `vuln + secret + config` on the built image |
| SBOM | CycloneDX format uploaded as artifact |
| Smoke test | Container started locally, `/health` endpoint verified |

### cd.yml — Deploy
| Step | Details |
|------|---------|
| Trivy scan | `config + secret` on `ArgoCD/` manifests |
| aws-auth | Grants IAM user cluster access |
| ApplicationSet | `envsubst` injects ECR URLs → `kubectl apply` |
| Smoke test | Polls `https://www.saharbittman.com/health` |

**Destroy path** (manual): deletes ArgoCD apps → waits for ALB cleanup → `terraform destroy`

---

## Security

| Control | Details |
|---------|---------|
| **Non-root** | All pods run as UID 1000 (`appuser`), `allowPrivilegeEscalation: false` |
| **Capabilities** | `capabilities.drop: ALL` on every container |
| **Seccomp** | `RuntimeDefault` profile on every pod |
| **IRSA** | Least-privilege IAM per service account (no node-level permissions) |
| **Secrets** | RDS credentials via AWS Secrets Manager + secrets-store-csi |
| **NetworkPolicy** | Backend reachable only from frontend pods; port 3306 only from backend |
| **Node isolation** | Frontend on public nodes, backend on private nodes (no internet) |
| **Trivy** | Scans source, Dockerfile, image, IaC, and ArgoCD manifests at every stage |

---

## Infrastructure Modules

| Module | Resources |
|--------|----------|
| `vpc` | VPC, public/private subnets across 2 AZs, NAT gateway, IGW |
| `eks` | EKS 1.34, 2 node groups (public/private), managed addons |
| `iam` | IRSA roles — ALB controller, external-dns, EBS CSI, secrets |
| `ecr` | ECR repositories for frontend and backend |
| `rds` | MySQL Multi-AZ, subnet group, security group |
| `ssl` | ACM wildcard certificate (`*.saharbittman.com`) with DNS validation |
| `monitoring` | CloudWatch Container Insights addon + Log Groups |

---

## Quick Start

```bash
# 1. Fork the repo and set GitHub Secrets:
#    AWS_ROLE_TO_ASSUME · AWS_ACCOUNT_NUMBER · AWS_USER · DB_PASS

# 2. Run Bootstrap (GitHub Actions UI)
#    Actions → Bootstrap Infra → Run workflow → apply

# 3. CI runs automatically after bootstrap
#    Builds, scans, and pushes images to ECR

# 4. CD runs automatically after CI
#    Deploys ApplicationSet to ArgoCD

# 5. App:    https://www.saharbittman.com
#    ArgoCD: https://argocd.saharbittman.com
```

## Cleanup

Run CD workflow → `destroy`, then Bootstrap → `destroy`.

---

**Sahar Bittman** — [github.com/sahar449](https://github.com/sahar449)
