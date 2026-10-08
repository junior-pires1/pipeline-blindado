'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const { criarApp } = require('../src/app');

test('GET /health responde ok', async () => {
  const res = await request(criarApp()).get('/health');
  assert.equal(res.status, 200);
  assert.equal(res.body.status, 'ok');
});

test('POST /api/tarefas cria uma tarefa', async () => {
  const res = await request(criarApp()).post('/api/tarefas').send({ titulo: 'Configurar Jenkins' });
  assert.equal(res.status, 201);
  assert.equal(res.body.titulo, 'Configurar Jenkins');
  assert.equal(res.body.concluida, false);
});

test('POST /api/tarefas rejeita titulo invalido', async () => {
  const res = await request(criarApp()).post('/api/tarefas').send({ titulo: 'a' });
  assert.equal(res.status, 400);
});

test('GET /api/tarefas lista as tarefas criadas', async () => {
  const app = criarApp();
  await request(app).post('/api/tarefas').send({ titulo: 'Escrever testes' });
  const res = await request(app).get('/api/tarefas');
  assert.equal(res.body.length, 1);
});

test('PATCH /api/tarefas/:id/concluir conclui a tarefa', async () => {
  const app = criarApp();
  await request(app).post('/api/tarefas').send({ titulo: 'Assinar imagem' });
  const res = await request(app).patch('/api/tarefas/1/concluir');
  assert.equal(res.status, 200);
  assert.equal(res.body.concluida, true);
});

test('PATCH em tarefa inexistente retorna 404', async () => {
  const res = await request(criarApp()).patch('/api/tarefas/99/concluir');
  assert.equal(res.status, 404);
});

test('cabecalho x-powered-by nao e exposto', async () => {
  const res = await request(criarApp()).get('/health');
  assert.equal(res.headers['x-powered-by'], undefined);
});
