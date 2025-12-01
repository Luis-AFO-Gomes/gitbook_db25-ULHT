/********************************************************************************
 * Aula 07														  30/10/2024 	*
 * LIG/LEI/LCD/LMC															 	*
 *																			 	*
 * DDL: Definição de estrutura:						 							*
 *		CREATE [continuação]													*
 *		- VIEW																	*
 *		- INDEX																	*
 *		Restrições																*
 *		- Qualidade de dados: UNIQUE; CHECK; NN									*
 ********************************************************************************/
 use ULHT_DB25;

 DECLARE @len INT = (SELECT c.CHARACTER_MAXIMUM_LENGTH 
				FROM INFORMATION_SCHEMA.COLUMNS c 
				WHERE c.TABLE_NAME = 'employees' AND c.COLUMN_NAME = 'email');

-- Preparar dados para realização de exercícios (pode ser necessário várias vezes...)
IF EXISTS (SELECT 1 FROM sys.check_constraints cc
				WHERE parent_object_id = object_id('hr.employees','U') AND
					cc.name = 'ch_email_nbsp')
	ALTER TABLE hr.EMPLOYEES
		DROP CONSTRAINT ch_email_nbsp;

DELETE FROM hr.employees WHERE employee_id >= 1000;

UPDATE hr.employees 
	SET email = CONCAT(LAST_NAME,'.',FIRST_NAME);

SELECT * FROM hr.employees e;
-- CONSTRAINTS
-- Unicidade
-- PK
-- garante o principio da unicidade do modelo relacional

-- UK
-- implementa o conceito de AK, que também garante a unicidade mas com menos restrições que PK
-- aplica conceito de CHAVE ALTERNATIVA

-- CH
-- Integridade, qualidade e referência
-- implementa regras de integridade e qualidade de dados
-- Caso 1: Aplicação de regras de negócio para qualidade de dados
--		  ex.: mail não pode conter espaços
ALTER TABLE hr.employees 
	ADD CONSTRAINT ch_email_nbsp CHECK (EMAIL NOT LIKE '% %'); -- erro: ???
	
-- Em tabelas com dados, fazer query com filtro a aplicar na CONSTRAINT	
SELECT count(*) FROM hr.employees e WHERE NOT(e.EMAIL NOT LIKE '% %');
-- O query identifica as linhas que não cumprem a restrição a inserir
-- Esta linhas são as que se pretende que NÃO existam

-- retirar espaços (ex.: REPLACE() 2 Aula 4)
UPDATE hr.EMPLOYEES 
	SET email =UPPER(REPLACE(EMAIL,' ',''))
	WHERE EMAIL LIKE '% %';
	
ALTER TABLE hr.employees 
	ADD CONSTRAINT ch_email_nbsp CHECK (EMAIL NOT LIKE '% %');
-- A condição de CHECK tem que ser cumprida pelos dados existentes e pelo novos

-- repor original
UPDATE hr.EMPLOYEES 
	SET email = 'LDE HAAN'
	WHERE EMPLOYEE_ID  = 102; -- > ERRO: violação ch_email_nbsp!

DELETE FROM HR.EMPLOYEES WHERE EMAIL LIKE '% %';
-- O mais correcto é realizar REPLACE com REGEX, substituindo espaços por uma caracter válido - '_' - ou removendo o espaço

INSERT INTO HR.EMPLOYEES 
	VALUES (1000,'Steve','King','S KING','515.123.4567','2003.06.17','AD_PRES',24000,NULL,NULL,90);

-- eliminar CONSTRAINT
ALTER TABLE hr.employees 
	DROP CONSTRAINT ch_email_nbsp;
-- Mais abaixo, forma de inactivar sem apagar a CONSTRAINT

-- Caso 2: Uso de funções para validação de regra de negócio
-- 		ex.: data de admissão não pode ser poserior ao dia de hoje
-- 			 Obter data do sistema: SYSDATE() --> GETDATE() em MS-SQL
SELECT CAST(SYSDATETIME() AS TIME);

