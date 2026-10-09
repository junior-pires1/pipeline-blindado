#!/bin/bash
# Promove o código para o próximo ambiente: dev -> homolog -> pre-prod -> main
# Uso: bash scripts/promover.sh homolog   (ou pre-prod, ou main)
set -e
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
