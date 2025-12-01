/********************************************************************************
 * Aula 05														  30/09/2024 	*
 * LIG/LEI/LCD/LMC															 	*
 *																			 	*
 * DML: Filtros Horizontais (restrição de resultados):						 	*
 *			- WHERE																*
 *		Operadores lógicos													 	*
 *		Caso particulares:							 							*
 *			- Intervalos: BETWEEN												*
 *			- Semelhança (texto): LIKE											*
 *			- Conjuntos: IN														*
 *			- Tratamento de nulos												*
 *		Regular Expressions: REGEXP												*
 *		Condicional:															*
 *			- CASE/DECODE														*
 *			- (Só MS-SQL) In-line IF: IIF()										*
 ********************************************************************************/
USE ULHT_DB25;

SELECT * FROM hr.employees e ORDER BY e.HIRE_DATE;
-- Pesquisa de resaultados: WHERE
-- A clausula WHERE permite filtrar o resultado de um query por uma operação lógica, executada para cada linha
-- As linhas onde a operação seja avaliada como verdadeira são incluidas no resultado
-- Sintaxe base, v.2
-- SELECT «colunas»|* 
-- 		FROM «tabela»
-- 		[WHERE «condição»]
-- Onde:
-- «colunas» ::= «coluna» [«alias»]|«coluna» [«alias»],«colunas»
-- «condição» ::= qualquer operação lógica sobre colunas da tabela

-- Casos particulares
-- 1. Comparação por intervalos: BETWEEN 
SELECT * FROM hr.employees 
	WHERE SALARY BETWEEN 2500 AND 5000
	ORDER BY SALARY; 

-- Pode-se inverter o intervalo utilizando a negação: NOT
SELECT * FROM hr.employees 
	WHERE SALARY NOT BETWEEN 2500 AND 5000
	ORDER BY SALARY; 

-- Notar que o BETWEEN inclui os intervalos 
-- o query acima é equivalente a:
SELECT * FROM hr.employees 
	WHERE NOT(SALARY >= 2500 AND SALARY <= 5000); 

SELECT * FROM hr.employees e 
	WHERE SALARY NOT = 2500; -- > ERRO
-- Correcto
SELECT * FROM hr.employees e 
	WHERE NOT(SALARY = 2500);
-- OU
SELECT * FROM hr.employees e 
	WHERE SALARY <> 2500;	
	

SELECT * FROM hr.employees 
	WHERE SALARY >= 2500 AND <= 5000; -- erro!! 
	    								-- cada operação logica tem que indicar ambos os operandos

-- 3. Pesquisa em conjuntos: IN
-- 	Entenda-se conjunto como grupo discreto de valores
-- pesquisa por intervalo pode utilizar conjuntos de valores discretos: IN
SELECT DISTINCT e.DEPARTMENT_ID FROM hr.employees e 
	WHERE e.DEPARTMENT_ID IN (10,30,50);

-- ex.: funcionários dos departamentos 10 e 50
SELECT * FROM hr.employees e 
	WHERE e.DEPARTMENT_ID IN (10,50);

-- A função IN tem um uso mais corrente, o de permitir comparar com outras tabelas/grupos: SUBQUERIES
-- IN Com subqueries:
SELECT * FROM hr.employees e 
	WHERE e.DEPARTMENT_ID IN (SELECT DISTINCT e2.DEPARTMENT_ID 
								FROM hr.employees e2 
								WHERE e2.DEPARTMENT_ID BETWEEN 10 AND 50);

-- Os subqueries são uma ferramenta muito importante do SQL por permitirem reverter a normalização
-- e podem ser colocados em vários locais numa instrução: Num filtro (ou restrição horizontal); ou utilizados com uma função de linha
-- em projecção (ou restrição vertical):
-- Subquery de substituição							
SELECT e.FIRST_NAME, e.DEPARTMENT_ID
		,(SELECT d.DEPARTMENT_NAME FROM hr.departments d WHERE d.DEPARTMENT_ID = e.DEPARTMENT_ID) AS departamento
	FROM hr.employees e		
	WHERE e.DEPARTMENT_ID IN (SELECT DISTINCT e2.DEPARTMENT_ID 
								FROM hr.employees e2 
								WHERE e2.DEPARTMENT_ID BETWEEN 10 AND 50);					

-- 4. Nulidade: IS NULL
SELECT * FROM hr.employees e;

-- 	ex.: verificar funcionários sem chefia
SELECT * FROM hr.employees e 
	WHERE e.MANAGER_ID IS NULL;
