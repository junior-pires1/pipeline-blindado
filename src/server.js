'use strict';

const { criarApp } = require('./app');

const PORT = Number(process.env.PORT) || 3000;

criarApp().listen(PORT, () => {
  console.log(`tarefas-api ouvindo na porta ${PORT}`);
});
