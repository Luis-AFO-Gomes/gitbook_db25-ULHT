/*****************************************************************************
 * Aula 03														  25/09/2024 *
 * LIG/LEI/LCD/LMC															 *
 *																			 *
 * DML: Operações de linha: 												 *
 *			- texto															 *
 *			- Aritméticas													 *
 *			- Datas															 *
 *		Literais															 *
 *		Tratamento de nulos	(diferença MySQL/MSSQL)							 *
 *		Formatação (diferençaa MySQL/MSSQL)									 *
 *		Conversão entre tipos de dados										 *
 *****************************************************************************/
 use ULHT_DB25;

SELECT * FROM information_schema.columns c WHERE c.table_name = 'emp';

-- operações com texto
SELECT * FROM hr.employees;

-- Projecção ou filtro vertical
SELECT e.first_name, e.last_name FROM hr.EMPLOYEES e;

SELECT CONCAT(last_name, ', ', FIRST_NAME) AS full_name FROM hr.employees;
-- CONCAT é uma função de linha
-- Funções de linha, ou operações de linha, aplicam-se na definição de resultados, i.e., como parte do SELECT

SELECT LOWER(e.EMAIL + '@empresa.com') FROM hr.employees e;
SELECT LOWER(LEFT(e.FIRST_NAME,1)+ e.LAST_NAME + '@empresa.com') FROM hr.employees e;

-- limitação com '+' alfabética
SELECT e.EMPLOYEE_ID +'.'+ LOWER(e.EMAIL + '@empresa.com') FROM hr.employees e; --> Erro, não podem existir tipos diferentes
SELECT CAST(e.EMPLOYEE_ID AS VARCHAR(4)) +'.'+ LOWER(e.EMAIL + '@empresa.com') FROM hr.employees e; --> CORRECTO
SELECT CAST(e.EMPLOYEE_ID AS VARCHAR(3)) +'.'+ LOWER(e.EMAIL + '@empresa.com') FROM hr.employees e;

-- '' representa um litearl/string a ser incluido AS-IS no resultado

-- EXTRA: Operações com texto - Concatenação como junção lógica (|| - OR)
-- 		  || não deixa de ser um operador lógico/aritmético


SELECT last_name + ', ' + FIRST_NAME AS full_name FROM hr.employees;
-- MySQL: SELECT last_name || ', ' || FIRST_NAME AS full_name FROM hr.employees;
-- 
-- Pode ser necessário manipular variaveis de sistema:
-- ex.: sql_mode
-- SHOW variables LIKE 'sql_mode';

-- SET sql_mode = PIPES_AS_CONCAT;

-- Operações de linha com texto
-- ex.: LEFT; RIGHT; LOWER; UPPER
SELECT LEFT(first_name,1),LOWER(last_name) FROM HR.EMPLOYEES;

-- uso acumulado de funções de linha
SELECT LOWER(LEFT(first_name,1) + '.' + last_name) AS funcionario FROM HR.employees;

-- Outras funções interessantes: LENGHT(), SUBSTRING(), POSITION(), REPLACE()
-- funções de texto em MS-SQL: https://learn.microsoft.com/en-us/sql/t-sql/functions/string-functions-transact-sql?view=sql-server-ver17
-- funções de texto em MySQL: https://dev.mysql.com/doc/refman/8.0/en/string-functions.html

-- operações numericas
-- muito simples...
SELECT 1 + 1;

-- NOTA: Oracle não pemite SELECT sem tabela, para contornar esta limitação disponibiliza uma tabela ficticia: DUAL 
-- 		SELECT 1 + 1 FROM DUAL;

-- operações com colunas: Calculo de vencimento
-- 1. vencimento base
SELECT * FROM HR.employees e;

SELECT 	 EMPLOYEE_ID  as numero
		,last_name + ', ' + FIRST_NAME AS full_name 
		,MANAGER_ID 
		,JOB_ID 
		,DEPARTMENT_ID 
		,SALARY as 'vencimento base'
		,COMMISSION_PCT as 'comissão'
	FROM hr.employees;

-- 2. comissão
SELECT 	 EMPLOYEE_ID  as numero
		,last_name + ', ' + FIRST_NAME AS full_name 
		,JOB_ID 
		,DEPARTMENT_ID 
		,SALARY as 'vencimento base'
		,COMMISSION_PCT as 'comissão'
		,SALARY * (1+COMMISSION_PCT) as 'vencimento total'
	FROM hr.employees;
--	WHERE COMMISSION_PCT IS NOT NULL; -- filtrar para funcionários sem comissão
-- o que se passa com o vencimento total?


-- simples: NULL
-- NULL é 'O' elemeto absorvente na algebra relacional, qualquer operação com NULL tem resultado NULL
-- Como resolver? ISNULL
-- SINTAXE
-- 	IFNULL(«expressão»,«valor_se_NULL»)
SELECT 	 EMPLOYEE_ID  as numero
		,last_name + ', ' + FIRST_NAME AS full_name 
		,JOB_ID 
		,DEPARTMENT_ID 
		,SALARY as 'vencimento base'
		,COMMISSION_PCT
		,ISNULL(COMMISSION_PCT,0) as 'comissão'
		,SALARY * (1+ISNULL(COMMISSION_PCT,0)) as 'vencimento total'
		,ISNULL(SALARY*COMMISSION_PCT,SALARY)
	FROM hr.employees