SELECT * FROM HR.EMPLOYEES e WHERE e.HIRE_DATE >= CAST(SYSDATETIME() AS DATE);

ALTER TABLE employees 
	ADD CONSTRAINT ch_hire_date CHECK (HIRE_DATE < CAST(SYSDATETIME() AS DATE));

-- Caso 3: Comparação entre colunas 
-- 		ex.: na tabela JOB_HISTORY, garantir que data de saída é posterior à de entrada (END_DATE >= START DATE)
SELECT * FROM hr.JOB_HISTORY jh;

SELECT * FROM HR.JOBS j;

ALTER TABLE job_history 
	ADD CONSTRAINT ch_jh_dates CHECK (END_DATE >= START_DATE);

-- Caso 4: CH como definição de tipos ENUM
SELECT * FROM HR.REGIONS;

ALTER TABLE HR.REGIONS ADD
	continent	VARCHAR(12)	DEFAULT NULL
	,CONSTRAINT ch_continent CHECK (continent IN ('europe','asia','africa','oceania','america'))
;
GO
-- A indicação do DEFAULT não é absolutamente necessária, o parâmetro de nulidade fará o preenchimento
-- Utiliza-se apenas para garantia de coerência e qualidade dos dados
-- Os NULL são sempre aceites, os NOT NULL terão que estar nos valores enumerados
	
UPDATE HR.REGIONS 
	SET continent = 'africa'
	WHERE REGION_ID = 4;

SELECT * FROM HR.REGIONS WHERE REGION_ID = 4;

ALTER TABLE HR.regions DROP COLUMN continent; --> Existe um problema de dependências/restrições
-- É necessário começar por eliminar estas dependências...
ALTER TABLE HR.REGIONS DROP
	 CONSTRAINT DF__REGIONS__contine__6E01572D
	,CONSTRAINT ch_continent;
-- Notas	
-- 	1.	O exemplo serve para verificar a eliminação de multiplas CONSTRAINT numa única instrução
--	2.	A CONSTRAINT DEFAULT foi definida em linha, de onde resulta o nome aleatório
--		Será necessário recorrer ao exemplo da aula anterior para identificar o nome (embora o erro também o indique...)
--		O mais adequado será especificar o DEFAULT como CONSTRAINT no ALTER, passando este a ter a seguinte sintaxe
--			ALTER TABLE HR.REGIONS ADD
--				continent	VARCHAR(12)	
--				,CONSTRAINT df_continent DEFAULT NULL FOR continent
--				,CONSTRAINT ch_continent CHECK (continent IN ('europe','asia','africa','oceania','america'))
--			;
-- Agora, já se pode eliminar a coluna!

-- Caso 5: Tratamento de nulidade como CH
--		Nas versões actuais de SGBD, a NULIDADE é tratada com CHECK CONSTRAINT
-- ex.: email
ALTER TABLE HR.employees ADD
	CONSTRAINT nn_email CHECK (email IS NOT NULL);

-- Exercicios com (des)activaçãoo de CONSTRAINT e INDEX
DELETE FROM HR.EMPLOYEES WHERE EMPLOYEE_ID >= 1001;

-- ENABLE/DISABLE CONSTRAINTS
-- O SQL permite (des)activar CONSTRAINTS de todos os tipos, embora com sintaxes diferentes
-- Nas CONSTRAINTS que utilizam indices - PRIMARY KEYS, UNIQUE e FOREIGN KEYS - a acção é realizada sobre indices (v. mais abaixo)
-- Apenas as CONSTRAINT de tipo CHECK têm acção directa para (des)activar
-- A (des)activação de CONSTRAINT não altera a sua especificação

-- NOTA PRÉVIA:
-- É necessário ter muito cuidado com estas acções pois podem introduzir problemas graves de incoerência no dados
-- Deve-se evitar o uso em estruturas de produção, limitando-o a ambitos de preparação ou tranformação de dados (e.g. ETL)

