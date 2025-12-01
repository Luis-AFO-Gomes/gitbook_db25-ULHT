/********************************************************************************
 * Aula 08														  20/10/2025 	*
 * LIG/LEI/LCD/LMC															 	*
 *																			 	*
 * DDL: Implementação de conceitos												*
 *		- RELAÇÕES ou RELACIONAMENTOS											*
 *		- Integridade referencial												*
 *		Definição de estrutura:						 							*
 *		Restrições																*
 *		- Chaves Estrangeiras (Foreign Keys): FK								*
 ********************************************************************************/
 USE ULHT_DB25;

 -- Preparar ambiente de trabalho, eliminando entradas de aulas anteriores
 DELETE FROM HR.EMPLOYEES WHERE EMPLOYEE_ID >= 1000;

-- eliminar FK a criar no exemplo
 IF EXISTS(SELECT 1 FROM sys.foreign_keys
 				WHERE 	parent_object_id = OBJECT_ID('HR.EMPLOYEES','U') AND
						name = 'EMP_JOB_FK')
	ALTER TABLE HR.EMPLOYEES
		DROP CONSTRAINT EMP_JOB_FK;

 IF EXISTS(SELECT 1 FROM sys.foreign_keys
 				WHERE 	parent_object_id = OBJECT_ID('HR.EMPLOYEES','U') AND
						name = 'FK_EMPLOYESS_JOBS')
	ALTER TABLE HR.EMPLOYEES
		DROP CONSTRAINT FK_EMPLOYESS_JOBS;

ALTER TABLE HR.EMPLOYEES
	ALTER COLUMN JOB_ID VARCHAR(10) NOT NULL;		

-- FK 
-- Implementa integridade referencial.
-- na prática, pode considerar-se que cria uma regra de integridade entre colunas mas onde os valores possiveis são definidos por outra tabela
 SELECT * FROM sys.foreign_keys;
 SELECT * FROM sys.foreign_key_columns;

-- Introduzir FOREIGN KEY
ALTER TABLE HR.employees ADD
	CONSTRAINT EMP_JOB_FK FOREIGN KEY (JOB_ID)
		REFERENCES HR.JOBS(JOB_ID);
	
