# BD25 – Introdução a Bases de Dados e SQL

Este “livro” reúne os tutoriais e exemplos do módulo **BD25**, organizados em formato de GitBook para apoio a aulas e estudo autónomo.

O foco está em:

- Fundamentos de **SQL** (consulta e manipulação de dados – DML)
- Definição e qualidade dos dados (DDL, constraints, chaves, integridade)
- Operadores relacionais (JOIN, subqueries, CTE)
- Transações, concorrência e isolamento
- Programação em SQL (variáveis, blocos, condicionais, ciclos, SPs, funções, triggers)

Os exemplos estão pensados principalmente para **MS-SQL Server** e **MySQL/MariaDB**, sempre que possível com notas de diferenças entre SGBD.

---

## Público-alvo

- Estudantes em unidades curriculares de **Bases de Dados** (nível inicial/intermédio)
- Pessoas que já sabem `SELECT` básico e querem:
  - ganhar rigor (GROUP BY, joins, subqueries),
  - perceber como funciona **isolamento de transações**,
  - dar os primeiros passos em **programação T-SQL / PL-SQL-like**.

---

## Organização do conteúdo

Os capítulos seguem aproximadamente a sequência das aulas práticas:

1. Fundamentos de SQL e DML básica  
2. Operações linha-a-linha: funções de texto, datas e números  
3. Filtros com `WHERE`  
4. Funções de grupo e agregação  
5. Criação de tabelas e tipos de dados  
6. Views, índices e constraints  
7. Relações e chaves estrangeiras  
8. Junções (`JOIN`)  
9. Subqueries e CTE  
10. Transações e isolamento (teoria)  
11. Cenários práticos de isolamento  
12. Variáveis e blocos de código  
13. Condicionais, ciclos e cursores  
14. Stored procedures e funções  
15. Tratamento de erros com `TRY…CATCH`  
16. Triggers

---

## Como usar

- Cada capítulo está num ficheiro `.md` com numeração `01-…`, `02-…`, etc.
- Os scripts SQL originais (`BD25-A02.sql`, `BD25-A03.sql`, …) podem ser usados em paralelo:
  - para execução em aula,
  - para retirar mais exemplos,
  - ou para criar fichas de exercícios.

Sugestão de uso em aula:

1. Apresentar os **conceitos chave** do capítulo.
2. Executar e comentar alguns **exemplos de código**.
3. Propor **exercícios** guiados ou autónomos.
4. Reforçar os pontos onde há diferenças entre SGBD (MySQL vs MS-SQL).

---

## Pré-requisitos

- Noções básicas de:
  - o que é uma **base de dados**,
  - o que é uma **tabela**, **linha** (registo) e **coluna** (campo),
  - o conceito de **chave primária**.

- Acesso a um SGBD (pelo menos um):
  - **MS-SQL Server** (por exemplo via Docker, ou Developer Edition),
  - **MySQL/MariaDB**.

---
