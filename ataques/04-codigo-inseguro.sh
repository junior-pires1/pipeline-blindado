#!/bin/bash
# ATAQUE BÔNUS - Código vulnerável a injeção (eval com dados da requisição)
set -u
echo "=== ATAQUE BÔNUS: adicionando rota /api/calcular que usa eval() ==="
cp src/app.js /tmp/app.js.bak
python3 - <<'PY'
p='src/app.js'; s=open(p).read()
s=s.replace("  return app;\n}", "  app.get('/api/calcular', (req, res) => {\n    res.json({ resultado: eval(req.query.expr) });\n  });\n\n  return app;\n}")
open(p,'w').write(s)
PY
grep -n "eval" src/app.js
semgrep scan --config semgrep.yml --metrics=off --error --quiet src/
RESULTADO=$?
cp /tmp/app.js.bak src/app.js
[ $RESULTADO -ne 0 ] && echo "=== RESULTADO: código BLOQUEADO pelo SAST (Semgrep) ===" || echo "!!! passou"
