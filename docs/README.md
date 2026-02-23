# Architecture & Documentation

This directory contains architecture diagrams, screenshots, and supplementary documentation for the Swiggy GitOps project.

## Contents

- [tools-verification.md](tools-verification.md) — Installation verification checklist for all DevOps tools

## Architecture Overview

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Developer  │────▶│   GitHub     │────▶│   Jenkins    │
│   Workstation│     │   Repository │     │   CI Server  │
└──────────────┘     └──────┬───────┘     └──────┬───────┘
                            │                     │
                    ArgoCD watches          Build & Push
                    for changes            Docker Image
                            │                     │
                            ▼                     ▼
                     ┌──────────────┐     ┌──────────────┐
                     │   ArgoCD     │     │   AWS ECR    │
                     │   (GitOps)   │     │   Registry   │
                     └──────┬───────┘     └──────────────┘
                            │
                     Deploy to K8s
                            │
                            ▼
                     ┌──────────────┐
                     │   AWS EKS    │
                     │   Cluster    │
                     └──────┬───────┘
                            │
                     ┌──────┴──────┐
                     ▼             ▼
              ┌────────────┐ ┌────────────┐
              │ Prometheus │ │  Grafana   │
              │ Monitoring │ │ Dashboards │
              └────────────┘ └────────────┘
```

## Screenshots

_Add deployment screenshots and Grafana dashboard previews here._