-- verificar estado da verificação de CONSTRAINTS
-- Todas as CHECK CONSTRAINTS
SELECT * FROM information_schema.CHECK_CONSTRAINTS cc;
-- Colunas utilizadas em CHECK CONSTRAINTS
SELECT * FROM information_schema.KEY_COLUMN_USAGE kcu WHERE table_name = 'employees';
-- Query 'user frendly' para verificar estado de CHECK CONSTRAINTS em tabela especificada
SELECT 
    name AS 'Constraint',
    object_name(parent_object_id) AS tabela,
	cc.definition,
    CASE is_disabled 
		WHEN 0 THEN 'ENABLE'
		WHEN 1 THEN 'DISABLE'
		ELSE 'N/A'
	END AS estado
FROM 
    sys.check_constraints cc
WHERE 
    parent_object_id = OBJECT_ID('hr.employees');

-- Teste 1: CH activa
INSERT INTO hr.EMPLOYEES 
	VALUES (1000,'Steve','King','S.KING','515.123.4567','2003.06.17','AD_PRES',0,NULL,NULL,90);	

-- Desactivar CONSTRAINT
ALTER TABLE HR.EMPLOYEES
	NOCHECK CONSTRAINT CH_EMPLOYEES_SALARY; --> NOCHECK CONSTRAINT ALL para desactivar todas as CONSTRAINT da tabela
GO

-- Teste 2: CH inactiva
INSERT INTO hr.EMPLOYEES 
	VALUES (1000,'Steve','King','S.KING','515.123.4567','2003.06.17','AD_PRES',0,NULL,NULL,90);

SELECT * FROM HR.EMPLOYEES e WHERE e.EMPLOYEE_ID >= 1000;  

-- ENABLE CONSTRAINTS
ALTER TABLE HR.EMPLOYEES
	CHECK CONSTRAINT CH_EMPLOYEES_SALARY; --> Não verifica coerência de dados!!!
GO

-- Teste 3: CH reactivada, mas sem verificação
INSERT INTO hr.EMPLOYEES 
	VALUES (1001,'Steve','King','S_KING','515.123.4567','2003.06.17','AD_PRES',0,NULL,NULL,90);
--> ERRO, mas... existe um registo com dados iguais!

-- ENABLE CONSTRAINTS com verificação
ALTER TABLE HR.EMPLOYEES
	WITH CHECK CHECK CONSTRAINT CH_EMPLOYEES_SALARY; --> WITH CHECK Verifica se os dados são coerentes com a CONSTRAINT antes de a activar
GO

-- Teste 4: Corrigir dados antes de reactivar a CH
UPDATE HR.EMPLOYEES
	SET SALARY = NULL
	WHERE SALARY = 0;

-- CREATE (revisitado)
-- 	Verificar TABLE existentes
SELECT * FROM information_schema.TABLES t WHERE TABLE_SCHEMA = 'hr';

-- 	Verificar COLUMNS em TABLE
SELECT * FROM information_schema.COLUMNS c WHERE c.TABLE_SCHEMA = 'hr' AND c.TABLE_NAME = 'employees';

/****************************************************************************************		
 * VIEW																					*
 ****************************************************************************************		
 * Uma VIEW é um query gravado que pode ser consultado a qualquer momento com uma 		*
 * instrução simples																	*
 * Qualquer query pode ser guardado numa VIEW											*
 * A VIEW não guarda dados, obtém-os no momento em que é chamada, executando o query 	*
 * indicado na sua especificação														*
 ****************************************************************************************
 * NOTA:																				*
 * EM MS-SQL, o CREATE VIEW tem que ser sempre a única instrução de um batch/script		*
 * pelo que tem sem pre que ser precedido da instrução GO ou executado de forma isolada	*
 ****************************************************************************************/
-- 	SINTAXE: 
--	CREATE VIEW «identificador» 
--		AS SELECT (...)

-- CREATE VIEW
-- ex.: análise estatistica por função
GO
CREATE VIEW hr.vw_MediaSalario_job
AS
    SELECT       job_id
	            ,MIN(salary) as 'minimo'
	            ,AVG(salary) as 'media'
	            ,MAX(salary) as 'maximo'
	            ,COUNT(employee_id) as 'funcionarios'
	    FROM HR.EMPLOYEES
	    GROUP BY job_id;
