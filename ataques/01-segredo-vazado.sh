#!/bin/bash
# ATAQUE 1 - Credencial comitada por engano
# Simula um desenvolvedor colando uma chave da AWS no código.
set -u
echo "=== ATAQUE 1: tentando comitar uma chave de acesso da AWS ==="
# A chave é montada em tempo de execução para que ESTE script não seja barrado pelo próprio hook
P1='q8Rz3Lk9Vb2Nm7Xc4Hj6'; P2='Tp1Wd5Fg0Sa8Ye3Ui7Ko'
cat > src/config.js <<JS
'use strict';
// "só pra testar rapidinho"...
const AWS_ACCESS_KEY_ID = 'AKIA2E0A8F3B244C9986';
const AWS_SECRET_ACCESS_KEY = '${P1}${P2}';
module.exports = { AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY };
JS
git add src/config.js
git commit -m "feat: adiciona configuracao da AWS"
RESULTADO=$?
git reset -q HEAD src/config.js; rm -f src/config.js
[ $RESULTADO -ne 0 ] && echo "=== RESULTADO: ataque BLOQUEADO pelo hook pre-commit ===" || echo "!!! commit passou"
