'use strict';

const express = require('express');

const VERSION = process.env.APP_VERSION || '1.0.0';

function criarApp() {
  const app = express();
  app.use(express.json({ limit: '10kb' }));
  app.disable('x-powered-by');

  // Armazenamento em memória (suficiente para o escopo do trabalho)
  const tarefas = [];
  let proximoId = 1;

  // Usado pelo Kubernetes (readiness/liveness) e pelo smoke test do pipeline
  app.get('/health', (req, res) => {
    res.json({ status: 'ok', versao: VERSION });
  });

  app.get('/api/tarefas', (req, res) => {
    res.json(tarefas);
  });

  app.post('/api/tarefas', (req, res) => {
    const { titulo } = req.body || {};
    if (typeof titulo !== 'string' || titulo.trim().length < 3) {
      return res.status(400).json({ erro: 'titulo deve ter ao menos 3 caracteres' });
    }
    const tarefa = { id: proximoId++, titulo: titulo.trim(), concluida: false };
    tarefas.push(tarefa);
    return res.status(201).json(tarefa);
  });

  app.patch('/api/tarefas/:id/concluir', (req, res) => {
    const tarefa = tarefas.find((t) => t.id === Number(req.params.id));
    if (!tarefa) {
      return res.status(404).json({ erro: 'tarefa nao encontrada' });
    }
    tarefa.concluida = true;
    return res.json(tarefa);
  });

  return app;
}

module.exports = { criarApp };
