/********************************************************************************
 * Aula 13														  27/11/2024 	*
 * LIG/LEI/LCD/LMC															 	*
 *																			 	*
 * Programação parte II: Módulos Programados									*
 * - procedimentos																*
 * - Funções																	*
 *	 - Funções Escalares														*
 *	 - Funções Vectorias (Table Value)											*
 * Definição e chamada															*
 ********************************************************************************/
USE ULHT_DB25;

-- 	ANTES DE INICIAR:
-- 	Verificar estado de transações e nível de isolamento
select IIF(@@OPTIONS & 2 = 0, 'OFF', 'ON');
SET IMPLICIT_TRANSACTIONS OFF; -- > Apenas para o query executado depois da instrução

-- Verificar nível de isolamento actual
SELECT CASE transaction_isolation_level	
			WHEN 0 THEN 'Unspecified'  							
			WHEN 1 THEN 'ReadUncommitted'  						
			WHEN 2 THEN 'ReadCommitted'  						
			WHEN 3 THEN 'Repeatable Read'  							
			WHEN 4 THEN 'Serializable'  						
			WHEN 5 THEN 'Snapshot' 
		END AS TRANSACTION_ISOLATION_LEVEL  
	FROM sys.dm_exec_sessions  								
	WHERE session_id = @@SPID;

/************************************************************************************************************************************************************************
 * Como em qualquer linguagens de programação, o SQL permite a utilização de de sub-programas para abstração funcional. Sendo o SQL uma linguagem de scripting, o que 	*
 * significa que não existe uma aplicação em operação, a abstração funcional tem maior impacto uma vez que permite criar módulos que podem ser executados em qualquer 	*
 * momento																																								*
 * Os usos mais comuns para módulos programados são:																													*
 * - Transações de escrita com multiplas inserções																														*
 * - Instruções compostas e código complexo																																*
 * - Segurança 																																							*
 ************************************************************************************************************************************************************************
 * Em MySQL a abstração funcional tem uma utilização adicional, já que que este não permite o uso de INSTRUÇÕES COMPOSTA em código 'livre', limitando o seu uso a 		*
 * PROCEDIMENTOS, FUNÇÕES e TRIGGERS	                            *
 * Define-se como INSTRUÇÃO COMPOSTA um bloco de instruções delimitado por BEGIN ... END ou estrutura similar															*
 * Mais informações sobre INSTRUÇÕES COMPOSTAS em: https://dev.mysql.com/doc/refman/8.0/en/sql-compound-statements.html													*
 ************************************************************************************************************************************************************************/

-- 1. 	Elementos básicos
-- 		Os procedimentos, designados por STORED PROCEDURES ou SP são subprogramas procedimentais

--	MS-SQL:
GO	-- tal como acontece com a VIEW, a criação de PROCEDURES e FUNCTIONS têm que ser o primeiro comando do batch
	-- Para o efeito, utiliza-se o comando GO para delimitar batches
CREATE PROCEDURE sp_exemplo
AS
BEGIN
	-- Código do procedimento
END;
GO

--	Ex. MS-SQL
--	Definir procedimento com verificação prévia de a existência do objecto, recorre às tabelas de sistema (sys table)
--	Este processo reveste-se de alguma complexidade porque requer a verificação por nome do objecto, mas também a identificação de tipo
IF EXISTS (SELECT *
			FROM   sys.objects
			WHERE  object_id = OBJECT_ID(N'[HR].[sp_exemplo]')
					AND type = N'P')
	DROP PROCEDURE [HR].[sp_exemplo];
GO							
CREATE PROCEDURE HR.sp_exemplo AS	-- O MS-SQL requer o termo 'AS' para indicar o início do código do procedimento
	BEGIN		
		SET NOCOUNT OFF;	-- Evita a apresentação de mensagens de contagem de registos afectados

		SELECT * FROM HR.DEPARTMENTS

	END;
GO	
--	Não esquecer que a sintaxe correcta em MS-SQL requer que seja identificado o schema a que será associado o objecto
--	(mesmo que se trate do default schema: dbo)	
  