GO		
	   
SELECT * FROM hr.vw_MediaSalario_job v ORDER BY minimo; 

-- Os queries sobre VIEW retêm todas as propriedades dos queries, incluindo filtros e agregações
-- mas é necessário ter em conta os nomes das novas colunas e o seu significado 
SELECT * FROM hr.vw_MediaSalario_job 
	WHERE media > (SELECT AVG(salary) FROM hr.employees);
-- Note-se que a média passou a ser um valor, e não um agrupamento	

-- EM MS-SQL Não é possível utilizar controlo de execução nas construção de VIEW:
IF OBJECT_ID('hr.vw_MediaSalario_job', 'V') IS NULL
CREATE VIEW hr.vw_MediaSalario_job
AS
    SELECT       job_id
	            ,MIN(salary) as minimo
	            ,AVG(salary) as 'media'
	            ,MAX(salary) as 'maximo'
	            ,COUNT(employee_id) as 'funcionarios'
	    FROM employees
	    GROUP BY job_id;
END
GO
-- Isto porque o DB Engine considera que o IF é uma instrução, portanto, falha a regra enumerada anteriormente
-- do CREATE VIEW ser a única instrução do batch/scritp
-- A criação dinamica de VIEW em MS-SQL requer a execução de código dinamico, que se verá futuramente nas aulas
-- 
-- Em contrapartida, o MySQL mantém esta possibilidade com o comandos IF EXISTS e CREATE OR REPLACE

-- ALTER VIEW
-- Uma VIEW não contem dados, pelo que não tem impacto quando apagada
-- Por esta razão, não se utiliza ALTER VIEW       
-- O usual é apagar a VIEW (com teste de execução) e cria-la novamente
-- O ALTER VIEW obriga a reescrita integral da VIEW original, não se permite adição ao remoção de colunas:
ALTER VIEW HR.vw_MediaSalario_job ADD
	COUNT(DISTINCT SALARY);

ALTER VIEW HR.vw_MediaSalario_job AS 
	SELECT COUNT(DISTINCT SALARY) FROM employees e;	

SELECT * FROM HR.vw_MediaSalario_job;
-- Sendo a VIEW um objecto não persistente e que depende da estrutura de outros, 
-- é lógico que não permita alterações de estrutura já que podia criar incoerências

-- DROP VIEW  
IF OBJECT_ID('hr.vw_MediaSalario_job', 'V') IS NOT NULL  
	DROP VIEW HR.vw_MediaSalario_job;
-- Ao contrário do CREATE, o DROP permite controlo de execução
-- Juntando este factor à não persistência de dados, é boa-prática preceder o CREATE VIEW de um DROP VIEW com controlo de execução

-- (RE)CREATE VIEW:: Substitui ALTER
IF OBJECT_ID('hr.vw_MediaSalario_job', 'V') IS NOT NULL  
	DROP VIEW HR.vw_MediaSalario_job;
GO	
CREATE VIEW HR.vw_MediaSalario_job
AS
    SELECT   job_id
            ,MIN(salary) as minimo
            ,AVG(salary) as 'media'
            ,MAX(salary) as 'maximo'
            ,COUNT(DISTINCT SALARY) as 'vencimentos'
            ,COUNT(employee_id) as 'funcionarios'
	    FROM HR.EMPLOYEES
	    GROUP BY job_id;
GO		
       
-- 	Verificar VIEW existentes
SELECT * FROM information_schema.VIEWS v WHERE TABLE_SCHEMA = 'hr';
SELECT * FROM information_schema.TABLES t  WHERE TABLE_SCHEMA = 'hr';
SELECT * FROM information_schema.COLUMNS c WHERE c.TABLE_NAME like 'vw%';
-- No âmbito do INFORMATION_SCHEMA, as VIEWS são idênticas a TABLE
-- Note-se a coluna [VIEW_DEFINITION], que tem a especificação da VIEW

