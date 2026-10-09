#!/bin/bash
# ATAQUE 2b - Dependência legítima, mas com vulnerabilidade CRÍTICA conhecida
# lodash 4.17.11 tem CVE de prototype pollution (CVE-2019-10744).
set -u
DIR=$(mktemp -d)
echo "=== ATAQUE 2b: projeto usando lodash@4.17.11 (versão vulnerável) ==="
cd "$DIR" && npm init -y >/dev/null && npm install lodash@4.17.11 --no-fund --no-audit >/dev/null 2>&1
npm audit --audit-level=high
RESULTADO=$?
[ $RESULTADO -ne 0 ] && echo "=== RESULTADO: build REPROVADO pelo npm audit (SCA) ===" || echo "!!! passou"
