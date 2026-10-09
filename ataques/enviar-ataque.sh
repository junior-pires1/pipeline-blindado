#!/bin/bash
# Envia um ataque controlado para uma branch "ataque/<nome>" no GitHub.
# O GitHub Actions roda os portões de segurança e deve ficar VERMELHO.
#
# Uso:  bash ataques/enviar-ataque.sh segredo
#       bash ataques/enviar-ataque.sh typosquatting
#       bash ataques/enviar-ataque.sh eval
set -e
ATAQUE="$1"
case "$ATAQUE" in segredo|typosquatting|eval) ;; *)
  echo "Uso: bash ataques/enviar-ataque.sh [segredo|typosquatting|eval]"; exit 1;; esac

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Você tem alterações não salvas. Faça commit delas antes de enviar um ataque."; exit 1
fi

ORIGEM=$(git branch --show-current)
BRANCH="ataque/$ATAQUE"
echo "=== Criando a branch $BRANCH a partir da main ==="
git checkout -q -B "$BRANCH" main

case "$ATAQUE" in
  segredo)
    # chave montada em tempo de execução para este script não ser barrado
    P1='q8Rz3Lk9Vb2Nm7Xc4Hj6'; P2='Tp1Wd5Fg0Sa8Ye3Ui7Ko'
    printf "'use strict';\n// \"só pra testar rapidinho\"...\nconst AWS_ACCESS_KEY_ID = 'AKIA2E0A8F3B244C9986';\nconst AWS_SECRET_ACCESS_KEY = '%s%s';\nmodule.exports = { AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY };\n" "$P1" "$P2" > src/config.js
    ;;
  typosquatting)
    node -e "const f='package.json',p=require('./'+f);p.dependencies.expres='^1.0.0';require('fs').writeFileSync(f,JSON.stringify(p,null,2)+'\n')"
    ;;
  eval)
    node -e "const f='src/app.js',fs=require('fs');let s=fs.readFileSync(f,'utf8');s=s.replace('  return app;\n}', \"  app.get('/api/calcular', (req, res) => {\n    res.json({ resultado: eval(req.query.expr) });\n  });\n\n  return app;\n}\");fs.writeFileSync(f,s)"
    ;;
esac

git add -A
# --no-verify simula um desenvolvedor que desativou o hook local:
# a defesa agora precisa vir do pipeline no GitHub.
git commit -q --no-verify -m "ataque: $ATAQUE (demonstração controlada)"
git push -f -u origin "$BRANCH"
git checkout -q "$ORIGEM"

echo ""
echo "=== Ataque '$ATAQUE' enviado para $BRANCH ==="
echo "Abra a aba Actions do repositório no GitHub: o pipeline dessa branch deve ficar VERMELHO."
