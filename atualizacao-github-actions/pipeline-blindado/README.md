# Pipeline Blindado — tarefas-api

![Pipeline Blindado](https://github.com/junior-pires1/pipeline-blindado/actions/workflows/pipeline.yml/badge.svg)

API de tarefas (Node.js + Express) usada como fonte de um pipeline CI/CD com DevSecOps:
GitHub Actions (ou Jenkins), Docker, Trivy, SBOM, cosign, Kubernetes, Helm e Kyverno.
Trabalho da disciplina DevOps Tools.

- `.github/workflows/pipeline.yml` — pipeline principal (GitHub Actions)
- `Jenkinsfile` — implementação alternativa com os mesmos estágios
- `ataques/` — demonstração "Hackeie meu pipeline"

Veja `GUIA_EXECUCAO.md` para rodar tudo passo a passo.
