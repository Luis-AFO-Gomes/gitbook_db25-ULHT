/********************************************************************************
 * Aula 12														  20/11/2024 	*
 * LIG/LEI/LCD/LMC															 	*
 *																			 	*
 * Programação parte I: Introdução												*
 *	- Variáveis																	*
 *	- Blocos de código															*
 *	- Tratamento de erros														*
 ********************************************************************************/
 USE ULHT_DB25;

/****************************************************************************************************************************
 * Programação com SQL - Parte I: Variáveis																					*
 *																															*
 * (i).	Variaveis																											*
 * 		Em SQL as variaveis identificam-se pelo prefixo '@'																	*
 * 		MS-SQL:																												*
 * 			DECLARE @var AS «DATA_TYPE»																						*
 * 			SET @var = «valor» OU SELECT @var = «valor»																		*
 * 																															*
 *      NOTA: o MS-SQL é fortemente tipificado, portanto, além da declaração explicita também tem que ter indicação de tipo	*
 * 																															*
 *      Em versões mais antigas de alguma implementações, a variavel tem que ser declarada antes de uso, com atribuição em 	*
 *      instrução separada																									*
 *      ex.: 																												*
 *   		DECLARE @var AS VARCHAR(50);																					*
 *	    	SET @var = 'teste de variavel 1';																				*
 * 																															*
 *      Em versões mais modernas, a declaração e atribuição não deixam de existir mas podem ser feitas na mesma linha:	    *
 *      ex.:																												*
 * 		DECLARE @var1 AS VARCHAR(50) = 'teste de variavel 1';																*
 * 																															*
 * 		MySQL: 	A variavel é instanciada com a atribuição, assumindo automaticamente o tipo de dados do valor atribuido		*
 * 				Há 3 formas de definir o valor de uma variavel em MySQL:													*
 * 				- SET @var = «valor»																						* 
 * 				- SELECT @var := «valor» FROM (...)																			*
 * 					O MySQL desaconselha o uso desta variante uma vez que está em roadmap para ser retirada da sintaxe		*
 * 					Noutras implementações continua em uso corrente por ter a vantagem de permitir multiplas atribuições na	*
 * 					mesma instrução																							*
 * 					Ter em conta que a sintaxe da atribuição é diferente do MS-SQL: ':=' e não '='							*
 * 				- SELECT «valor» FROM (...)	INTO @var																		*
 ****************************************************************************************************************************/
-- Variante 1:
DECLARE @var_1 VARCHAR(50);
SET @var_1='teste de variavel tipo 1';
SELECT @var_1;

-- Variante 2:
DECLARE @var_2 VARCHAR(50) ='teste de variavel tipo 2';
SELECT @var_2;

-- 	Variante 3:
DECLARE @var_3 VARCHAR(50);
SELECT @var_3 ='teste de variavel tipo 3';
SELECT @var_3;
SELECT @var_3 = REPLACE(LAST_NAME, ' ', '') 
                + '.' 
                + REPLACE(FIRST_NAME, ' ', '') 
                + '@empresa.com' FROM HR.EMPLOYEES;
SELECT @var_3;

SELECT @var_1 = 'variavel 1',@var_2 = 'variavel 2';
SELECT @var_1,@var_2;
-- 		Nesta variante sintatica, o query apresenta o valor das variaveis em resultado
--		Em MySQL a atriuição é feita com ':=', em MS-SQL apenas com '='

-- Em MySQL, a instrução de atribuição pode ser utilizada juntamente com SELECT em tabela
-- Inclusivamente, atribuindo valores da tabelas a variavel
-- Ex.:
--      SELECT @var_1 = e.FIRST_NAME ,@var_2 = 'variavel 2', e.employee_id FROM hr.employees e;
--      SELECT @var_1,@var_2;