-- 	O mesmo método de verificação de objecto pode ser utilizado para todos os tipos
--	Os tipos de objectos são:
--		C  - CHECK_CONSTRAINT  
--		D  - DEFAULT_CONSTRAINT  
-- 		F  - FOREIGN_KEY_CONSTRAINT  
--		FN - SQL_SCALAR_FUNCTION  
--		FS - CLR_SCALAR_FUNCTION  
-- 		IT - INTERNAL_TABLE  
-- 		P  - SQL_STORED_PROCEDURE  
-- 		PK - PRIMARY_KEY_CONSTRAINT  
-- 		S  - SYSTEM_TABLE  
-- 		SQ - SERVICE_QUEUE  
--		TR - SQL_TRIGGER  
--		U  - USER_TABLE  
--		UQ - UNIQUE_CONSTRAINT  
-- 		V  - VIEW    

-- 	O exemplo anterior serve apenas para demonstrar a sintaxe de definição de um PROCEDURE. Não é O uso mais comum dos procedimentos é simplificar o código que se escreveria em scripts 
-- 	Ex.2: aumentar o vencimento aos funcionários com vencimento abaixo da média  
IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[HR].[sp_exemplo]')
                  AND type = N'P')
	DROP PROCEDURE [HR].[sp_exemplo];
GO
-- A necessidade de incluir a instrução GO impede que se faça a definição do procedimento dentro de um bloco
-- No entanto, qualquer módulo programado pode ser apagado e recriado em sequência de instruções uma vez que tem acção passiva
CREATE PROCEDURE [HR].[sp_exemplo] AS
	BEGIN
		DECLARE @media NUMERIC(9,3) = 0;	-- obrigatório o uso do prefixo '@'
		
		SET @media = (SELECT AVG(SALARY) FROM HR.employees);
		-- Como alternativa, apenas é válido o formato:
		--		SELECT media = AVG(SALARY) FROM employees;

		UPDATE HR.employees 
			SET salary = salary * 1.1
			WHERE salary < @media;	
	END;
GO		

-- Como em qualquer linguagem de programação, um procedimento não devolve qualquer valor
-- No entanto, pode apresentar resultados para consola ou reposta a utilizador através de instruções SELECT
-- Não havendo instrução SELECT no procedimento, não é apresentado qualquer resultado no stdio/consola

-- Na versões mais recentes do MS-SQL, é possível utilizar o comando CREATE OR ALTER PROCEDURE, 
-- que permite criar ou alterar um procedimento sem necessidade de verificação prévia
-- A instrução anterior pode ser reescrita como:
CREATE OR ALTER PROCEDURE HR.sp_exemplo AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @media NUMERIC(9,3) = 0;	-- obrigatório o uso do prefixo '@'
		
		SET @media = (SELECT AVG(SALARY) FROM HR.employees);
		-- Como alternativa, apenas é válido o formato:
		--		SELECT media = AVG(SALARY) FROM employees;

		UPDATE HR.employees 
			SET salary = salary * 1.1
			WHERE salary < @media;	
	END;	
GO		-- O GO continua a ser obrigatório

-- Ex.3: Procedimento sem consulta a dados existentes - Calcular a data na próxima semana
--       Para este resultado, é mais correcto o uso de uma função, mas faz-se uso de procedimento para demonstração de funcionamento
IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[hr].[sp_data]')
                  AND type = N'P')
	DROP PROCEDURE [hr].[sp_data];
GO

CREATE PROCEDURE [hr].[sp_data] AS
	BEGIN
		SELECT DATEADD(ww,1,GETDATE()); 
	END;
GO

-- 2. 	Invocar um procedimento
--		A chamada a um procedimento é realizada pela instrução EXEC, obedecendo à assinatura
-- 	Ex.2: aumentar o vencimento aos funcionários com vencimento abaixo da média  
EXEC [HR].[sp_exemplo];
SELECT * FROM HR.employees;

-- Ex.3: Procedimento sem consulta a dados existentes - Calcular a data na próxima semana
EXEC [HR].[sp_data];

--	Em MS-SQL, não é necessário a utilização de '(' e ')' na invocação de procedimentos, mesmo que tenham parâmetros
--	Por outro lado, é possivel guardar o código de execução do procedimento para debug
DECLARE @resultado AS DATETIME;

