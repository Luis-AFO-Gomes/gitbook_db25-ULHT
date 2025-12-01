/********************************************************************************
 * Aula 15														  	11/2025 	*
 * LIG/LEI/LCD/LMC															 	*
 *																			 	*
 * Programação Parte IV: Tratamento de Erros									*
 *	- TRY ... CATCH																*
 ********************************************************************************/
USE ULHT_DB25;

/************************************************************************************************************************************************************************
 * ERROR HANDLING																																						* 
 ************************************************************************************************************************************************************************
 * 	MS-SQL				* 
 ************************************************************************************************************************************************************************
 * o MS-SQL utiliza TRY ... CATCH para lidar com excepções																												*
 * Do mesmo modo, também não requer que INSTRUÇÕES COMPOSTA seja encapsuladas em módulos programados, embora seja esse o uso mais correcto por boas-práticas 			*
 ************************************************************************************************************************************************************************/

-- Ex. 1: SP de inserção com CATCH para duplicado de chave
IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[hr].[sp_InsertJob]')
                  AND type = N'P')
	DROP PROCEDURE [hr].[sp_InsertJob];
GO

CREATE PROCEDURE hr.sp_InsertJob(
    @inJob_ID 		VARCHAR(10), 
    @inJob_Title 	VARCHAR(35),
    @inMin_Salary 	DECIMAL(12,2),
    @inMax_Salary 	DECIMAL(12,2)
) AS
BEGIN
	BEGIN TRY    
	-- inserção de linha
	    INSERT INTO hr.jobs(JOB_ID,JOB_TITLE,MIN_SALARY,MAX_SALARY)
	    	VALUES(@inJob_ID,@inJob_Title,@inMin_Salary,@inMax_Salary);
	    
	END TRY 
	BEGIN CATCH
		SELECT 'Código de função existente (duplicação de PK)' Message
	END CATCH
END

SELECT * FROM hr.jobs j WHERE j.JOB_ID = 'T1';
DELETE FROM hr.jobs WHERE JOB_ID = 'T1';

EXEC hr.sp_InsertJob 'T1','Teste 1',2500,5000;

-- Ex. 2: UPDATE instead of INSERT
IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[hr].[sp_InsertJob]')
                  AND type = N'P')
	DROP PROCEDURE [hr].[sp_InsertJob];
GO

CREATE PROCEDURE hr.sp_InsertJob(
    @inJob_ID 		VARCHAR(10), 
    @inJob_Title 	VARCHAR(35),
    @inMin_Salary 	DECIMAL(12,2),
    @inMax_Salary 	DECIMAL(12,2)
) AS
BEGIN
	BEGIN TRY    
	-- tentativa de inserção de linha
	    INSERT INTO hr.jobs(JOB_ID,JOB_TITLE,MIN_SALARY,MAX_SALARY)
	    	VALUES(@inJob_ID,@inJob_Title,@inMin_Salary,@inMax_Salary);
	    
	END TRY 
	BEGIN CATCH
	-- Caso ocorra erro por duplicação de PK, actualizam-se dados em vez os inserir
		SELECT 'Função existente, dados serão actualizados' Message
		UPDATE hr.jobs 
			SET JOB_TITLE = @inJob_Title,
				MIN_SALARY = @inMin_Salary,
				MAX_SALARY = @inMax_Salary
			WHERE JOB_ID = @inJob_ID 
	END CATCH
END

SELECT * FROM hr.jobs j WHERE j.JOB_ID = 'T1';
DELETE FROM hr.jobs WHERE JOB_ID = 'T1';

