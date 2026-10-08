#!/bin/bash
# ATAQUE 3 - Imagem construída fora do pipeline (sem assinatura)
# Requer: cluster kind com Kyverno + política k8s/kyverno-somente-imagens-assinadas.yaml
set -u
IMAGE=ghcr.io/SEU-USUARIO-GITHUB/tarefas-api
echo "=== ATAQUE 3: build e push manual, pulando o Jenkins ==="
docker build -t $IMAGE:hack .
docker push $IMAGE:hack
echo "=== Tentando implantar a imagem não assinada no namespace de produção ==="
kubectl -n tarefas-prod run invasor --image=$IMAGE:hack --restart=Never
[ $? -ne 0 ] && echo "=== RESULTADO: ataque BLOQUEADO pelo Kyverno (assinatura ausente) ===" || echo "!!! pod criado"