--	WHERE COMMISSION_PCT = NULL; --> Não erro, mas não funciona
	WHERE COMMISSION_PCT IS NULL; --> CORRECTO
-- No caso de se testarem mais de 2 valores, utiliza-se função COALESCE()

-- NOTA: ISNULL() só funciona em MySQL
-- 		MS-SQL/PostGreSQL: ISNULL()
-- 		ORACLE: NVL()

-- Alternativa ISNULL: COALESCE
 
-- 3. resultados ordenados por vencimento
SELECT 	 EMPLOYEE_ID  as numero
		,last_name + ', ' + FIRST_NAME AS full_name 
		,JOB_ID 
		,DEPARTMENT_ID 
		,SALARY as 'vencimento base'
		,ISNULL(COMMISSION_PCT,0) as 'comissão'
		,SALARY * (1+ISNULL(COMMISSION_PCT,0)) as 'vencimento total'
	FROM hr.employees
	ORDER BY salary;
-- não é um resultado muito correcto... no sentido em que a ordem não é a de venvimento real
-- deve-se utilizar a expressão completa na ordenação
SELECT 	 EMPLOYEE_ID  as numero
		,last_name + ', ' + FIRST_NAME AS full_name 
		,JOB_ID 
		,DEPARTMENT_ID 
		,SALARY as 'vencimento base'
		,ISNULL(COMMISSION_PCT,0) as 'comissão'
		,SALARY * (1+ISNULL(COMMISSION_PCT,0)) as 'vencimento total'
	FROM hr.employees
	ORDER BY "vencimento total" DESC;
-- NOTA: o uso de alias de colunas para ordenação tem comportmento diferente consoante a implementação
--		 Por exemplo, no MySQL não aceita ordenação por alias, terá que se utilizar a expressão de calculo

-- outra possibilidade é utilizar a ordem das colunas
SELECT 	EMPLOYEE_ID  as numero
		,last_name + ', ' + FIRST_NAME AS full_name 
		,JOB_ID 
		,DEPARTMENT_ID 
		,SALARY as 'vencimento base'
		,ISNULL(COMMISSION_PCT,0) as 'comissão'
		,SALARY * (1+ISNULL(COMMISSION_PCT,0)) as 'vencimento total'
	FROM hr.employees
	ORDER BY 7;

-- Ordem decrescente: DESC
SELECT 	 EMPLOYEE_ID  as numero
		,last_name + ', ' + FIRST_NAME AS full_name 
		,JOB_ID 
		,DEPARTMENT_ID 
		,SALARY as 'vencimento base'
		,ISNULL(COMMISSION_PCT,0) as 'comissão'
		,SALARY * (1+ISNULL(COMMISSION_PCT,0)) as 'vencimento total'
	FROM hr.employees
	ORDER BY SALARY * (1+ISNULL(COMMISSION_PCT,0)) DESC, COMMISSION_PCT ASC;

-- funções matemáticas em MS-SQL: https://learn.microsoft.com/en-us/sql/t-sql/functions/mathematical-functions-transact-sql?view=sql-server-ver17
-- operadores aritméticos em MS-SQL:https://learn.microsoft.com/en-us/sql/t-sql/language-elements/arithmetic-operators-transact-sql?view=sql-server-ver17
-- funções e operadores numéricos em MySQL: https://dev.mysql.com/doc/refman/8.0/en/numeric-functions.html

-- operações com datas: diferença de datas
SELECT 	 EMPLOYEE_ID  as numero
		,last_name + ', ' + FIRST_NAME AS full_name 
		,JOB_ID 
		,DEPARTMENT_ID 
		,HIRE_DATE 
		,DATEDIFF(day,GETDATE(),HIRE_DATE) 
	FROM hr.employees;

SELECT SYSDATETIME();	--> OU SYSDATETIME()
						-- Outros formatos:
						--	GETDATE(): Apenas data
						--	CURRENT_TIMESTAMP: Maior precisão
-- Em MySQL: SELECT CAST(CURDATE() AS DATETIME);  	
-- funções com data em MS-SQL: https://learn.microsoft.com/en-us/sql/t-sql/functions/date-and-time-data-types-and-functions-transact-sql?view=sql-server-ver16
-- funções com data em MySQL: https://dev.mysql.com/doc/refman/8.0/en/date-and-time-functions.html	

-- Conversões: CAST
-- Juntar tipos de dados diferentes	
SELECT 	 EMPLOYEE_ID  as numero
		,last_name + ', ' + FIRST_NAME AS full_name
		,LOWER(LEFT(first_name,1) + '.' + last_name) + EMPLOYEE_ID  AS sigla 
	FROM hr.employees;