EXEC @resultado = [HR].[sp_data];

SELECT @resultado AS 'próxima semana';

-- 4. 	parametros
-- 		Em SQL os parametros são passados por valor, indicando-se o tipo de dados
-- 		No entanto, têm a particularidade de requerer a indicação explicita de parametros de saída
--		Na sintaxe base, a direccionalidade tem que ser indicada em todos os casos. Por efeito, a direccção é IN
-- 		que será o comportamento assumido na ausência de indicação explícita, podendo omitir-se a indicação
--		Os parametros podem ser de entrada (IN), saída (OUT) ou ambos (INOUT)
-- 		Ex.2: aumentar o vencimento aos funcionários indicando o vencimento máximo que recebe aumento e a % do aumento
IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[HR].[sp_exemplo]')
                  AND type = N'P')
	DROP PROCEDURE [HR].[sp_exemplo];
GO	

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[HR].[sp_data]')
                  AND type = N'P')
	DROP PROCEDURE [HR].[sp_data];	
GO

CREATE PROCEDURE [HR].[sp_exemplo]
		 @minimo NUMERIC(9,3)
		,@aumento NUMERIC(3,2) 
	AS
	BEGIN
		SET NOCOUNT ON;

		UPDATE hr.employees 				-- > Se o Schema não for especificado, é utilizado o de definição da SP
			SET salary = salary * (1+@aumento)
			WHERE salary < @minimo;	
	END;		

-- 		A chamada a procedimentos com parametros mantém o principio de chamada com respeito pela assinatura
DECLARE @resultado AS NUMERIC(6,0);

EXEC @resultado = HR.sp_exemplo 10000,0.1;

SELECT @resultado

SELECT * FROM HR.EMPLOYEES;

--		É possível tratar nulidade de parâmetros, evitando erros na omissão dos mesmos
--		A correcção é realizada na declaração do procedimento, atribuindo valores DEFAULT aos parâmetros
--		Ou introduzindo lógica de tratamento de NULL no código do procedimento
IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[HR].[sp_exemplo]')
                  AND type = N'P')
	DROP PROCEDURE [HR].[sp_exemplo];
GO

CREATE PROCEDURE [HR].[sp_exemplo]
		 @minimo NUMERIC(9,3) = NULL
		,@aumento NUMERIC(3,2) = 0.03
	AS
	BEGIN
		SET NOCOUNT ON;

		IF (@minimo IS NULL)
			SET @minimo = (SELECT AVG(salary) FROM hr.employees);
		UPDATE hr.employees 
			SET salary = salary * (1 + @aumento)
			WHERE salary < @minimo;	
	END;		
GO

-- 		A chamada a procedimentos com parametros mantém o principio de chamada com respeito pela assinatura
--		mas como a possibilidade de indicação específica de NULL ou omissão de parâmetros
DECLARE @resultado AS NUMERIC(6,0);

-- EXEC @resultado = HR.sp_exemplo NULL,NULL;
-- A chamada com NULL mantém os valores de chamada - NULL

EXEC @resultado = HR.sp_exemplo @aumento=-0.01;
-- Mas a omissão preenche os valores omissos com o DEFAULT da decçaração da SP
-- O emparelhamento dao valores é ordenado de acordo com a declaração da SP. Neste caso, o NULL é atribuído a @minimo (1ª variável)

 SELECT @resultado

IF @resultado =0
	PRINT 'query executado com sucesso'

SELECT * FROM HR.EMPLOYEES;

--		O comportamento de chamada com omissão de parâmetros é diferente do MySQL, diferenciando-se entre o uso de NULL e a falta de parâmetros
--		No MySQL, a omissão de parâmetros não é permitida, sendo obrigatório o uso de NULL para indicar ausência de valor

-- 5. 	retorno de valores
-- 		O uso de parametros para retorno tem algumas alterações que aumentam a complexidade da declaração do procedimento
-- 		A indicação de direccionalidade da passagem de valores - OUT ou INOUT - passa a ser estricatamente obrigatória
--		Além disso, a variavel terá que existir no ambiente de invocação para receber o valor retornado 
--		E TAMBÉM TEM QUE INDICAR A DIRECCIONALIDADE NA CHAMADA para que o SQL saíba que tem que devolver o valor
--		(valores passados por referência)
-- 		Ex.: Calculo do endereço de email a partir do nome do funcionario
IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[hr].[sp_email]')
                  AND type = N'P')
	DROP PROCEDURE [hr].[sp_email];