-- É importante perceber que, em filtros, o <NULL> é tratado como um objecto e não como um valor
-- A operação de comparação '=' irá resultar em erro...
-- ... na realidade não é bem um erro, a comparação será feita com o literar NULL e não com a nulidade
SELECT * FROM hr.employees e 
	WHERE e.MANAGER_ID = NULL;

-- 5. Filtros com funções de linha
-- À imagem do que viu na aula anterior, também se pode utilizar funções de linha em filtros
-- ex.: funcionário com indicativo telefone 515
SELECT * FROM hr.employees e 
	WHERE LEFT(e.PHONE_NUMBER,3) = '515';

SELECT * FROM hr.employees e 
	WHERE LEN(CONCAT(e.LAST_NAME,'.',e.FIRST_NAME,'@empresa.com')) > 25;

-- Filtros de texto: LIKE
-- O SQL permite utiização de operadores de texto para pesquisa mais rica: FULL TEXT SEARCH
-- Além de operadores, utilizam-se carateres especiais para substiuição de texto: Wildcards
-- 	Wildcards mais comuns:
-- 		'%' - Qualquer conjunto de caracteres
-- ex.: funcionários com apelido iniciado por 'S'
SELECT * FROM hr.employees e
	WHERE e.LAST_NAME LIKE 's%';

-- ex.: funcionários com 'S' no apelido, em qualquer posição
SELECT * FROM hr.employees e
	WHERE e.LAST_NAME LIKE '%s%';

-- 		'_' - substitui um único caracter
-- ex.: funcionários com 'O' na segunda letra do apelido
SELECT * FROM hr.employees e
	WHERE e.LAST_NAME LIKE '_o%';

SELECT * FROM hr.employees e
	WHERE e.LAST_NAME LIKE '%o%';

SELECT * FROM hr.employees e
	WHERE e.LAST_NAME LIKE '% %';

SELECT * FROM hr.employees e
	WHERE e.JOB_ID LIKE '%\_%' ESCAPE '\'; 
-- Em MySQL, omite-se a indicação explicita do caracter de escape, sendo o '\' o caracter padrão para escape
-- SELECT * FROM hr.employees e:
-- 	WHERE e.LAST_NAME LIKE '%\_%';

