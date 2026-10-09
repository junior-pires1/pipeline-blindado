# Guia de Execução — Pipeline Blindado (GitHub Actions)

O pipeline roda no **GitHub Actions**, nos servidores do GitHub. Não é preciso
Docker nem Jenkins no seu computador. Os quadros **📸 PRINT** indicam o que capturar.

> O `Jenkinsfile` continua no repositório como implementação alternativa,
> com os mesmos estágios (veja a seção "Alternativa: Jenkins" no fim).

Pré-requisitos: Git Bash, Node.js 22 e o repositório já enviado ao GitHub.

---

## 1. Testar localmente

```bash
npm install
npm test                        # 7 testes devem passar
npm start                       # abra http://localhost:3000/health  (Ctrl+C para parar)
bash scripts/pipeline-local.sh  # precisa do semgrep: pip install semgrep
```
📸 PRINT: `/health` no navegador e o final `PIPELINE LOCAL APROVADO`.

## 2. Criar o ambiente de produção com aprovação manual

No GitHub: **Settings → Environments → New environment**
1. Nome: `producao` → **Configure environment**.
2. Marque **Required reviewers** e adicione o seu usuário.
3. **Save protection rules**.

📸 PRINT: tela do environment `producao` com o revisor obrigatório.

## 3. Disparar o pipeline na branch dev

```bash
git checkout dev
git push origin dev
```
Abra a aba **Actions** do repositório. O workflow **Pipeline Blindado** roda 4 jobs:

| Job | O que faz |
|---|---|
| 1. CI e portões de segurança | dependências, segredos (secretlint + Gitleaks), lint, testes, Semgrep, npm audit, SBOM |
| 2. Imagem, scan, SBOM e assinatura | build Docker, Trivy, Syft, push no GHCR por digest, cosign |
| 3. Kyverno – só imagem assinada | cluster Kubernetes temporário: aceita a imagem oficial e **bloqueia** uma imagem com backdoor (Ataque 3) |
| 4. Deploy (dev) | cluster Kubernetes temporário, Helm com o digest, smoke test e rollback |

📸 PRINT: visão geral do workflow com os 4 jobs verdes (o grafo de jobs).
📸 PRINT: o **Summary** (tabela "Portões de segurança" e "Artefato publicado e assinado").
📸 PRINT: dentro do job 2, o passo **11b. Verificar a assinatura**.
📸 PRINT: dentro do job 3, o passo **ATAQUE 3** com o erro do Kyverno.
📸 PRINT: dentro do job 4, os passos **13. Deploy com Helm** e **14. Smoke test**.
📸 PRINT: a imagem publicada em **Packages** (perfil ou página do repositório).

## 4. Promover entre ambientes

```bash
bash scripts/promover.sh homolog
bash scripts/promover.sh pre-prod
bash scripts/promover.sh main
```
Cada comando faz o merge, envia ao GitHub e dispara o pipeline do ambiente.
Na `main`, o job **4. Deploy (main)** fica **aguardando aprovação**:
abra o workflow, clique em **Review deployments**, marque `producao` e **Approve and deploy**.

📸 PRINT: a tela "Review deployments" (aprovação manual).
📸 PRINT: o deploy em produção concluído (3 réplicas prontas no Summary).

## 5. Os ataques (vão aparecer VERMELHOS no Actions)

```bash
bash ataques/enviar-ataque.sh typosquatting   # bloqueado no estágio 2
bash ataques/enviar-ataque.sh eval            # bloqueado no estágio 5c (Semgrep)
bash ataques/enviar-ataque.sh segredo         # bloqueado no estágio 4 (secretlint/Gitleaks)
```
Cada comando cria a branch `ataque/<nome>`, envia ao GitHub e volta para a sua branch.

> Se o GitHub **recusar o push** do ataque "segredo" com a mensagem
> *"Push cannot contain secrets"*, isso é a proteção de push do próprio GitHub
> barrando a credencial antes mesmo do pipeline. Tire o print: é mais uma camada de defesa!

📸 PRINT: lista de execuções no Actions com os ataques em vermelho (❌).
📸 PRINT: para cada ataque, o passo que falhou aberto, mostrando o motivo.

Ataques locais (sem GitHub), para a apresentação:
```bash
bash ataques/01-segredo-vazado.sh
bash ataques/02-typosquatting.sh
bash ataques/02b-dependencia-vulneravel.sh
bash ataques/04-codigo-inseguro.sh
bash ataques/03b-artefato-adulterado-local.sh
```

Para apagar as branches de ataque depois:
```bash
git push origin --delete ataque/typosquatting ataque/eval ataque/segredo
```

## 6. (Opcional) Exigir o pipeline verde para a main

Depois da primeira execução: **Settings → Branches → editar a regra `main`** →
marque **Require status checks to pass** → busque `1. CI e portões de segurança` → **Save changes**.

---

## Alternativa: Jenkins

O `Jenkinsfile` implementa os mesmos estágios para quem tem Docker Desktop:
```powershell
docker build -t jenkins-blindado ./jenkins
docker run -d --name jenkins-blindado -u root -p 8080:8080 -v jenkins_blindado_home:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock jenkins-blindado
```
Credenciais esperadas: `github-token`, `ghcr-credentials`, `cosign-key`, `cosign-password`, `kubeconfig-kind`.
Crie um job **Multibranch Pipeline** apontando para o repositório.