-- Também pode ser criada em linha no CREATE
-- 	CREATE TABLE employees (
-- 		...
-- 		JOB_ID VARCHAR(6) NOT NULL [FORREIGN KEY] REFERENCES jobs(JOB_ID)
-- 		...
-- 	
-- NOTAS:
-- A FOREIGN KEY cria relações de dependência, onde os valores de um conjunto (tabela) dependem dos de outro
-- A tabela onde é colocada a FK - [employees] no exemplo acima - fica com valores que dependem de valores da tabela referenciada - [jobs].
-- Por esta razão, a tabela da FK é designada por DEPENDENTE ou SLAVE e a tabela refenciada por INDEPENDENTE ou MASTER
-- 	
-- Uma FK impõe restrições ao modelo, ditas de integridade referencial por dependerem de uma referência
-- 1. Existindo um FK, os valor na tabela SLAVE têm que existir na MASTER, e vice-versa
SELECT * FROM HR.JOBS j WHERE j.JOB_ID IN ('AD_PRES','Presidente');

SELECT * FROM HR.employees e WHERE e.JOB_ID IN ('AD_PRES','Presidente');

INSERT INTO HR.EMPLOYEES 
	VALUES (1000,'Steve','King','S.KING','515.123.4567','2003.06.17','Presidente',24000,NULL,NULL,90);

INSERT INTO HR.EMPLOYEES 
	VALUES (1001,'Steve','King','S.KING','515.123.4567','2003.06.17','AD_PRES',24000,NULL,NULL,90);

SELECT * FROM HR.EMPLOYEES e WHERE e.EMPLOYEE_ID >= 1000;	

-- A restrição não se aplica a NULL. Como acontece com as CHECK CONSTRAINT, o NULL não é validado 	
INSERT INTO HR.EMPLOYEES 
	VALUES (1002,'Steve','King','SKING','515.123.4567','2003.06.17',NULL,24000,NULL,NULL,90); 
-- A FOREIGN KEY não tem qualquer impacto sobre a nulidade, sendo esta uma constraint local da tabela

-- em UPDATE
UPDATE HR.EMPLOYEES
	SET JOB_ID = 'presidente'
	WHERE EMPLOYEE_ID = 1002;

UPDATE HR.EMPLOYEES
	SET JOB_ID = 'AD_PRES'
	WHERE EMPLOYEE_ID = 1002;	

UPDATE HR.EMPLOYEES
	SET JOB_ID = NULL
	WHERE EMPLOYEE_ID = 1002;		
	
SELECT * FROM HR.JOBS j WHERE JOB_ID LIKE 'AD_PRES';	
SELECT * FROM HR.EMPLOYEES e WHERE e.JOB_ID LIKE 'AD_PRES' OR e.JOB_ID IS NULL;

DELETE FROM HR.EMPLOYEES WHERE EMPLOYEE_ID >= 1000;	
-- 	
-- 2. Inversamente, e pela mesma razão, não se pode eliminar um valor em MASTER se for referenciado em SLAVE
DELETE FROM HR.JOBS WHERE JOB_ID = 'AD_PRES';	

UPDATE HR.JOBS
	SET JOB_ID = 'presidente'
	WHERE JOB_ID = 'AD_PRES';

SELECT * FROM HR.JOBS j;

-- 3. Mais genericamente, a coluna sobre a qual é criada uma FK não pode ser alterada ao eliminada
-- SLAVE
ALTER TABLE HR.EMPLOYEES
	DROP COLUMN job_id;

-- MASTER
ALTER TABLE HR.JOBS
	DROP COLUMN job_id; 

-- Para poder apagar o valor, é necessário:
-- 	1. Apagar todas as linhas em SLAVE que o referenciem...
--	2. Apagar a FK
-- 	3. Utilizar REFERETIAL ACTION na FK
-- REFERENCIAL ACTION é uma acção programática que indica ao DBEngine o que fazer quando é alterado um valor refefenciado por uma FK
-- Dependendo da implementação, podem existir 2 REFERENTIAL ACTION: UPDATE e DELETE, que indicam a acção a executar em alteração e eliminação respectivamente
-- Também dependendo da implementação, a acção pode ser NO ACTION, CASCADE ou SET NULL
-- NO ACTION (acção por defeito): não permite qualquer acção (pode ser RESTRICT noutras implementações);
-- CASCADE: replica para SLAVE a acção em MASTER
-- SET NULL/SET DEFAULT (deprecated): altera o valor em SLAVE para NULL/DEFAULT, tinha utilização mais relevante em DELETE 
--
-- NOTA
-- É necessário ter cuidado com o uso de REFERENCIAL ACTION	uma vez que podem levantar problemas de coerência e isolamento de transacções
-- ex.: 
IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys
 				WHERE 	parent_object_id = OBJECT_ID('HR.EMPLOYEES','U') AND
						name = 'EMP_JOB_FK')
	ALTER TABLE HR.EMPLOYEES ADD
		CONSTRAINT EMP_JOB_FK FOREIGN KEY (JOB_ID)
			REFERENCES HR.JOBS(JOB_ID)
			ON UPDATE CASCADE
			ON DELETE NO ACTION
ELSE
BEGIN
	PRINT 'A CONSTRAINT EMP_JOB_FK já existe, será apagada' + CHAR(13) + CHAR(10) + 'executar novamente a instrução'
	ALTER TABLE HR.EMPLOYEES
		DROP CONSTRAINT EMP_JOB_FK
END;

	
UPDATE HR.JOBS  SET
	job_id = 'presidente'
	WHERE job_id = 'AD_PRES';

SELECT * FROM HR.JOBS j WHERE j.JOB_ID IN ('AD_PRES','Presidente');

SELECT * FROM HR.employees e WHERE e.JOB_ID IN ('AD_PRES','Presidente');

-- A reversão só pode ser realisada por instrução contrária
UPDATE HR.JOBS  SET
	job_id = 'AD_PRES'
	WHERE job_id = 'presidente';
	
