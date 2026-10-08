#!/bin/bash
# Executa localmente os estágios de CI do Jenkinsfile que não dependem de Docker/Kubernetes.
# Útil para validar antes do push (e foi usado para gerar as evidências do relatório).
set -e
etapa() { echo ""; echo "=================================================================="; echo ">> ESTÁGIO $1"; echo "=================================================================="; }
INICIO=$(date +%s)

etapa "2. Portão de dependências (typosquatting)"
node scripts/verificar-dependencias.js

etapa "3. Instalar dependências (npm ci)"
npm ci --ignore-scripts --no-fund --no-audit

etapa "4. Varredura de segredos (secretlint)"
npx secretlint "**/*" && echo "Nenhum segredo encontrado."

etapa "5a. Lint (ESLint)"
npm run lint --silent && echo "ESLint: 0 problemas."

etapa "5b. Testes + cobertura (node:test)"
node --test --experimental-test-coverage --test-coverage-include="src/**" --test-reporter=spec test/*.test.js

etapa "5c. SAST (Semgrep)"
semgrep scan --config semgrep.yml --metrics=off --error src/

etapa "6. SCA (npm audit)"
npm audit --omit=dev --audit-level=high

etapa "9. SBOM (CycloneDX)"
mkdir -p relatorios
npx cyclonedx-npm --omit dev --output-file relatorios/sbom.cdx.json
node -e "const s=require('./relatorios/sbom.cdx.json');console.log('SBOM gerado: '+s.components.length+' componentes | formato '+s.bomFormat+' '+s.specVersion)"

echo ""
echo "PIPELINE LOCAL APROVADO em $(( $(date +%s) - INICIO ))s"