EXEC hr.sp_InsertJob 'T1','Teste 1',2500,5000 ;
EXEC hr.sp_InsertJob 'T1','Teste 1',2000,5000 ;
/************************************************************************************************************************************************************************
 * NOTAS Exception Handling em MS-SQL																																	* 
 * O MS-SQL, ao contrário do que acontece noutras implementação (e.g. MySQL) não tem forma de continuar o código contornando a ocorrência de um erro					*
 * O comportamento pode ser implementado por recursividade ou evocação de procedimentos complementares chamados no CATCH. Deve-se ter muito cuidado no encadeamento 	*
 * porque qualquer transacção em curso (a que produziu o erro) fica pendente enquanto o código alternativo é executado													*
 *																																										*
 * É possivel dar informação ao utilizador recorrendo a um SELECT no bloco de tratamento de exepções (CATCH)															*
 *																																										*
 * Pela natureza da extrutura TRY ... CATCH, erros ocorridos no bloco de tratamento de excepções - CATCH - não são tratados. O DB Engine só consegue lidar com uma		*
 * execpção de cada vez																																					*
 * O mais adequado nestes casos é recorrer a abstração funcional, com chamadas no TRY/CATCH para lidar com erros mantendo a possibilidade de controlo da execução		*
 *																																										*
 * O tratamento de erros também pode ser particularizado, recorrendo a código de erro, SQLSTATE ou identificação genérica, de modo a fornecer informação mais detalhada *
 * ao utilizador. Este tratamento utiliza estrutura condicional - IF ou CASE - e funções de sistema de identificação de erro - p.e. ERROR_NUMBER()						*
 * Como se utiliza extrutura condiconal, não há prioridade na identificação do erro, será apresentada a primeira condição validada										*
 ************************************************************************************************************************************************************************/
-- Ex. 3.1: SP de inserção com CATCH e identificação de erro por código
IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[hr].[sp_InsertJob]')
                  AND type = N'P')
	DROP PROCEDURE [hr].[sp_InsertJob];
GO

CREATE PROCEDURE hr.sp_InsertJob(
    @inJob_ID 		VARCHAR(10), 
    @inJob_Title 	VARCHAR(35),
    @inMin_Salary 	DECIMAL(12,2),
    @inMax_Salary 	DECIMAL(12,2)
) AS
BEGIN
	BEGIN TRY    
	-- inserção de linha
	    INSERT INTO hr.jobs(JOB_ID,JOB_TITLE,MIN_SALARY,MAX_SALARY)
	    	VALUES(@inJob_ID,@inJob_Title,@inMin_Salary,@inMax_Salary);
	    
	END TRY 
	BEGIN CATCH
		DECLARE	 @errorNumber	int
				,@errorLine		int
				,@ErrorMessage	nvarchar(4000)
				,@ErrorSeverity int;  

		DECLARE @errorString	nvarchar(MAX)

		SELECT	 @errorNumber	= ERROR_NUMBER()
				,@errorLine		= ERROR_LINE()
				,@ErrorMessage 	= ERROR_MESSAGE()
				,@ErrorSeverity = ERROR_SEVERITY();  

		SET @errorString =	N'Ocorreu o erro ' + CAST(@errorNumber AS nvarchar(10)) +
							N', na linha ' + CAST(@errorLine AS nvarchar(10)) + N', ' +
							N'com descrição: ' + @ErrorMessage
		SELECT @errorString
	END CATCH
END
GO

SELECT * FROM hr.jobs j WHERE j.JOB_ID = 'T1';
DELETE FROM hr.jobs WHERE JOB_ID = 'T1';

EXEC hr.sp_InsertJob 'T1','Teste 1',2500,5000;

-- Ex. 3.2: SP de inserção com CATCH e tratamento de erro por ERROR_NUMBER
IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[hr].[sp_InsertJob]')
                  AND type = N'P')
	DROP PROCEDURE [hr].[sp_InsertJob];
GO