/****************************************************************************************		
 * Activar e Desactivar FOREIGN KEYS													*
 ****************************************************************************************
 * Tal como acontece com as restantes CONSTRAINT, o funcionamento de FK também pode ser	*
 * manipulada por código sem a necessidade de as apagar e recriar						*
 *																						*
 * A sintaxe e funciionamento é muito semelhante às CHECK CONSTRAINTS					*
 ****************************************************************************************/
 SELECT  fk.name
 		,fk.is_disabled 
		,OBJECT_NAME(fk.principal_id) as principal
		,OBJECT_NAME(fk.parent_object_id) as parent_object
		,OBJECT_NAME(fk.referenced_object_id) as referenced_object
		,fk.delete_referential_action_desc as 'ON DELETE'
		,fk.update_referential_action_desc as 'ON UPDATE'
	FROM sys.foreign_keys fk
	WHERE fk.parent_object_id = OBJECT_ID('HR.EMPLOYEES','U');

-- DISABLE FOREIGN KEY	
ALTER TABLE HR.EMPLOYEES
	NOCHECK CONSTRAINT EMP_JOB_FK;

-- teste com FK
INSERT INTO HR.EMPLOYEES 
	VALUES (1000,'Steve','King','S.KING','515.123.4567','2003.06.17','presidente',24000,NULL,NULL,90); -- OK
	
-- DELETE FROM HR.EMPLOYEES WHERE EMPLOYEE_ID = 1000; 

SELECT *  FROM HR.jobs j WHERE JOB_ID = 'AD_PRES' OR JOB_ID = 'presidente';
	
SELECT * FROM HR.EMPLOYEES e WHERE e.EMPLOYEE_ID >= 1000;

-- o que acontece ao repor a FK?
ALTER TABLE HR.EMPLOYEES
	CHECK CONSTRAINT EMP_JOB_FK;

INSERT INTO HR.EMPLOYEES 
	VALUES (1001,'Steve','King','KING','515.123.4567','2003.06.17','presidente',24000,NULL,NULL,90); -- OK

-- Verificar inconsistências
SELECT * FROM HR.EMPLOYEES e 	
	WHERE e.JOB_ID NOT IN (SELECT j.JOB_ID FROM HR.jobs j);
-- Correcções
-- 1. Alterar valor errado
UPDATE HR.EMPLOYEES 
	SET job_id = 'AD_PRES' WHERE JOB_ID = 'presidente';
-- 	  Ou Apagar linhas com erro
DELETE FROM HR.EMPLOYEES 
	WHERE JOB_ID NOT IN (SELECT j.JOB_ID FROM HR.jobs j);
-- 2. Repor a CONSTRAINT, mas com verificação de coerência
ALTER TABLE HR.EMPLOYEES
	WITH CHECK
	CHECK CONSTRAINT EMP_JOB_FK;
-- São válidas todas as considerações realizadas anteriormente com as CHECK CONSTRAINT a propósito da coerência de dados
-- embora agora se apliquem no âmbito da INTEGRIDADE REFERENCIAL	

ALTER TABLE HR.EMPLOYEES 
	DROP CONSTRAINT EMP_JOB_FK;

/********************************************************************************
 *	Sintaxe completa para consulta de FOREIGN KEY em SYS.OBJECTS				*
 ********************************************************************************/ 
 SELECT * FROM sys.foreign_keys;
 SELECT * FROM sys.foreign_key_columns;

 SELECT	 fk.name AS 'KEY name'
		,SCHEMA_NAME(fk.schema_id) AS 'SCHEMA name'
		,OBJECT_NAME(fk.parent_object_id) AS 'TABLE name'
		,'FOREIGN KEY' AS 'KEY type'
        ,(SELECT ac.name FROM sys.all_columns ac WHERE ac.object_id=fkc.parent_object_id AND ac.column_id=fkc.parent_column_id) AS 'local column'
		,OBJECT_NAME(fkc.referenced_object_id) AS 'referenced table'
		,(SELECT ac.name FROM sys.all_columns ac WHERE ac.object_id=fkc.referenced_object_id AND ac.column_id=fkc.referenced_column_id) AS 'referenced column'
        ,fkc.constraint_column_id AS ordem
	FROM    sys.foreign_keys fk JOIN
			sys.foreign_key_columns fkc ON fk.object_id=fkc.constraint_object_id
    WHERE fk.schema_id = SCHEMA_ID('hr')	