-- Noutras implementações esta possibilidade não existe, só se permite atribuição ou leitura
-- Nestas implementações, o SELECT com atribuição não produz tabela de resultados
-- O exemplo anterior irá resultar em erro em MS-SQL, devendo ser substituída por:
-- SELECT @var_1 = e.FIRST_NAME ,@var_2 = 'variavel 2' FROM employees e;
-- SELECT @var_1, @var_2, employee_id FROM employees e;

-- 	Eliminar variaveis
-- 	Para o caso de ser necessário limpar um variavel, deve-se atribuir-lhe o valor NULL
DECLARE @var VARCHAR(50) = 'teste de variavel';
SELECT @var;

SET @var = NULL;
SELECT @var;
--	À excepção de casos muito especificos, o SQL não permite que um variavel seja apagada

/****************************************************************************************************************************
 * VARIÁVEIS DO TIPO TABELA                                                                                                 *
 ****************************************************************************************************************************
 * Em MS-SQL, é possível utilizar variáveis do tipo tabela:                                                                 */
DECLARE @tbl_mail TABLE
(
     employee_id    NUMERIC(6)
    ,first_name     VARCHAR(20)
    ,last_name      VARCHAR(25)
    ,email          VARCHAR(255)
);

INSERT INTO @tbl_mail 
    SELECT EMPLOYEE_ID,
           FIRST_NAME,
           LAST_NAME,
           REPLACE(LAST_NAME, ' ', '') 
                + '.' 
                + REPLACE(FIRST_NAME, ' ', '') 
                + '@empresa.com' AS EMAIL
    FROM HR.EMPLOYEES;

SELECT * FROM @tbl_mail;    

/* As variáveis de tabela criam tabelas temporárias a utilizar em calculos intermédios, com o mesmo comportamento das       *
 * tabelas temporárias (v. mais à frente) e funções semelhantes a tabelas produzidas por CTE ou subqueries.                 *
 * Ao contrário de CTE e subqueries, as variáveis de tabela podem ter elementos estruturais das tabelas 'normais' - e.g.    *
 * chaves, constraints, etc. - com excepção de índices (além do associado à PK) e chaves estrangeiras, e podem ser          *
 * reutilizadas em várias instruções dentro do mesmo bloco de código.                                                       *
 * No entanto, têm um âmbito de utilização muito reduzido, existindo apenas dentro do bloco de código onde foram declaradas.*
 ****************************************************************************************************************************/

/****************************************************************************************************************************
 * TABELAS TEMPORÁRIAS                                                                                                      *
 ****************************************************************************************************************************
 * Além de variáveis do tipo tabela, o MS-SQL também permite criar tabelas temporárias com a instrução CREATE TABLE         *
 * As tabelas temporárias têm prefixo '#' e são criadas na base de dados tempdb                                             *
 * Por defeito, as tabelas temporárias são visíveis apenas na sessão que as criou, podendo ser utilizadas em qualquer       *
 * instrução da sessão enquanto esta se mantiver activa. Elas são eliminadas automaticamente quando a sessão é encerrada    *
 * No entanto, podem ser criadas tabelas temporárias globais (prefixadas com ##) que são visíveis para todas as sessões     *
 * e só são eliminadas quando a última sessão que as está a utilizar é encerrada.                                           *
 * As tabelas temporárias podem ter índices, chaves estrangeiras e constraints.                                             */
CREATE TABLE #tbl_mail
(
     employee_id    NUMERIC(6)
    ,first_name     VARCHAR(20)
    ,last_name      VARCHAR(25)
    ,email          VARCHAR(255)
);

INSERT INTO #tbl_mail 
    SELECT EMPLOYEE_ID,
           FIRST_NAME,
           LAST_NAME,
           REPLACE(LAST_NAME, ' ', '') 
                + '.' 
                + REPLACE(FIRST_NAME, ' ', '') 
                + '@empresa.com' AS EMAIL
    FROM HR.EMPLOYEES;

SELECT * FROM #tbl_mail; 