CREATE PROCEDURE hr.sp_InsertJob(
    @inJob_ID 		VARCHAR(10), 
    @inJob_Title 	VARCHAR(35),
    @inMin_Salary 	DECIMAL(12,2),
    @inMax_Salary 	DECIMAL(12,2)
) AS
BEGIN
	BEGIN TRY    
	-- Tentativa de inserção de linha
	    INSERT INTO hr.jobs(JOB_ID,JOB_TITLE,MIN_SALARY,MAX_SALARY)
	    	VALUES(@inJob_ID,@inJob_Title,@inMin_Salary,@inMax_Salary);
	    
	END TRY 
	BEGIN CATCH
	-- Tratamento de erro
		DECLARE	 @errorNumber	int
				,@errorLine		int
				,@ErrorMessage	nvarchar(4000)
				,@ErrorSeverity int;  

		DECLARE @errorString	nvarchar(MAX)

		SELECT	 @errorNumber	= ERROR_NUMBER()
				,@errorLine		= ERROR_LINE()
				,@ErrorMessage 	= ERROR_MESSAGE()
				,@ErrorSeverity = ERROR_SEVERITY()
		
		IF @errorNumber = 2627
	-- particularização do erro para duplicação de PK - Pode ser acrescentado com UPDATE em substituição do INSERT, conforme exemplo anterior
			SET @errorString = N'Código de função existente (duplicação de PK)'
		ELSE
	-- tratamento genérico para outros erros
			SET @errorString =	N'Ocorreu o erro ' + CAST(@errorNumber AS nvarchar(10)) +
								N', na linha ' + CAST(@errorLine AS nvarchar(10)) + N', ' +
								N'com descrição: ' + @ErrorMessage
								
		SELECT @errorString
	END CATCH
END
GO

SELECT * FROM hr.jobs j WHERE j.JOB_ID = 'T1';
DELETE FROM hr.jobs WHERE JOB_ID = 'T1';

EXEC hr.sp_InsertJob 'T1','Teste 1',2500,5000;
/************************************************************************************************************************************************************************
 * ERROR HANDLING com reversão: TRANSACTIONS																															* 
 ************************ 
 * 	MS-SQL				* 
 ************************/
 -- Ex. 4: SP de inserção multipla com COMMIT/ROLLBACK
-- 		  Funcionário muda de função, com inserção automática de histórico
DELETE FROM hr.job_history WHERE EMPLOYEE_ID = 1000;
DELETE FROM hr.employees  WHERE EMPLOYEE_ID = 1000;

INSERT INTO hr.employees
	(EMPLOYEE_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER, HIRE_DATE, JOB_ID, SALARY, COMMISSION_PCT, MANAGER_ID, DEPARTMENT_ID)
	VALUES(1000, 'TESTE', 'PARA', 'P.TESTE', NULL,CAST('2020-01-01' AS DATE) , 'AD_VP', 10000, NULL, 102, 60);

SELECT * FROM hr.employees e WHERE e.EMPLOYEE_ID = 1000;
SELECT * FROM hr.job_history jh WHERE jh.EMPLOYEE_ID =1000;
SELECT * FROM hr.jobs j;

-- Procedimento inicial:
IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[hr].[sp_NewJob]')
                  AND type = N'P')
	DROP PROCEDURE [hr].[sp_NewJob];
GO

CREATE PROCEDURE hr.sp_NewJob(
    @inEmployee_ID int, 
    @inJob_ID VARCHAR(10),
    @inSalary DECIMAL(12,2),
    @inDepartment_ID int
) AS
BEGIN
	BEGIN TRY 
-- Declaração de variáveis locais
		DECLARE @oldStart_date DATE
		DECLARE	@oldJob_ID VARCHAR(10)
		DECLARE @oldDepartment_ID int
 
-- inserir linha em [Job_history]			
			SELECT @oldJob_ID = e.job_id, @oldDepartment_ID = e.department_id
				FROM hr.employees e
				WHERE e.EMPLOYEE_ID = @inEmployee_ID
		
			SET @oldStart_date = COALESCE((SELECT TOP 1 jh.END_DATE 
											FROM hr.job_history jh 
											WHERE jh.EMPLOYEE_ID = @inEmployee_id 
											ORDER BY jh.END_DATE DESC),
										(SELECT e.Hire_date 
											FROM hr.employees e 
											WHERE e.EMPLOYEE_ID = @inEmployee_ID))

