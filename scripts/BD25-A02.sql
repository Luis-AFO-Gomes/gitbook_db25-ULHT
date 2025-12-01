/*****************************************************************************
 * Aula 03														  25/09/2024 *
 * LIG/LEI/LCD/LMC															 *
 *																			 *
 * DML: INSERT; UPDATE; DELETE												 *
 *		SELECT SIMPLES														 *
 *****************************************************************************/
 
 -- cometários:
-- 1. linha: '--' todas a linha após o simbolo é comentada
-- 2. intervalo: '/* */' todo o código entre '/*' e '*/' não é interpretado
 

-- Introdução ao SELECT
-- A base elementar da pesquisa:
-- SELECT * FROM «tabela»;
-- ex.:
SELECT * FROM ULHT_DB25.Scott.EMP
	WHERE sal < 1000;
-- Onde '*' é um wildcard, significa "Todas as colunas"

-- para simplificar, podem fixar a BD de trabalho: USE
USE ULHT_DB25;
GO

SELECT * FROM Scott.EMP
  WHERE sal < 1000;

SELECT * FROM BikeStores.sales.customers c
 WHERE c.city = 'Lisbon';  

-- Sintaxe base, v.1
-- SELECT «colunas»|* FROM «tabela»
-- Onde:
-- «colunas» ::= «coluna»|«coluna»,«colunas»
 
 -- Mais elementos para a Sintaxe SELECT: filtros -> WHERE; ALIASING
-- 
-- WHERE define uma qualquer expressão lógica sobre a estrutura das relações consultadas, realizada por linha
--		Mais à frente veremos filtros de grupo e a possibilidade de utilizar expressões e funções em filtros
-- 
-- ALIAS: alias é uma forma de simplificar a identificação de um objecto de modo a facilitar a escrita de código
--		Só funciona em SELECT
-- Sintaxe base, v.2
-- SELECT «colunas»|* 
--		FROM «tabela» «alias»
-- 		WHERE «condição»;
-- Onde:
-- «alias» ::= [AS] «identificador»
-- «colunas» ::= «coluna» [«alias»]|«coluna» [«alias»],«colunas»
-- «condição» ::= qualquer operação lógica sobre colunas da tabela
 
-- Ex.: SELECT FROM INFORMATION_SCHEMA Para identificação de colunas da tabela [EMP]
USE ULHT_DB25;
GO
-- Inserir linhas numa tabela: INSERT 
-- Sintaxe base
-- INSERT INTO «tabela» [(«lista_de_colunas»)]
-- 		VALUES («lista_de_valores»);
-- 
-- ONDE:
-- «lista_de_colunas» ::= «coluna»|«coluna»,«lista_de_colunas»
-- «lista_de_valores» ::= «valor»|«valor»,«lista_de_valores»
-- 		valores alfabéticos são delimitados por ''
-- 
-- NOTAS: #«lista_de_colunas» == #«lista_de_valores»
-- 		se acontagem for diferente, o SQL apresentará erro
-- 		A inserção é feita mapeando valroes para colunas pela ordem indicada
-- 		A ordem não tem que ser a que aparece na estrutura da tabela, mas
-- 		Tem que haver correspondência entre tipos de dados das colunas e dos valores
-- 		Sempre que se pretenda que uma coluna não seja preenchida, utiliza-se NULL
 
 -- Ex.: Inserir-se em [EMP]
  -- Antes da inserção, como saber os atributos da relação para fazer a inserção: INFORMATION_SCHEMA
INSERT INTO Scott.EMP (empno, ename, job, mgr, hiredate, sal, comm, deptno)
  VALUES (2703, 'Luis Gomes', NULL, NULL,GETDATE(), 1000, NULL, NULL);
  
-- Verificar a inserção com SELECT
SELECT * FROM Scott.EMP
 WHERE empno = 2703;

-- Atributos não obrigatórios: Nulidade -> NULL em INSERT
 
 
-- Alterar linhas numa tabela: UPDATE
-- Sintaxe base
-- UPDATE «tabela»
-- 		SET «atribuições»
-- 		[WHERE «condição»]
-- Onde:
-- 	«atribuições» ::= «atribuição»|«atribuição»,«atribuições»
-- 	«atribuição» ::= «coluna» = «valor»
-- 		Tem que haver correspondência entre tipos de dados das colunas e dos valores
--  	«condição» é facultativa, se não utilizada «atribuição» é aplicada a todas as linhas
 
 -- Ex.: Alterar função e vencimento
 UPDATE Scott.EMP
  SET SAL = 1500
  WHERE empno = 2703;
 
-- Verificar a inserção com SELECT
SELECT * FROM Scott.EMP
 WHERE empno = 2703;

-- Atributos não obrigatórios: Nulidade -> NULL em UPDATE
 
 -- Apagar linhas da tabela
 
 -- Sintaxe DELETE
-- DELETE FROM «tabela»
-- 		[WHERE «condição»]

-- MUITO IMPORTANTE:
-- As instruções de SQL são irreversiveis, qualquer linha apagada só pode ser reposta por INSERT
-- Embora a condição seja facultativa, é preciso ter muito cuidado para não a utilizar 
-- uma vez que todos os dados da tabela serão apagados definitivamente
 
 -- Ex.: Apagar linhas inseridas
  DELETE FROM Scott.EMP
    WHERE empno = 2703;
 
-- Verificar a inserção com SELECT
SELECT * FROM Scott.EMP
 WHERE empno = 2703;
