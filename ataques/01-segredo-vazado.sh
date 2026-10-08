#!/bin/bash
# ATAQUE 1 - Credencial comitada por engano
# Simula um desenvolvedor colando uma chave da AWS no código.
set -u
echo "=== ATAQUE 1: tentando comitar uma chave de acesso da AWS ==="
cat > src/config.js <<'JS'
'use strict';
// "só pra testar rapidinho"...
module.exports = {
  awsAccessKeyId: 'AKIA2E0A8F3B244C9986',
  awsSecretAccessKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY8',
};
JS
git add src/config.js
git commit -m "feat: adiciona configuracao da AWS"
RESULTADO=$?
git reset -q HEAD src/config.js; rm -f src/config.js
[ $RESULTADO -ne 0 ] && echo "=== RESULTADO: ataque BLOQUEADO pelo hook pre-commit ===" || echo "!!! commit passou"