-- corrigir salário para limites da nova função										
			IF 	(@inSalary > (SELECT j.max_salary FROM hr.jobs j WHERE j.job_id = @inJob_ID)) 	
				SET @inSalary = (SELECT j.max_salary FROM hr.jobs j WHERE j.job_id = @inJob_ID)
			IF 	(@inSalary < (SELECT j.min_salary FROM hr.jobs j WHERE j.job_id = @inJob_ID)) 	
				SET @inSalary = (SELECT j.min_salary FROM hr.jobs j WHERE j.job_id = @inJob_ID)
		   
		    INSERT INTO hr.job_history(employee_id,START_DATE,END_DATE,JOB_ID,DEPARTMENT_ID)
		    	VALUES(@inEmployee_ID,@oldStart_date,GETDATE(),@oldJob_ID,@oldDepartment_ID)
		    
-- Actualizar registo de funcionário 
			UPDATE hr.employees 
				SET	 job_id = @inJob_ID
					,salary = @inSalary
					,DEPARTMENT_ID = @inDepartment_ID
				WHERE EMPLOYEE_ID = @inEmployee_ID
-- Se o código chegar a este ponto, significa que não houve erro.
	END TRY
	BEGIN CATCH
-- Com a execução a chegar ao CATCH, significa que houve erro.
		DECLARE	 @errorNumber	int
				,@errorLine		int
				,@ErrorMessage	nvarchar(4000)
				,@ErrorSeverity int

		DECLARE @errorString	nvarchar(MAX)

		SELECT	 @errorNumber	= ERROR_NUMBER()
				,@errorLine		= ERROR_LINE()
				,@ErrorMessage 	= ERROR_MESSAGE()
				,@ErrorSeverity = ERROR_SEVERITY()

		SET @errorString =	N'Ocorreu o erro ' + CAST(@errorNumber AS nvarchar(10)) +
							N', na linha ' + CAST(@errorLine AS nvarchar(10)) + N', ' +
							N'com descrição: ' + @ErrorMessage
		SELECT @errorString
	END CATCH
END
GO
-- Havendo um erro na segunda instrução - UPDATE - como se deve proceder para garantir as caracteriscas ACID da BD? é o que acontece efectivamente?
-- Consideremos que a função não existe
DELETE FROM hr.job_history WHERE EMPLOYEE_ID = 1000;

EXEC hr.sp_NewJob 1000,'AD_PRES',25000,90;

SELECT * FROM hr.employees e WHERE e.EMPLOYEE_ID = 1000;
SELECT * FROM hr.job_history jh WHERE jh.EMPLOYEE_ID =1000;

-- Como se esperaria, a função do funcionário não é alterada, porque a indicada não existe, com o erro a ser tratado pelo HANDLER de excepção genérica, mas...
-- ... a primeira instrução - INSERT INTO job_history - é realizada criando uma situação de incoerência na base de dados
-- Isto acontece porque as instruções são separadas e a segunda só é iniciada após conclusão sem erros da primeira, sendo que o HANDLER só é chamada com a ocorrência do erro
-- (segunda instrução), só afectando esta

-- Para corrigir esta situação, ter-se-á que utilizar TRANSACÇÕES de forma a garantir a execução solidaria das instruções - ATOMICIDADE 
-- Ou seja, para garantir o modelo ACID, iremos definir o nivel de atomicidade para a totalidade do procedimento, de forma a garantir a coerência

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[hr].[sp_NewJob]')
                  AND type = N'P')
	DROP PROCEDURE [hr].[sp_NewJob];
GO

CREATE PROCEDURE hr.sp_NewJob(
    @inEmployee_ID int, 
    @inJob_ID VARCHAR(10),
    @inSalary DECIMAL(12,2),
    @inDepartment_ID int
) AS
BEGIN
	BEGIN TRY 
-- Declaração de variáveis locais
		DECLARE @oldStart_date DATE
		DECLARE	@oldJob_ID VARCHAR(10)
		DECLARE @oldDepartment_ID int
	
-- Transacção (para garantia de modelo ACID)
		BEGIN TRANSACTION
	    