GO

CREATE PROCEDURE [hr].[sp_email]
		 @funcionario NUMERIC(4)
		,@email VARCHAR(64) OUT
	AS
	BEGIN
	SELECT @email = LOWER(CONCAT(LEFT(e.first_name,1),'.',e.last_name,'@dominio.com'))
		FROM hr.employees e 
		WHERE e.employee_id = @funcionario
	END;
GO

DECLARE  @resultado AS NUMERIC(6,0)
		,@email_out AS VARCHAR(64) = '';

EXEC @resultado = hr.sp_email 100,@email = @email_out OUTPUT;

SELECT @resultado,@email_out	
GO	-- o GO não ligado a batch/CREATE serve para forçar a 'limpeza' do ambiente, i.e., libertar variaveis
	-- é útil para separar instruções mas também para evitar conflitos de nomes de variaveis e outro erro indesejados em scripts longos
	-- Não é obrigatório, mas recomendado já que evita efeitos colaterais indesejados

-- 		@resultado retém o código de erro da execução do procedimento (0 = sucesso)
--		que servirá para debug complementar, realizado no âmbito da chamada à SP, e independente do código do procedimento

-- 6.	Uso corrente
-- 		Os usos mais frequentes de procedimentos são inserções ou alterações de dados em tabelas, particularmente quando aplicada a multiplas tabelas.
-- 		Este uso é associado a TRANSAÇÕES e EXCEPCION HANDLING, que veremos posteriormente

-- 		A chamada a um procedimento com parametros pode não ter valores, mas o parametro tem que ser sempre indicado
-- 		Nesse caso, terá que se passar a indicalção NULL e garantir que o código do procedimento trata essa possibilidade
IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[hr].[sp_email]')
                  AND type = N'P')
	DROP PROCEDURE [hr].[sp_email];
GO

CREATE PROCEDURE [hr].[sp_email]
		 @funcionario NUMERIC(4)
		,@email VARCHAR(64) OUTPUT
	AS
	BEGIN
	SELECT @email = LOWER(CONCAT(LEFT(e.first_name,1),'.',e.last_name,'@dominio.com'))
		FROM hr.employees e 
		WHERE e.employee_id = @funcionario
	SELECT @email = ISNULL(@email,'email inválido')
	END;
GO


DECLARE  @resultado AS NUMERIC(6,0)
		,@email AS VARCHAR(64);

EXEC @resultado = hr.sp_email 10,@email = @email OUTPUT;

SELECT @resultado,@email	
GO

/************************************************************************************************************************************************************************
 * FUNÇÕES																																								* 
 ************************************************************************************************************************************************************************/

-- 1.	Elementos básicos
-- 		As funções são semelhantes aos procedimentos, com a diferença base de retornarem valores, como acontece em qualquer linguagem de programação
-- 		Outra diferença fundamental da funções é que os parametros não requerem indicação de direcção, todos são de exclusivamente de entrada (IN), 
--		existindo apenas um valor de retorno que é a própria função
-- 		Também na invocação há diferenças já que existe a necessidade de lidar com o valor de retorno
-- 
-- 		NOTA: 	O MySQL não permite funções que devolvem tabelas, apenas os tipos simples de dados {STRING|INTEGER|REAL|DECIMAL}
-- 				Para se obter uma tabelas, deve-se utilizar um procedimento tendo como instrução final o SELECT com a relação a devolver
-- 				A relação a devolver pode ser criada e povoada dentro do procedimento. No entanto, há que ter em conta questões de performance e recursos na execução do 
-- 				procedimento, para mais se houver recursividade e/ou concorrência
--
--				Já o MS-SQL possui tipo específico de funções, designadas de VECTORIAIS ou TABLE FUNCTION (TF), que retornam funções