DROP TABLE #tbl_mail;
/****************************************************************************************************************************
 * Tabelas temporárias vs Variáveis de tabela                                                                               *
 ****************************************************************************************************************************
 * Âmbito:                                                                                                                  *  
 *      Variáveis de tabela:  limitado ao bloco de código onde são declaradas                                               *
 *      Tabelas temporárias:  partilhadas entre sessões (tabelas temporárias globais, prefixadas com ##)                    *
 *                            exclusivas da sessão que as criou (tabelas temporárias locais, prefixadas com #).             *
 * Performance:                                                                                                             *
 *      Variáveis de tabela:  criadas em memória, o que pode melhorar o desempenho em certos cenários.                      *
 *      Tabelas temporárias:  criadas no disco, na base de dados tempdb.                                                    *
 * Estrutura:                                                                                                               *
 *      Variáveis de tabela:  não podem ter índices (além do associado à PK) nem chaves estrangeiras.                       *
 *      Tabelas temporárias:  podem ter índices, chaves estrangeiras e constraints.                                         *
 * Uso:                                                                                                                     *
 *      Variáveis de tabela:  identico a subqueriesadequadas para conjuntos de dados pequenos a médios e operações simples. *
 *      Tabelas temporárias:  maior persistência, mais adequadas para conjuntos de dados maiores e operações complexas.     *
 ****************************************************************************************************************************/

/****************************************************************************************************************************
 * (ii). Blocos																												*
 * Em SQL os blocos de código são delimitados por BEGIN ... END																*
 *																															*
 * Em MS-SQL, como já vimos antes, podem-se utilizar blocos BEGIN ... END em query corrido									*
 * No entanto, por funcionamento interno ao DBEngine, nem todos os erros são 'apanhados' pelo CATCH e há diferenlas entre	*
 * os que são detectados em query aberto e os que o são em módulos programados. 											*
 * Ex.: chamadas a tabelas inexistentes ou falhas em INSERT são detectados em módulos, mas não em query corrido				*
 * 																															*
 * Por razões que se verão em aulas posteriores, o MySQL requer que blocos apenas funcionem dentro de módulos programados	*
 * Esta caracteristicas são especificas do MySQL e resultam, principalmente, da forma de delimitação de instruções			*
 ****************************************************************************************************************************/
-- Exemplo de bloco em MS-SQL
select IIF(@@OPTIONS & 2 = 0, 'OFF', 'ON');
SET IMPLICIT_TRANSACTIONS OFF; 

-- Blocos de código com error handling...:
-- (fica o exemplo, mas voltaremos ao error handling mais tarde com maior detalhe)
PRINT @@TRANCOUNT;
BEGIN TRY
	BEGIN TRANSACTION
	    INSERT INTO scott.dept
	        VALUES(50,'IT','LISBOA')
	                
        SELECT * FROM scott.dept
	               
        INSERT INTO scott.emp
            VALUES(1,'Gomes','QQ',NULL,'2021-12-07',0,NULL,60)

        PRINT @@TRANCOUNT
	      
	IF @@TRANCOUNT > 0
        COMMIT              -- Pode-se utilizar XACT_STATE() = 1 em vez de @@TRANCOUNT > 0
                            -- XACT_STATE é mais seguro e fiável
                            -- COMMIT decrementa o valor de @@TRANCOUNT, mas apenas para as transacções que
                            -- foram iniciadas na sessão atual (efectuadas após o BEGIN TRANSACTION do bloco TRY)
                            -- pode gerar confusão se houver transacções encadeadas ou iniciadas em triggers
    SELECT 'sucesso!'
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0      -- Pode-se utilizar XACT_STATE() <> 0 em vez de @@TRANCOUNT > 0
		ROLLBACK
	
	SELECT 'erro!'
END CATCH; 

SELECT * FROM scott.dept;
SELECT * FROM scott.emp;

BEGIN TRANSACTION

    DELETE FROM scott.emp WHERE empno=1;
    DELETE FROM scott.dept WHERE deptno>=50;

COMMIT
