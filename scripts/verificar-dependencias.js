#!/usr/bin/env node
'use strict';

/*
 * Portão de cadeia de suprimentos (supply chain gate).
 * Lê o package.json ANTES do `npm ci` e reprova o pipeline se:
 *   1) houver dependência fora da lista aprovada (allowlist); ou
 *   2) o nome for parecido com um pacote popular (possível typosquatting).
 * Rodar antes da instalação é essencial: um pacote malicioso pode executar
 * código já no `postinstall`.
 */

const fs = require('node:fs');
const path = require('node:path');

const raiz = path.join(__dirname, '..');
const pkg = JSON.parse(fs.readFileSync(path.join(raiz, 'package.json'), 'utf8'));
const permitidas = JSON.parse(fs.readFileSync(path.join(__dirname, 'dependencias-aprovadas.json'), 'utf8'));

// Pacotes muito baixados: alvos preferidos de typosquatting
const POPULARES = ['express', 'lodash', 'react', 'axios', 'request', 'chalk', 'commander',
  'moment', 'debug', 'dotenv', 'jsonwebtoken', 'mongoose', 'eslint', 'supertest', 'cross-env'];

function distancia(a, b) {
  const m = Array.from({ length: a.length + 1 }, (_, i) => [i]);
  for (let j = 1; j <= b.length; j++) m[0][j] = j;
  for (let i = 1; i <= a.length; i++) {
    for (let j = 1; j <= b.length; j++) {
      const custo = a[i - 1] === b[j - 1] ? 0 : 1;
      m[i][j] = Math.min(m[i - 1][j] + 1, m[i][j - 1] + 1, m[i - 1][j - 1] + custo);
    }
  }
  return m[a.length][b.length];
}

const todas = { ...pkg.dependencies, ...pkg.devDependencies };
let falhas = 0;

console.log(`Verificando ${Object.keys(todas).length} dependências declaradas em package.json...`);
for (const nome of Object.keys(todas)) {
  if (permitidas.includes(nome)) {
    console.log(`  [OK]       ${nome}`);
    continue;
  }
  falhas++;
  const parecido = POPULARES.concat(permitidas)
    .find((p) => p !== nome && distancia(p, nome) <= 2);
  if (parecido) {
    console.log(`  [BLOQUEIO] ${nome} -> possível TYPOSQUATTING de "${parecido}" (distância ${distancia(parecido, nome)})`);
  } else {
    console.log(`  [BLOQUEIO] ${nome} -> dependência não aprovada (adicione em scripts/dependencias-aprovadas.json via PR revisado)`);
  }
}

if (falhas > 0) {
  console.error(`\nFALHA: ${falhas} dependência(s) bloqueada(s). Pipeline interrompido antes do npm ci.`);
  process.exit(1);
}
console.log('\nSUCESSO: todas as dependências estão na lista aprovada.');