-- 2.	Definição de função
-- 		SINTAXE
-- 			CREATE FUNCTION «identificador»([«parametros»]) RETURNS {STRING|INTEGER|REAL|DECIMAL} 
-- 			BEGIN
-- 				...
-- 				RETURN «valor_retorno»;
-- 			END
-- 			GO
-- 
-- 		Onde:
-- 			«parametros» ::= «parametros»|«parametro»,«parametros»
-- 			«parametro» ::= [IN|OUT|INOUT]«identificador» 
-- 
-- 		A instrução RETURN tem que existir em todos os caminhos possiveis da função e ter que ser a última a ser executada, 
-- 		qualquer instrução posterior não é executada e provoca erro na criação da função  

-- 		Ex.1: o email...
IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[hr].[ufn_email]')
                  AND type = N'FN')
	DROP FUNCTION [hr].[ufn_email];
GO

CREATE FUNCTION [hr].[ufn_email](
		@funcionario NUMERIC(4)
		) RETURNS VARCHAR(64)
	AS
	BEGIN
	DECLARE @email VARCHAR(64)
	SELECT @email = LOWER(CONCAT(LEFT(e.first_name,1),'.',e.last_name,'@dominio.com'))
		FROM hr.employees e 
		WHERE e.employee_id = @funcionario
	RETURN ISNULL(@email,'Invalid address')
	END;
GO
-- 3. 	Invocar uma função
-- 		Uma função pode ser chamada de duas formas distintas:
-- 		Ex.1: Como atribuição do valor de retorno a uma variavel
DECLARE @email AS VARCHAR(64);
SET @email = hr.ufn_email(100);
SELECT @email;
GO

-- 		Ex.2: Como parte de uma instrução de SELECT 
SELECT hr.ufn_email(100);

-- 			Este formato pode ser utilizado dentro de instrução SELECT mais complexa
SELECT e.FIRST_NAME,e.LAST_NAME, hr.ufn_email(e.EMPLOYEE_ID) FROM hr.employees e; 


/****************************************************************************************************************************
 * Funções Vectoriais ou de Tabela [Apenas MS-SQL]																			*
 *	- Funções de devolvem tabelas																							*
 ****************************************************************************************************************************/ 
-- Estas funções são em tudo iguais às funções escalares com a excepção de devolverem tabelas (vectores multidimensionais)
-- ao invés de devolverem valores isolados (escalares)
--
-- As funções vectoriais pode apresentar dois formatos consoante a especificação da tabela de retorno seja incluida na 
-- assinatura da função ou não
-- Ex. 1: Especificação de tabela na assinatura da função:
--	A função [fn_resume(employee_id)] devolve o percurso profissional de um funcionário na empresa
--	O formato de saida é propositadamente definido para ser idêntico a [JOB_HISTORY] para realçar a capacidade de abstracção
--	do SQL. Com a presente função apresenta-se o registo de cada funcionário acrescentando a ultima função desempenhada, que
--	consta da tabela [EMPLOYEES] e não da [JOB_HISTORY]
--
-- SINTAXE: funções vectoriais com tabela de retorno na assinatura
-- CREATE FUNCTION [«schema_name».]«function_name» («lista_parametros») 
--		RETURNS TABLE «especificação_tabela»
--		AS
--		BEGIN
-- 			«instruções»
--			RETURN
--		END
--
--	onde 
--		«lista_parametros» ::= «parametro»|«parametro»,«lista_parametros»
--			«parametro» ::= @«nome» «tipo» [= «default»] 
-- 			[= default] ::= valor a utilizar caso a variavel não seja identifica na invocação
--		«especificação_tabela» ::= («lista_coluna»)
--			«lista_colunas» ::= «coluna»|«coluna»,«lista_colunas»
--			«coluna» ::= «identificador» «data_type»
--
-- Uma função continua a devolver apenas 1 (um) valor, embora sobre a forma de uma tabela com a especificação 
-- indicada (RETURNS TABLE ...)
-- A função pode ter código bastante complexo e extenso, mas todas as terminações possiveis terão que acabar 
-- com uma instrução de RETURN. Neste formato de função, a instrução RETURN não tem qualquer parametro já que
-- a função se limitará a devolver a variavel definida em RETURNS
--
-- Ex. 1: o percurso profissional (curriculum) de funcionário
IF EXISTS (SELECT *
		   FROM   sys.objects
		   WHERE  object_id = OBJECT_ID(N'[HR].[ft_resume]')
				  AND type = N'TF')
	DROP FUNCTION [HR].[ft_resume];
