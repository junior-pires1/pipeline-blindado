#!/bin/bash
# Promove o código para o próximo ambiente: dev -> homolog -> pre-prod -> main
# Uso: bash scripts/promover.sh homolog   (ou pre-prod, ou main)
set -e
# Executa a partir de uma cópia temporária: ao trocar de branch o arquivo
# original pode sumir do disco (no Windows isso travaria o checkout).
if [ -z "$PROMOVER_COPIA" ]; then
  TMP="${TMPDIR:-/tmp}/promover-$$.sh"; cp "$0" "$TMP"
  PROMOVER_COPIA=1 exec bash "$TMP" "$@"
fi
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "Há alterações não salvas. Rode 'git status' e faça commit antes de promover."; exit 1
fi
case "$1" in
  homolog)  ORIGEM=dev ;;
  pre-prod) ORIGEM=homolog ;;
  main)     ORIGEM=pre-prod ;;
  *) echo "Uso: bash scripts/promover.sh [homolog|pre-prod|main]"; exit 1 ;;
esac
DESTINO="$1"
git checkout -q "$DESTINO"
git merge --no-ff "$ORIGEM" -m "merge: promove $ORIGEM para $DESTINO"
git push origin "$DESTINO"
git checkout -q dev
echo "=== $ORIGEM promovido para $DESTINO. Acompanhe na aba Actions do GitHub. ==="