-- procurar o caracter "'"
SELECT * FROM hr.employees e
	WHERE e.LAST_NAME LIKE '%''''%';

-- ex.: funcionários com 'O' na terceira letra do apelido
SELECT * FROM hr.employees e
	WHERE e.LAST_NAME LIKE '__o%';
 
-- Regular Expressions (REGEXP)
-- 	REGEXP são expresões avançadas de pesquisa de texto que permite regras mais complexas,
-- 	comparando com padrões, que podem ser utilizados em filtro de texto complexos
-- 
-- 	Na sua forma mais simples de MSSQL, desigan-se por REGEXP a aplicação de padrões de pesquisa complexa em filtros
-- 	No entanto, continua a utilizar-se o operador LIKE, ao contrario de outras implementações (e.g. MySQL) onde existe o operador REGEXP
-- 	ex.: funcionários com nome iniciado por 'R','S' ou 'T' 
SELECT * FROM hr.employees e
	WHERE e.LAST_NAME LIKE '[rst]%';
-- equivale a:
SELECT * FROM hr.employees e
	WHERE e.LAST_NAME LIKE 'r%' OR e.LAST_NAME LIKE 's%' OR e.LAST_NAME LIKE 't%';
-- OU
SELECT * FROM HR.EMPLOYEES ELSE

-- equivalente a:
SELECT * FROM hr.employees e
	WHERE e.LAST_NAME LIKE 'r%' OR e.LAST_NAME LIKE 's%' OR e.LAST_NAME LIKE 't%';

-- Em MSSQL, mantém-se o operador '%' para designar cadeias de caracteres omissos
-- O padrão permite multiplas comparações numa única operação, mas não substitui o operador elementar 'LIKE'
-- Mais uma vez, o comportamente é diferente noutras implementações (e.g. MySQL), onde os wildcards são substituidos por operandos (como o '^')
-- ex.: a instrução acima teria a seguinte sintaxe em MySQL para o mesmo resultado
--		SELECT * FROM hr.employees e
--			WHERE e.LAST_NAME REGEXP '^[rst]';
--		onde ^ designa iníco do texto

-- O uso de Regular Expressions em MSSQL é bastante limitado quando comaprado com o operador REGEXP de MySQL (e outros)
-- No entanto, o MSSQL tem funções próprias de Regular Expressions com capacidade bastante mais elevada e flexivel
-- Função mais comum: REGEXP_LIKE
-- 		Sintaxe: (...) WHERE REGEXP_LIKE(«valor»,«padrão»)
-- ex.: O código anterior passa a ser
SELECT * FROM hr.employees e
	WHERE REGEXP_LIKE(e.LAST_NAME REGEXP,'^[rst]');
-- Infelizmente, esta função só está disponível a partir do SQL 2025 (v.17), posterior à que estamos a utilizar	

-- As funções REGEXP não contêm apenas o _LIKE, são um conjunto que permitem manipulação avançada de texto,
-- podendo mesmo ser utilizadas como parte do SELECT para verificar se um texto obedece ao padrão
-- (Neste caso, o query responderá TRUE (1) se o padrão for cumprido ou FALSE (0) caso contrário)
-- ou para fazer substituições em linha
-- ex.: verificar apelidos com 8 caracteres de cumprimento	
 SELECT e.LAST_NAME, REGEXP_INSTR(e.LAST_NAME, '^[a-z]{8}') FROM hr.employees e; 	
	
-- Mais sobre regular expressions em: 	MySQL	https://dev.mysql.com/doc/refman/8.0/en/regexp.html#regexp-syntax
-- 										MariaDB	https://mariadb.com/kb/en/regular-expressions-functions/	
--										MS-SQL	https://learn.microsoft.com/en-us/sql/ssms/scripting/search-text-with-regular-expressions?view=sql-server-ver16

-- Exemplos mais completos para regular expression com LIKE
-- Verificar se um endereço email está correcto
SELECT * FROM HR.EMPLOYEES
	WHERE EMAIL NOT LIKE '%[A-Z0-9][@][A-Z0-9]%[.][A-Z0-9]%'

-- Verificar nome com espaços (para não gerar endereços de email errado)
-- como o MSSQL não suporte nativamente a comparação para REGEXP na versão utilizada, a resposta não é simples...
-- Podes-se utilizar uma comparação composta:
-- WHERE
--    «password» LIKE '%[a-zA-Z0-9]%' AND
--    «password» LIKE '%[~!@#$%^&*()_+-={}\[\]:"|\;,./<>?'']%' ESCAPE '\' AND
--    LEN(«password») BETWEEN 8 AND 20;
--
-- O mais correcto, no entanto, será utilizar código externo - CLR (Common Language Runtime)

-- Verificar se ua password tem letra minuscula, maiuscula, numero e caracter especial
SELECT * FROM HR.EMPLOYEES
	WHERE EMAIL NOT LIKE '%[A-Za-z0-9]%'	
	
-- Uso de condicionais
-- 1. IIF (inline IF)
SELECT 	e.EMPLOYEE_ID,
		e.FIRST_NAME, 
		e.LAST_NAME, 
		e.EMAIL, 
		IIF(e.MANAGER_ID IS NULL,'@administracao.com','@empresa.pt') AS dominio,
		e.MANAGER_ID,
		e.HIRE_DATE,
		e.SALARY, 
		e.COMMISSION_PCT 
	FROM hr.employees e ;
-- o INLINE IF, ou IIF, utilizado é uma função de linha não CONTROLO DE FLUXO
-- Sintaxe IIF: 
-- 	IIF(«condição»,«resultado_se_v»,«resultado_se_f»)
-- 	O Inline IF produzirá sempre 1 e apenas 1 resultado
-- 
--  Em MySQL a função tem apenas o IF(), mas a restante sintaxe é idêntica
-- 	Em Oracle não existe inline IIF, em sua substituição tem a função DECODE() que funciona como um CASE simplificado
-- SINTAXE:
-- 		DECODE(«expressao»,
-- 					«hipotese_1»,«resultado_1»,
-- 					...
-- 					«resultado_alternativo»)

-- 2. CASE: opções discretas
SELECT 	 EMPLOYEE_ID  as numero
		,last_name + ', ' + FIRST_NAME AS full_name 
		,lower(email) + '@empresa.com' as email
		,LOWER(LEFT(FIRST_NAME,1)+'.'+LAST_NAME) + '@empresa.pt' AS email
		,HIRE_DATE 
		,JOB_ID 
		,DEPARTMENT_ID 
		,SALARY as 'vencimento base'
		,SALARY  * (1+COMMISSION_PCT) AS 'vencimento bruto'
		,CASE ISNULL(COMMISSION_PCT,0)
			WHEN 0 THEN SALARY 
			ELSE SALARY * (1 + COMMISSION_PCT)
		 END AS 'vencimento'
		,IIF(COMMISSION_PCT IS NULL,SALARY,SALARY * (1+COMMISSION_PCT)) AS vencimento
	FROM hr.employees;
	
-- Sintaxe CASE
-- v.1
-- CASE «condition»
-- 		WHEN «H1» THEN «R1»
-- 		[WHEN «H2» THEN «R2»]
-- 		...
-- 		[WHEN «Hn» THEN «Rn»]
-- 		[ELSE «RDefault»]
-- END
-- O resultado de «condição» terá que ser sempre discreto
-- 
-- v.2
-- CASE
-- 		WHEN «condition_1» THEN «R1«
-- 		[WHEN «condition_2» THEN «R2»]
-- 		...
-- 		[WHEN «condition_n» THEN «Rn»]
-- 		[ELSE «RDefault»]
-- END
-- 
-- Tem que ter sempre pelo menos 1 hipotese válida ou produzirá erro
-- O CASE tem que ser sempre terminado com 'END' em ambas as versões 
-- Também em ambas as versões, o CASE produzirá sempre 1 e apenas 1 resultado.
-- Caso mais do que uma da opções for avaliada como V, é devolvido a primeira encontrada

/********************************************************************************************
 * EXTRA: Inserir dados a partir de consultas												*
 ********************************************************************************************/
-- 1. em tabela nova
SELECT 	 EMPLOYEE_ID  as numero
	,last_name + ', ' + FIRST_NAME AS full_name 
	,LOWER(LEFT(FIRST_NAME,1)+'.'+LAST_NAME) + '@empresa.pt' AS email
	,FORMAT(HIRE_DATE,'dd/MM/yyyy') as 'contratação'
	,JOB_ID 
	,DEPARTMENT_ID 
	,SALARY as 'vencimento base'
	,CASE ISNULL(COMMISSION_PCT,0)
		WHEN 0 THEN SALARY 
		ELSE SALARY * (1 + COMMISSION_PCT)
	 END AS 'vencimento'
INTO hr.new_employee 		--> a tabela hr.new_employee será criada de raiz
							--> ERRO se a tabela já existir
FROM hr.employees e
WHERE e.EMPLOYEE_ID  <=150;

-- validar criação e inserção
SELECT * FROM hr.new_employee ORDER BY numero;

-- apagar conteúdos
DELETE FROM hr.new_employee;
-- Aproveitar para verificar a irreversibilidade da acção...
-- ... mas também do SELECT ... INTO para uma tabela existente

-- Apagar a tabela
DROP TABLE hr.new_employee;
-- Ainda mais irreversível que a anterior!

-- 2. Numa tabela existente
INSERT INTO hr.new_employee (numero,full_name,email,job_id,department_id,"vencimento base",[vencimento bruto],vencimento)
	SELECT 	 EMPLOYEE_ID  as numero
		,last_name + ', ' + FIRST_NAME AS full_name 
		,lower(email) + '@empresa.com' as email
		,JOB_ID 
		,DEPARTMENT_ID 
		,SALARY as 'vencimento base'
		,IIF(COMMISSION_PCT IS NULL,SALARY,SALARY * (1+COMMISSION_PCT)) AS vencimento
	FROM hr.employees
	WHERE employee_id > 150;

-- variante sem indicação explicita de colunas
-- ... a regra de paridade mantém-se!
INSERT INTO hr.new_employee
	SELECT 	 EMPLOYEE_ID  as numero
		,last_name + ', ' + FIRST_NAME AS full_name 
		,lower(REPLACE(email,' ','')) + '@empresa.com' as email
		,FORMAT(HIRE_DATE,'dd/mm/yyyy') 
		,JOB_ID 
		,DEPARTMENT_ID 
		,SALARY as 'vencimento base'
		,IIF(COMMISSION_PCT IS NULL,SALARY,SALARY * (1+COMMISSION_PCT)) AS vencimento
	FROM hr.employees;
-- 	WHERE employee_id NOT IN (SELECT numero FROM new_employee);	

-- Tentar executar o INSERT ... SELECT em tabela inexistente
DROP TABLE hr.new_employee;

-- NOTA:
-- O mecanismos SELECT ... INTO e INSERT ... FROM têm sintaxes diferentes consoante a implementação
-- A sintaxe para outras implementações está fora do âmbito da disciplina