-- inserir linha em [Job_history]			
			SELECT @oldJob_ID = e.job_id, @oldDepartment_ID = e.department_id
				FROM hr.employees e
				WHERE e.EMPLOYEE_ID = @inEmployee_ID
		
			SET @oldStart_date = COALESCE((SELECT TOP 1 jh.END_DATE 
											FROM hr.job_history jh 
											WHERE jh.EMPLOYEE_ID = @inEmployee_id 
											ORDER BY jh.END_DATE DESC),
										(SELECT e.Hire_date 
											FROM hr.employees e 
											WHERE e.EMPLOYEE_ID = @inEmployee_ID))

-- corrigir salário para limites da nova função										
			IF 	(@inSalary > (SELECT j.max_salary FROM hr.jobs j WHERE j.job_id = @inJob_ID)) 	
				SET @inSalary = (SELECT j.max_salary FROM hr.jobs j WHERE j.job_id = @inJob_ID)
			IF 	(@inSalary < (SELECT j.min_salary FROM hr.jobs j WHERE j.job_id = @inJob_ID)) 	
				SET @inSalary = (SELECT j.min_salary FROM hr.jobs j WHERE j.job_id = @inJob_ID)
		   
		    INSERT INTO hr.job_history(employee_id,START_DATE,END_DATE,JOB_ID,DEPARTMENT_ID)
		    	VALUES(@inEmployee_ID,@oldStart_date,GETDATE(),@oldJob_ID,@oldDepartment_ID)
		    
-- Actualizar registo de funcionário 
			UPDATE hr.employees 
				SET	 job_id = @inJob_ID
					,salary = @inSalary
					,DEPARTMENT_ID = @inDepartment_ID
				WHERE EMPLOYEE_ID = @inEmployee_ID
		
-- Se o código chegar a este ponto, significa que não houve erro.
-- Pode-se fechar a transacção tornando as alterações definitivas (COMMIT)
		IF @@TRANCOUNT > 0 	-- ... mas apenas se houver alterações
							-- COMMIT sem linhas inseridas ou alteradas irá produzir erro
			COMMIT			-- Não há END explicito para TRANSACTION
							--	o bloco é terminado com COMMIT ou ROLLBACK
	END TRY
	BEGIN CATCH
-- Com a execução a chegar ao CATCH, significa que houve erro.
-- Terá que se reverter a transacção eliminando toas as alterações (ROLLBACK)	
		IF @@TRANCOUNT > 0 	-- ... mas també, apenas se houver alterações
							-- Tal como o COMMIT, o ROLLBAK sem linhas resulta em erro produzir erro
			ROLLBACK	
				
		DECLARE	 @errorNumber	int
				,@errorLine		int
				,@ErrorMessage	nvarchar(4000)
				,@ErrorSeverity int

		DECLARE @errorString	nvarchar(MAX)

		SELECT	 @errorNumber	= ERROR_NUMBER()
				,@errorLine		= ERROR_LINE()
				,@ErrorMessage 	= ERROR_MESSAGE()
				,@ErrorSeverity = ERROR_SEVERITY()

		SET @errorString =	N'Ocorreu o erro ' + CAST(@errorNumber AS nvarchar(10)) +
							N', na linha ' + CAST(@errorLine AS nvarchar(10)) + N', ' +
							N'com descrição: ' + @ErrorMessage
		SELECT @errorString
	END CATCH
END
GO

/************************************************************************************************************************************************************************
 * NOTAS DE BOAS PRÁTICAS:																																				*
 * Sempre que existir um erro com código conhecido, deve-se particularizar a informação e, sempre que possível, proceder ao tratamento adequado 						*
 * No exemplo a cima, podem ocorrer erro de identificação de função, de omissão de valore de vencimento ou outros. Disponibilizar ao utilizador a informação adequada é *
 * essencial para a qualidade da solução																																*
 * Em adição aos erros conhecidos, deve-se acescentar sempre tratamento genérico para captura de todas as outras situações, evitando erros não tratados					*
 ************************************************************************************************************************************************************************/