/****************************************************************************************		
 * INDEX																				*
 ****************************************************************************************		
 * 	O que é um indice? o que NÃO é um indice?											*
 * 	Os indices servem para ordenar tabelas pelas colunas indicadas, criando listas		*
 *	auxiliares que contém apenas as colunas do indice ordenadas							*
 *  Os inices podem servir de ordenação da tabela - CLUSTERED - ou terem ordenação 		*
 *	própria - NONCLUSTERED. Cada tabela só pode ter um CLUSTERED INDEX, uma vez que só	*
 *	pode existir uma ordem de armazenamento físico, mas podem ter os NONCLUSTEREDE que	*
 *	se considerem necessários															*
 *  Os indices facilitam a leitura, melhorando o desempenho da pesquisa, MAS implicam	*
 * 	custos adicionais na escrita já que a inserção no indice é independente da tabela	*
 * 																						*
 * Os indices podem ser:																*
 * IMPLICITOS: 	Criados automaticamente ao inserir chaves ou CONSTRAINT					*
 * 				Não podem ser criados ou alterados por código 							*
 * EXPLICITOS: 	Inseridos por código													*
 ****************************************************************************************/
-- 	Verificar INDEX existentes (sys.indexes)
-- 1. Verificar todos os indices de uma tabela
-- 	SELECT * FROM sys.indexes
--		WHERE object_id = OBJECT_ID('«table_name»', '«object_type»')
--	ex.:
SELECT * FROM sys.indexes
	WHERE object_id = OBJECT_ID('HR.EMPLOYEES', 'U');
-- Ou
-- 2. Verificar se um dado indice já existe
-- 	SELECT * FROM sys.indexes
--		WHERE name = '«index_name»'
--	ex.:
SELECT * FROM sys.indexes
	WHERE name = 'ix_phone';

-- CREATE INDEX
-- 	SINTAXE: CREATE [UNIQUE][NONCLUSTERED] INDEX «identificador» ON «table» («lista_colunas»)  
CREATE INDEX ix_phone ON HR.employees (phone_number);

-- Noutras implementações, a Sintaxe pode ser
-- 	ALTER TABLE HR.employees ADD
--		INDEX ix_phone ON phone_number;

-- Os INDEX são criados sobre colunas e especificos de tabela, mas são objectos globais,
-- o que significa que não podem ser duplicados na base de dados
-- Portanto, convém utilizar controlo de execução para verificar duplicação
-- Sendo um objecto dependente (de coluna), o INDEX não tem OBJECT_ID, 
-- tem que ser identificado a partir de tabela e coluna a que está associado ou de sys.indices
-- IF NOT EXISTS (
--    SELECT 1
--    FROM sys.indexes
--    WHERE name = '«nome_indice»'
--	)
--  CREATE [UNIQUE][NONCLUSTERED] INDEX «identificador» ON «table» («lista_colunas»);
-- ex.:
IF NOT EXISTS (
   SELECT 1
	   FROM sys.indexes
	    WHERE name = 'ix_phone'
)
CREATE NONCLUSTERED INDEX ix_phone ON HR.employees (phone_number);

-- Um INDEX pode ser definido para evitar duplicados, simulando CONSTRAINT UQ/AK
IF NOT EXISTS (
   SELECT 1
	   FROM sys.indexes
	    WHERE name = 'ix_phone'
)
CREATE UNIQUE NONCLUSTERED INDEX ix_phone ON HR.employees (phone_number);
-- Tal como acontece com CONSTRAINT, os dados existentes tm que ser validos para o INDEX
	
