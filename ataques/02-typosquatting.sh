#!/bin/bash
# ATAQUE 2 - Dependência maliciosa com nome parecido (typosquatting)
# Simula um "npm install expres" (sem o segundo s). O pacote NÃO é instalado:
# o portão lê o package.json antes do npm ci.
set -u
echo "=== ATAQUE 2: adicionando a dependência 'expres' ao package.json ==="
cp package.json /tmp/package.json.bak
node -e "const f='package.json',p=require('./'+f);p.dependencies.expres='^1.0.0';require('fs').writeFileSync(f,JSON.stringify(p,null,2))"
grep -n '"expres"' package.json
node scripts/verificar-dependencias.js
RESULTADO=$?
cp /tmp/package.json.bak package.json
[ $RESULTADO -ne 0 ] && echo "=== RESULTADO: ataque BLOQUEADO pelo portão de dependências ===" || echo "!!! dependência passou"
