#!/bin/bash
# ATAQUE BÔNUS - Código vulnerável a injeção (eval com dados da requisição)
set -u
echo "=== ATAQUE BÔNUS: adicionando rota /api/calcular que usa eval() ==="
cp src/app.js /tmp/app.js.bak
node -e "const f='src/app.js',fs=require('fs');let s=fs.readFileSync(f,'utf8');s=s.replace('  return app;\\n}', \"  app.get('/api/calcular', (req, res) => {\\n    res.json({ resultado: eval(req.query.expr) });\\n  });\\n\\n  return app;\\n}\");fs.writeFileSync(f,s)"
grep -n "eval" src/app.js
semgrep scan --config semgrep.yml --metrics=off --error --quiet src/
RESULTADO=$?
cp /tmp/app.js.bak src/app.js
[ $RESULTADO -ne 0 ] && echo "=== RESULTADO: código BLOQUEADO pelo SAST (Semgrep) ===" || echo "!!! passou"