GO

CREATE FUNCTION HR.ft_resume(@employee_id NUMERIC(3)) 
	RETURNS @resume TABLE(
		 EMPLOYEE_ID	NUMERIC(6)
		,START_DATE		DATE
		,END_DATE		DATE
		,JOB_ID			VARCHAR(10)
		,DEPARTMENT_ID	NUMERIC(4)
	)
	AS
	BEGIN
		IF EXISTS (SELECT JOB_ID FROM JOB_HISTORY WHERE EMPLOYEE_ID=@employee_id)
		BEGIN
			INSERT INTO @resume 
				SELECT EMPLOYEE_ID,START_DATE,END_DATE,JOB_ID,DEPARTMENT_ID 
					FROM JOB_HISTORY 
					WHERE EMPLOYEE_ID=@employee_id	
			INSERT INTO @resume 	
				SELECT	 EMPLOYEE_ID
						,(SELECT DATEADD(day,1,MAX(END_DATE)) FROM JOB_HISTORY WHERE EMPLOYEE_ID=@employee_id)
						,NULL
						,JOB_ID
						,DEPARTMENT_ID 
					FROM EMPLOYEES 
					WHERE EMPLOYEE_ID=@employee_id	
		END
		ELSE
			INSERT INTO @resume 
				SELECT EMPLOYEE_ID,HIRE_DATE,NULL,JOB_ID,DEPARTMENT_ID 
					FROM EMPLOYEES 
					WHERE EMPLOYEE_ID=@employee_id
		
		RETURN
	END -- function
GO 

-- MODO DE INVOCAÇÃO
-- Uma função vectorial também é invocada por SELECT, mas a proximidade com uma consulta simples à base de dados
-- é ainda maior uma vez que sendo o resultado uma tabela pode ser manipulado com uma relação da estrutura de dados 
-- a unica diferença relevante é o uso de () e parametros, quando aplicavel
-- 1.	invocação por SELECT
--		o uso de () distingue a chamada a uma função de uma consulta a uma tabela ou view
DECLARE @myEmployee NUMERIC(6) = 101
SELECT * FROM HR.ft_resume(@myEmployee)
SELECT * FROM HR.EMPLOYEES WHERE EMPLOYEE_ID=@myEmployee
SELECT * FROM HR.JOB_HISTORY WHERE EMPLOYEE_ID=@myEmployee

SELECT * FROM HR.ft_resume(101) ORDER BY START_DATE DESC

-- 		Para comparação, incluí-se o código da função num SELECT simples
SELECT	 f.EMPLOYEE_ID
		,e.FIRST_NAME
		,e.LAST_NAME 
		,f.START_DATE
		,f.END_DATE
		,(SELECT d.DEPARTMENT_NAME FROM HR.DEPARTMENTS d WHERE d.DEPARTMENT_ID=f.DEPARTMENT_ID) AS DEPARTMENT
		,(SELECT j.JOB_TITLE FROM HR.JOBS j WHERE j.JOB_ID=f.JOB_ID) AS JOB
	FROM	HR.ft_resume(101)  f JOIN 
			HR.EMPLOYEES e ON f.EMPLOYEE_ID=e.EMPLOYEE_ID

-- A tabela da função pode ser manipulada como qualquer outra tabela, incluindo junções, filtros, ordenações, agregações, etc.
-- Ex. 2: o percurso profissional com dados descritivos para função e departamento
--		  Exemplo demonstrativo, não optimizado. Seria mais correcto utilizar subqueires ou junções e tabela de devolução simplificada
IF EXISTS (SELECT *
		   FROM   sys.objects
		   WHERE  object_id = OBJECT_ID(N'[HR].[ft_resume]')
				  AND type = N'TF')
	DROP FUNCTION [HR].[ft_resume];
GO