-- ALTER INDEX
-- Tal com nas VIEW, a estrutura de um INDEX não pode ser alterada pelo risco de incoerência, deve-se optar por RE-CREATE
-- Nalgumas implementações, no entanto, (incluindo o MS-SQL, a partir da versão 2012, e MYSQL, a partir da v.8) 
-- é possível (des)activar e reconstruit INDEX
-- Estas opções são muito úteis para inserção de grandes quantidades de linhas (BULK INSERT), uma vez que cada inserção 
-- implica escrita orenada em todos o indices da tabela
-- No entanto, os ganhos não serão relevantes face a apagar o INDEX e inseri-lo novamente após as inserções
-- Qualquer alteração de indice mantém a especificação original
-- De notar que a reordenação poderá ser muito demorada em virtude da dimensão da tabela e da complexidade do indice
-- para mitigar efeitos, pode-se utilizar a opção 
--	WITH (ONLINE = ON)
-- 	(a opção não melhora a velocidade, mas matém a tabela disponivél para consulta enquato o indice é ordenado)
--
-- EM MS-SQL é obrigatório manter o CLUSTERED INDEX, caso contrário o engine não consegue ler a tabela (ao desactivar este indice,
-- toda a tabela fica offline, não permitindo qualquer instrução)
-- Por esta razão, não é possivel desactivar a PK
-- ex. 1: Desabilitar indice
IF EXISTS (
   SELECT 1
	   FROM sys.indexes
	    WHERE name = 'ix_phone'
)
ALTER INDEX ix_phone
	ON HR.EMPLOYEES
	DISABLE;

-- ex. 2: Repor indice mantendo tabela online
IF EXISTS (
   SELECT 1
	   FROM sys.indexes
	    WHERE name = 'ix_phone'
)
ALTER INDEX ix_phone
	ON HR.EMPLOYEES
	REBUILD WITH (ONLINE = ON);	

-- ex.3: Reorganizar indice para optimização de armazenamento
IF EXISTS (
   SELECT 1
	   FROM sys.indexes
	    WHERE name = 'ix_phone'
)
ALTER INDEX ix_phone
	ON HR.EMPLOYEES
	REORGANIZE;	
-- A reorganização é menos exigente que a reconstrução, é sempre online (não requer indicação explicita), mas tem menos impacto
-- Não pode ser utilizada para reposição de indices desactivados

-- Sintaxe para MySQL v.8
-- ALTER TABLE employees ALTER INDEX ix_phone INVISIBLE;
-- VISIBLE para reactivar

-- Trabalhar com indices desactivados
-- verificar estado do indice pk_employees
SELECT 
    name AS 'Constraint',
    object_name(i.object_id) AS tabela,
    CASE is_disabled 
		WHEN 0 THEN 'ENABLE'
		WHEN 1 THEN 'DISABLE'
		ELSE 'N/A'
	END AS estado
FROM 
    sys.indexes i
WHERE 
    object_id = OBJECT_ID('hr.employees');

SELECT * FROM HR.EMPLOYEES e WHERE e.EMPLOYEE_ID >= 1000;

IF EXISTS (
   SELECT 1
	   FROM sys.indexes
	    WHERE name = 'UQ_EMPLOYEES_EMAIL'
)
ALTER INDEX UQ_EMPLOYEES_EMAIL
	ON HR.EMPLOYEES
	DISABLE;

-- teste 1: duplicar UQ
INSERT INTO hr.employees 
	VALUES (1001,'Steve','King','S KING','515.123.4567','2003.06.17','AD_PRES',24000,NULL,NULL,90);
-- Existe violação de unicidade de email:

-- ex. 2: Repor indice 
IF EXISTS (
   SELECT 1
	   FROM sys.indexes
	    WHERE name = 'UQ_EMPLOYEES_EMAIL'
)
ALTER INDEX UQ_EMPLOYEES_EMAIL
	ON HR.EMPLOYEES
	REBUILD;	
-- ERRO: Reposição do indice não respeita dados existentes


-- DROP INDEX
DROP INDEX IF EXISTS ix_phone ON HR.EMPLOYEES;

-- EXTRA: DELETE JOIN
-- apaga as linhas com elementos comuns em duas ou mais tabelas (preferivel limitar a 2 tabelas)
-- 	DELETE «lista_tabelas»
--		FROM «tabela_master» JOIN «tabela_slave» ON «regra_junção»
--		WHERE «filtro»