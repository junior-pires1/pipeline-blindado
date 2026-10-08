# Guia de Execução — Pipeline Blindado

Passo a passo para rodar o projeto e tirar os prints do relatório.
Os quadros **📸 PRINT** indicam exatamente o que capturar.

Pré-requisitos: Windows 10/11, Docker Desktop, Git Bash, Node.js 22 e conta no GitHub.

---

## 1. Testar localmente (5 min)

```bash
npm install
npm test                      # 7 testes devem passar
npm start                     # abra http://localhost:3000/health
bash scripts/pipeline-local.sh
```
📸 PRINT 1: saída final `PIPELINE LOCAL APROVADO`.

## 2. Subir para o GitHub com as 5 branches

```bash
git remote add origin https://github.com/SEU-USUARIO/pipeline-blindado.git
git push -u origin main
for b in dev homolog pre-prod sustain; do git push origin $b; done
git config core.hooksPath .githooks          # ativa o hook anti-segredo
```
Em **Settings → Branches**, proteja a `main` (exigir pull request e status check do Jenkins).
📸 PRINT 2: lista de branches no GitHub. 📸 PRINT 3: regra de proteção da `main`.

## 3. Subir o Jenkins com as ferramentas

```powershell
docker build -t jenkins-blindado ./jenkins
docker network create kind
docker run -d --name jenkins -u root --network kind `
  -p 8080:8080 -p 50000:50000 `
  -v jenkins_home:/var/jenkins_home `
  -v /var/run/docker.sock:/var/run/docker.sock `
  jenkins-blindado
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```
Siga os passos 4–6 do `INSTALACAO_JENKINS.md` do professor (desbloquear, plugins, usuário).

> `-u root` e o socket do Docker são uma simplificação de laboratório; em produção, use agentes dedicados.

## 4. Cluster Kubernetes local (kind) + Kyverno

```bash
kind create cluster --name blindado
helm repo add kyverno https://kyverno.github.io/kyverno/
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
kind get kubeconfig --internal --name blindado > kubeconfig-kind.yaml
```

## 5. Chaves de assinatura (cosign)

```bash
cosign generate-key-pair        # gera cosign.key (secreta) e cosign.pub
```
Cole o conteúdo de `cosign.pub` em `k8s/kyverno-somente-imagens-assinadas.yaml` e aplique:
```bash
kubectl apply -f k8s/kyverno-somente-imagens-assinadas.yaml
```
📸 PRINT 4: `kubectl get clusterpolicy` mostrando a política `READY`.

## 6. Credenciais no Jenkins (Manage Jenkins → Credentials)

| ID | Tipo | Conteúdo |
|---|---|---|
| `github-token` | Username with password | usuário GitHub + token (repo, admin:repo_hook) |
| `ghcr-credentials` | Username with password | usuário GitHub + token com `write:packages` |
| `cosign-key` | Secret file | arquivo `cosign.key` |
| `cosign-password` | Secret text | senha da chave cosign |
| `kubeconfig-kind` | Secret file | arquivo `kubeconfig-kind.yaml` |

📸 PRINT 5: tela de credenciais (os valores ficam ocultos).

## 7. Criar o job Multibranch + webhook

1. **New Item → Multibranch Pipeline** → nome `pipeline-blindado`.
2. Branch Source: **GitHub**, credencial `github-token`, URL do repositório.
3. Script Path: `Jenkinsfile` → Save. O Jenkins cria um job por branch.
4. No GitHub: **Settings → Webhooks** → `http://SEU-IP-OU-TUNEL:8080/github-webhook/`
   (para o GitHub alcançar sua máquina, use `ngrok http 8080` ou Cloudflare Tunnel).

📸 PRINT 6: jobs criados por branch. 📸 PRINT 7: webhook com ✔ verde.

## 8. Executar o fluxo de promoção

```bash
git checkout dev && git commit --allow-empty -m "ci: dispara pipeline" && git push origin dev
```
📸 PRINT 8: **Stage View** da branch `dev`, todos os estágios verdes.
📸 PRINT 9: console mostrando o digest `sha256:...` e o `cosign sign`.
📸 PRINT 10: pacote no GitHub Packages (GHCR).
📸 PRINT 11: `kubectl get pods -n tarefas-dev`.

Promova: `dev → homolog → pre-prod → main` (merge + push).
📸 PRINT 12: tela de **aprovação manual** na branch `main`.
📸 PRINT 13: `helm history tarefas-api -n tarefas-prod`.

## 9. Os ataques (roteiro da apresentação)

```bash
bash ataques/01-segredo-vazado.sh          # bloqueado pelo pre-commit
bash ataques/02-typosquatting.sh           # bloqueado pelo portão de dependências
bash ataques/02b-dependencia-vulneravel.sh # bloqueado pelo npm audit
bash ataques/04-codigo-inseguro.sh         # bloqueado pelo Semgrep
bash ataques/03-imagem-nao-assinada.sh     # bloqueado pelo Kyverno (precisa do cluster)
```
📸 PRINT 14: Jenkins com build **vermelho** no estágio 2, após dar push do typosquatting numa branch `ataque/typosquatting`.
📸 PRINT 15: erro do Kyverno recusando a imagem não assinada.