CREATE FUNCTION HR.ft_resume(@employee_id NUMERIC(6)) 
/** historico completo do funcionário, incluindo a função actual **/
	RETURNS @resume TABLE(
		 EMPLOYEE_ID		NUMERIC(6)
		,START_DATE			DATE
		,END_DATE			DATE
		,JOB_ID				VARCHAR(10)
		,JOB_TITLE			VARCHAR(35)
		,DEPARTMENT_ID		NUMERIC(4)
		,DEPARTMENT_NAME 	VARCHAR(30)
	)
	AS
	BEGIN
		IF EXISTS (SELECT JOB_ID FROM JOB_HISTORY WHERE EMPLOYEE_ID=@employee_id)
		BEGIN
			INSERT INTO @resume (EMPLOYEE_ID,START_DATE,END_DATE,JOB_ID,DEPARTMENT_ID )
				SELECT EMPLOYEE_ID,START_DATE,END_DATE,JOB_ID,DEPARTMENT_ID 
					FROM JOB_HISTORY 
					WHERE EMPLOYEE_ID=@employee_id	
			INSERT INTO @resume (EMPLOYEE_ID,START_DATE,END_DATE,JOB_ID,DEPARTMENT_ID )
				SELECT	 EMPLOYEE_ID
						,(SELECT DATEADD(day,1,MAX(END_DATE)) FROM JOB_HISTORY WHERE EMPLOYEE_ID=@employee_id)
						,NULL
						,JOB_ID
						,DEPARTMENT_ID 
					FROM EMPLOYEES 
					WHERE EMPLOYEE_ID=@employee_id	
		END
		ELSE
			INSERT INTO @resume (EMPLOYEE_ID,START_DATE,END_DATE,JOB_ID,DEPARTMENT_ID )
				SELECT EMPLOYEE_ID,HIRE_DATE,NULL,JOB_ID,DEPARTMENT_ID 
					FROM EMPLOYEES 
					WHERE EMPLOYEE_ID=@employee_id
		
		UPDATE r
			SET JOB_TITLE = (SELECT j.JOB_TITLE FROM HR.JOBS j WHERE j.JOB_ID = r.JOB_ID)
			   ,DEPARTMENT_NAME = (SELECT d.DEPARTMENT_NAME FROM HR.DEPARTMENTS d WHERE d.DEPARTMENT_ID = r.DEPARTMENT_ID)
			FROM @resume r		
		RETURN 
	END -- function
GO 


SELECT	 f.EMPLOYEE_ID
		,e.FIRST_NAME
		,e.LAST_NAME 
		,f.START_DATE
		,f.END_DATE
		,f.JOB_TITLE
		,f.DEPARTMENT_NAME AS DEPARTMENT
	FROM	HR.ft_resume(101)  f JOIN 
			HR.EMPLOYEES e ON f.EMPLOYEE_ID=e.EMPLOYEE_ID
GO

-- 2.	invocação por atribuição
--		É possivel, mas requer que as variaveis de atribuição sejam tabelas com formato semelhante à resultante da função
--		Não tem grande aplicabilidade já que a função pode ser manipulada com grande flexibilidade como demonstrado a cima
--Ex. 1: atribuição do resultado da função a uma tabela temporária
CREATE TABLE #temp_resume (
		 EMPLOYEE_ID		NUMERIC(6)
		,START_DATE			DATE
		,END_DATE			DATE
		,JOB_ID				VARCHAR(10)
		,JOB_TITLE			VARCHAR(35)
		,DEPARTMENT_ID		NUMERIC(4)
		,DEPARTMENT_NAME 	VARCHAR(30)
);

INSERT INTO #temp_resume
	SELECT * FROM HR.ft_resume(101);

SELECT * FROM #temp_resume;	

-- OU
DROP TABLE #temp_resume;

SELECT 	 f.EMPLOYEE_ID
		,f.START_DATE
		,f.END_DATE
		,f.JOB_TITLE
		,f.DEPARTMENT_NAME 
	INTO #temp_resume
	FROM HR.ft_resume(1000) f;

SELECT * FROM #temp_resume;	

-- A atribuição directa do resultado de uma função vectorial a uma tabela temporária não é possível
SET #temp_resume = SELECT * FROM HR.ft_resume(101); -- ERRO