-- havendo compatibilidade de tipo, o SQL opera conversão implicita
-- Mas nem sempre funciona...
-- Nalguns casos, é necessária conversão explicita

-- O correcto é utilizar conversão explicita
SELECT 	 EMPLOYEE_ID  as numero
		,last_name + ', ' + FIRST_NAME AS full_name
		,LOWER(LEFT(first_name,1) + '.' + last_name) + CAST(EMPLOYEE_ID AS VARCHAR(3))  AS sigla 
	FROM hr.employees;
-- Oracel: TO_???
	
/**	
 * formatar saida: FORMAT() et al.
 */
-- As funções de formatação podem assumir comportamentos muito diferentes entre implementações
-- embora utilizem a mesma função: FORMAT
--
-- Ex.: 
-- Em MySQL, a função FORMAT() apenas formata numeros para formato padrão
-- SELECT 	 EMPLOYEE_ID  as numero
-- 			,last_name + ', ' + FIRST_NAME AS full_name 
--			,JOB_ID 
--			,DEPARTMENT_ID 
--			,FORMAT(SALARY,2) as 'vencimento base'
--			,FORMAT(ISNULL(COMMISSION_PCT,0),2) as 'comissão' --> coloca 2 casas decimais no resultado
--			,SALARY * (1+ISNULL(COMMISSION_PCT,0)) as 'vencimento total'
--		FROM hr.employees
--		ORDER BY SALARY * (1+ISNULL(COMMISSION_PCT,0)) DESC;

-- Em MS-SQL, a função FORMAT() permite ajustes culturais ou uso de máscaras de formatação
-- No entanto para reproduzir a formatação do exemplo anterior de MySQL, a função correcta é STR()
SELECT 	 EMPLOYEE_ID  as numero
		,last_name + ', ' + FIRST_NAME AS full_name 
		,JOB_ID 
		,DEPARTMENT_ID 
		,STR(SALARY,6,2) as 'vencimento base'
		,STR(ISNULL(COMMISSION_PCT,0),6,2) as 'comissão' --> coloca 2 casas decimais no resultado
		,FORMAT(SALARY * (1+ISNULL(COMMISSION_PCT,0)),'C','pt-pt') as 'vencimento total'
	FROM hr.employees
	ORDER BY SALARY * (1+ISNULL(COMMISSION_PCT,0)) DESC;
-- SINTAX FORMAT(): https://learn.microsoft.com/en-us/sql/t-sql/functions/format-transact-sql?view=sql-server-ver17
-- SINTAX STR(): https://learn.microsoft.com/en-us/sql/t-sql/functions/str-transact-sql?view=sql-server-ver17

-- Há outras funções que podem ser utilizadas para formatar e facilitar a legibilidade  
-- ex.: Padding (preencher espaços com caracter específico)
SELECT 	 EMPLOYEE_ID  as numero
		,last_name + ', ' + FIRST_NAME AS full_name
		,LOWER(LEFT(first_name,1) + '.' + last_name) + RIGHT(REPLICATE('0',4)+CAST(EMPLOYEE_ID AS VARCHAR(4)),4) AS sigla 
	FROM hr.employees;
-- O padding em MS-SQL tem alguma complexida, não há preenchimento directo do espaço, pelo que se recorre a várias funções:
-- REPLICATE(«string»,«repetições») -- repete «string» «repetições» vezes
--									-- «string»	pode ter mais do que um caracter
-- CAST(«numero» to VARCHAR(«len»)) -- converte «numero» para uma string/VARCHAR de comprimento máximo «len»
--									-- Tem que existir conversão para string para que a concatenação funcione
-- RIGHT(«string»,«len») 	-- trunca «string» aos «len» caracteres à direita
--							-- também existe a função LEFT()

-- Em MySQL é bastante mais simples, há funções próprias: LPAD() e RPAD()
-- SELECT 	 EMPLOYEE_ID  as numero
--			,last_name + ', ' + FIRST_NAME AS full_name
--			,LOWER(LEFT(first_name,1) + '.' + last_name) + LPAD(CAST(EMPLOYEE_ID AS VARCHAR(3)),4,0)  AS sigla 
--		FROM hr.employees;
	
-- LPAD também pode ser utilizado com texto (embora possa não fazer grande sentido...)	
--	SELECT 	 EMPLOYEE_ID  as numero
--			,last_name + ', ' + FIRST_NAME AS full_name
--			,UPPER(LEFT(first_name,1) + '.' + RPAD(last_name,11,'_')) + LPAD(CAST(EMPLOYEE_ID AS VARCHAR(3)),4,0)  AS sigla 
---		FROM hr.employees;

-- LPAD: https://dev.mysql.com/doc/refman/8.0/en/string-functions.html#function_lpad	

/**
 * Substituição de texto: REPLACE()
 */
SELECT (lower(REPLACE(last_name,' ','_') + '.' + REPLACE(first_name,' ','') + '@empresa.com'))  
	FROM HR.employees e 
	WHERE last_name LIKE '% %';
	