INSERT INTO HR.EMPLOYEES
	(EMPLOYEE_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER, HIRE_DATE, JOB_ID, SALARY, COMMISSION_PCT, MANAGER_ID, DEPARTMENT_ID)
	VALUES(1000, 'Luis', 'Gomes', 'T.SILVA', '555.555.555',CAST('2020-01-01' AS DATE) , 'AD_VP', 15000, NULL, 100, 60);

SELECT * FROM hr.employees e WHERE e.EMPLOYEE_ID = 1000;
SELECT * FROM hr.job_history jh WHERE jh.EMPLOYEE_ID =1000;
SELECT * FROM hr.jobs WHERE JOB_ID = 'XPTO';

DELETE FROM hr.job_history WHERE EMPLOYEE_ID = 1000;
DELETE FROM hr.employees  WHERE EMPLOYEE_ID = 1000;

UPDATE HR.JOBS
	SET JOB_ID = 'AD_PRES'
	WHERE JOB_ID = 'presidente';

EXEC hr.sp_NewJob 1000,'XPTO',24000,90;

EXEC hr.sp_NewJob 1000,'AD_PRES',24000,90;

EXEC hr.sp_NewJob 1000,'AC_MGR',24000,90;

DECLARE @myEmployee NUMERIC(6) = 1000
SELECT * FROM HR.ft_resume(@myEmployee)

/************************************************************************************************************************************************************************
 * Erros personalizados:																																				*
 * Sempre que necessário, o SQL também permite que sejam gerados erros personalizados para maior controle de execução. Este tipo de operação é particularmente útil em	*
 * em código encadeado, particularmente módulos programados, e em operação remota para passar informação útil ao cliente												*
 * Ter em conta que o CATCH só responde ao último erro. Se houver encadeamento, a operação exterior pode não capturar erros do bloco internos 							*
 * Função RAISERROR																																						*
 *	- Sintaxe: RAISERROR ( message_string , severity , state [ , argument [ ,...n ] ] )																					*
 *	- message_string: texto do erro (até 4000 caracteres), pode conter parametros a prencher pelos argumentos indicados no final										*
 *	- severity: nível de severidade do erro (0-25)																														*
 *		* 0-10 : WARNING (INFORMATIVO), não é tratado como erro, mas fica em log e é apresentado no stdio																*
 *		* 11-16: Erros gerados pelo utilizador, podem ser tratados																										*
 *				 se for gerado num bloco TRY, a execução passa para o CATCH; se gerado no CATCH, devolve o erro para o código que chamou o bloco						*
 *		* 17-25: Erros criticos, a ligação é fechada e o erro listado no log																							*
 *	- state: valor definido pelo utilizador, entre 0 e 255, serve para ajudar a localizar o erro no código																*
 *	- argument: valores opcionais para formatação do message_string, semelhante ao que acontece com outras linguagens (e.g. C ou Java)									*				
 ************************************************************************************************************************************************************************/
-- Ex.:
BEGIN TRY
	RAISERROR('Teste de erro personalizado: ID=%d',16,1,9999);
END TRY
BEGIN CATCH	
	DECLARE	 @errorNumber	int				= ERROR_NUMBER()	--> 50000 (por defeito para RAISERROR)
			,@errorLine		int				= ERROR_LINE()	
			,@ErrorMessage	nvarchar(4000)	= ERROR_MESSAGE()
			,@ErrorSeverity int				= ERROR_SEVERITY()
			,@ErrorState	int				= ERROR_STATE();  

	DECLARE @errorString	nvarchar(MAX)	=	N'Ocorreu o erro ' + CAST(@errorNumber AS nvarchar(10)) +
												N', na linha ' + CAST(@errorLine AS nvarchar(10)) + N', ' +
												N'com descrição: ' + @ErrorMessage + 
												N', Severidade: ' + CAST(@ErrorSeverity AS nvarchar(10)) +
												N', Estado: ' + CAST(@ErrorState AS nvarchar(10))

	SELECT @errorString

	PRINT 'erro de utilizador'
	RAISERROR('Teste de erro personalizado: ID=%d',16,1,9999);
END CATCH	

  