/********************************************************************************
 * Aula 05-2														  			*
 * LIG/LEI/LCD/LMC															 	*
 *																			 	*
 * DML: Fun��es de grupo e Agrupamento											*
 *		- GROUP BY																*
 *		Filtro de Agrega��o														*
 *		- HAVING																*
 *		Opera��es de conjunto													*
 *		- UNION, INTERSECT e MINUS												*
 ********************************************************************************/
 USE ULHT_DB25;

-- Fun��es de grupo
-- Ao contr�rio do que se tem visto at� ao momento, fun��es e opera��es sobre linhas
-- as fun��es de grupo aplicam-se � globalidade de um tabela/rela��o
-- As fun��es mais comuns s�o estat�sticas, mas podem ser de tipo mais geral  

-- Come�ar por calculo de vencimento de 1 funcionário e progredir para an�lises estatisticas
SELECT 	e.EMPLOYEE_ID,
		e.FIRST_NAME, 
		e.LAST_NAME, 
		LOWER(e.EMAIL + IIF(e.MANAGER_ID IS NULL,'@administracao.com','@empresa.pt')) AS email,
		DATE_FORMAT(e.HIRE_DATE,'hired on %W,%Y %M %D') as data,
		e.SALARY As 'base', 
		e.COMMISSION_PCT,
		e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0)) as vencimento
	FROM hr.employees e ;

-- Query simples, apenas com dados necess�rios para a an�lise
SELECT 	e.SALARY As 'base', 
		e.COMMISSION_PCT,
		e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0)) as vencimento
	FROM hr.employees e ;	

SELECT * FROM hr.employees e;

-- estatistica geral: dados gerais de funcionários	
SELECT 	e.EMPLOYEE_ID , -- DISTINCT 
		AVG(e.SALARY) As 'média base', 
		MIN(e.SALARY) As 'minimo base', 
		MAX(e.SALARY) As 'máximo base', 
		SUM(e.SALARY)/COUNT(e.EMPLOYEE_ID),
		COUNT(e.employee_id)
	FROM hr.employees e ;	

-- Juntar fun��es de linha com fun��es de grupo
SELECT 	AVG(e.SALARY) As 'média base', 
		MIN(e.SALARY) As 'minimo base', 
		MAX(e.SALARY) As 'máximo base', 
		AVG(e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0))) as 'média vencimento',
		IFNULL(AVG((e.SALARY * e.COMMISSION_PCT)),0) as 'média vencimento',
		COUNT(e.employee_id)
	FROM hr.employees e
-- trabalhando com agrupamento, � essencial que cada linha produza apenas um resultado
-- o que � garantido com a fun��o AVG()
-- Ambas as situa��es acima funcionam, mas n�o produzem o mesmo resultado...	

-- Caso particular de IFNULL 	
SELECT 	AVG(e.SALARY) As 'média base', 
		MIN(e.SALARY) As 'minimo base', 
		MAX(e.SALARY) As 'máximo base', 
		AVG(e.COMMISSION_PCT) as 'comissão',          	-- em MySQL n�o utilisar IFNULL 
														-- faz a média apenas com os valores preenchidos
		AVG(IFNULL(e.COMMISSION_PCT,0)) as 'comissão',	-- � diferente da linha anterior
		AVG(e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0))) as 'média vencimento',
		COUNT(e.employee_id),
		COUNT(COMMISSION_PCT),
		COUNT(*)
	FROM hr.employees e; 

-- em MySQL, os query permitem o uso de colunas com valores distintos em queries com agrupamento, 
-- mas o resultado n�o tem significado v�lido ou coerente com as fun��es de grupo 
SELECT 	e.department_id, 
		FORMAT(AVG(e.SALARY),2) As 'média base', 
		MIN(e.SALARY) As 'minimo base', 
		MAX(e.SALARY) As 'máximo base', 
		e.COMMISSION_PCT,
		FORMAT(AVG(e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0))),2) as 'média vencimento',
		COUNT(e.employee_id)
	FROM hr.employees e	
-- [e].[department_id] ir� apresentar o valor da coluna na primeira linha da tabela utilizada no query, sem qualquer agrupamento
-- 
-- Noutras implement��es - MS-SQL, Oracle - esta sintaxe ir� produzir erro de concord�ncia 
-- Num query com agrupamento, todas as colunas t�m que estar agrupadas - fun��o de grupo - ou serem agregadores - v. � frente	
	
SELECT * FROM hr.employees e;
	
-- estatistica por departamento	
-- Agrupamento: GROUP BY
SELECT  e.department_id, 
		e.EMPLOYEE_ID,
		AVG(e.SALARY) As 'média base', 
		MIN(e.SALARY) As 'minimo base', 
		MAX(e.SALARY) As 'máximo base', 
		AVG(e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0))) as 'média vencimento',
		COUNT(e.employee_id) AS '# funcionario'
	FROM hr.employees e
	GROUP BY e.department_id;
-- o GROUP BY cria subconjuntos sob o dom�nio do query, aplicando isolamente as fun��es de grupo a cada conjunto 
-- Nesta sintaxe, a coluna [e].[department_id] n�o ir� produzi erro uma vez que � referida no GROUP BY, o que � uma forma de agrupamento 
-- A omiss�o do GROUP BY leva a que as fun��es ejam aplicadas � totalidade da tabela

-- NOTA
-- � preciso ter em conta a nomenclatura
-- . Fun��o de grupo: 	fun��es que trabalham sobre tabelas ou subgrupos de linhas
-- 						AVG(), COUNT(), etc
-- 						DISTINCT 
-- 						- N�o � uma fun��o, antes um operador que elimina duplicados
-- 						  Apresenta apenas uma ocorr�ncia de um valor que se pode repetir na tabela
-- . Agrupamento:		par�metro do query que define modo de agrupar linhas
-- 						GROUP BY

-- Restri��es sint�ticas
-- 1. 	Todos as colunas do query (SELECT) t�m que ter uma fun��o de grupo (podem estar opera��o dentro da fun��o)
-- 		ou estar no par�metro de agrupamento
-- 2.	A regra anterior tamb�m se aplicar em filtro (WHERE) ou ordena��o (ORDER BY)

-- Agrega��o: utilizar agrupamentos diferentes da tabela completa
-- contagem de funcionários por fun��o
SELECT job_id,COUNT(employee_id) FROM hr.employees
        GROUP BY job_id;
        
-- vencimento m�dio por fun��o       
SELECT job_id,AVG(salary) FROM hr.employees
        GROUP BY job_id;

-- contagem de funcionários por chefia       
SELECT manager_id,COUNT(employee_id) FROM hr.employees
        GROUP BY manager_id;

-- contagem de funcionário por chefia, indicando o nome do chefe       
SELECT	 IFNULL(CAST(manager_id AS VARCHAR(10)),'patrão') as "chefe"
        ,COUNT(employee_id) AS '# funcionário'
	FROM hr.employees 
	GROUP BY manager_id;

-- O GROUP BY pode utilizar fun��es
SELECT 	e.COMMISSION_PCT,COUNT(*)
	FROM hr.employees e
	GROUP BY (IIF(e.COMMISSION_PCT IS NULL,0,1)) ;
-- Mas � necess�rio ter cuidado com a constru��o porque pode gerar resultados indesejados ou mesmo erro
SELECT  e.COMMISSION_PCT, COUNT(*)
	FROM hr.employees e
	GROUP BY (IFNULL(e.COMMISSION_PCT,0)) ;	

-- Alternativa para agrupamento: OVER        
SELECT	 DISTINCT IFNULL(CAST(manager_id AS VARCHAR(10)),'patrão') as "chefe"
        ,COUNT(employee_id) OVER(PARTITION BY manager_id) AS '# funcionário'
	FROM hr.employees ;

SELECT * FROM hr.employees e;

-- A parti��o � individaulizada para a coluna, n�o � v�lida para as restantes
SELECT 	DISTINCT e.DEPARTMENT_ID,  JOB_ID, 
		MIN(e.SALARY),
		AVG(SALARY) OVER (PARTITION BY e.DEPARTMENT_ID)
	FROM hr.employees e
	ORDER BY 1,2; 
-- Neste caso, h� duas condi��es a considerar:
-- Existindo uma fun��o de grupo n�o particionada - MIN() - o query passa a insidir sobre a totalidade da tabela,
-- da� o resultado ter apenas 1 linha
-- A mesma coluna aplica-se � totalidade da tabela, independentemente da parti��o na �ltima coluna
-- As colunas sem agrupamento seguem a regra j� referida anteriormente de apresentar os valores da 1� linha da tabela
-- ou erro noutras implementa��es de SQL

-- A parti��o pode ser realizada por mais do que 1 coluna
-- Neste caso, o agrupamento � realizado para todas as colunas que tenham o par (e.DEPARTMENT_ID,e.JOB_ID) igual 
SELECT 	DISTINCT e.DEPARTMENT_ID,  JOB_ID, 
		AVG(SALARY) OVER (PARTITION BY e.DEPARTMENT_ID,e.JOB_ID)
	FROM hr.employees e
	ORDER BY 1,2; 
-- Neste caso, n�o h� erros de sintaxe ua vez que as colunas sem fun��o de grupo s�o referidas na parti��o,
-- o que funciona como agrupamento, comprindo a restri��o referida anteriormente

-- A parti��o para o OVER n�o tem que ser sobre a mesmo coluna:
SELECT 	DISTINCT e.DEPARTMENT_ID,  JOB_ID, 
		MIN(e.SALARY) OVER (PARTITION BY e.JOB_ID ),
		AVG(SALARY) OVER (PARTITION BY e.DEPARTMENT_ID)
	FROM hr.employees e
	ORDER BY 2,1; 
-- mas � preciso saber ler os resultados!!!
-- Cada parti��o � independente de qualquer outra existente
        
	-- GROUP BY vs. OVER
SELECT e.DEPARTMENT_ID,e.JOB_ID,
		MIN(e.SALARY),
		AVG(e.SALARY)
	FROM hr.employees e
	GROUP BY e.JOB_ID, e.DEPARTMENT_ID
	ORDER BY 1,2;
-- a diferen�a entre este query e o equivalente com OVER, �ltimo anterior, est� na independ�ncia da parti��o
-- No OVER, a pati��o � independente por coluna; no GROUP BY a parti��o � sempre realizada pela lista de colunas
-- Este query de GROUP BY acaba por estar mais pr�ximo da parti��o com duas colunas, s� que, para produzir os mesmo resultados
-- teria que ter uma coluna adicional com a necess�ria duplica��o da parti��o: 
SELECT 	DISTINCT e.DEPARTMENT_ID,  JOB_ID, 
		MIN(e.SALARY) OVER (PARTITION BY e.DEPARTMENT_ID,e.JOB_ID ),
		AVG(SALARY) OVER (PARTITION BY e.DEPARTMENT_ID,e.JOB_ID)
	FROM hr.employees e
	ORDER BY 1,2; 
-- de notar que o OVER � computacionalmente mais exigente (consultar execution plan)
-- pelo que se deve ponderar o uso de uma ou outra op��o com base na performance

-- Outros exemplos
SELECT   DISTINCT e.last_name + ', ' + e.first_name  'nome completo'
        ,IFNULL(CAST(manager_id AS VARCHAR(10)),'patrão') as "chefe"
        ,COUNT(employee_id) OVER(PARTITION BY manager_id) AS '# funcionário'
    FROM hr.employees e
    WHERE last_name LIKE 'a%';

SELECT   DISTINCT e.last_name + ', ' + e.first_name  'nome completo'
	    ,IFNULL(CAST(manager_id AS VARCHAR(10)),'patrão') as "chefe"
	    ,COUNT(employee_id) OVER(PARTITION BY job_id) AS '# funcionário'
    FROM hr.employees e
    WHERE manager_id= 100;
-- a utiliza��o do OVER(PARTITION) permite que a agrega��o seja diferente da organiza��o do query
-- � possivel agregar por uma coluna e agrupar por outra  
-- Na pr�tica, o OVER contorna algumas limita��es sint�ticas referidas anteriormente com o GROUP BY

-- Filtros com agrupamento: HAVING  
SELECT 	e.department_id,
		AVG(e.SALARY) As 'média base', 
		MIN(e.SALARY) As 'minimo base', 
		MAX(e.SALARY) As 'máximo base', 
		e.COMMISSION_PCT,
		AVG(e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0))) as 'média vencimento',
		COUNT(e.employee_id)
	FROM hr.employees e
	WHERE e.SALARY < 7500
	GROUP BY e.department_id;
-- Funciona, mas aplica estatistica apenas a funcionários com vencimento < 7500

SELECT 	e.department_id,
		AVG(e.SALARY) As 'média base', 
		MIN(e.SALARY) As 'minimo base', 
		MAX(e.SALARY) As 'máximo base', 
		e.COMMISSION_PCT,
		AVG(e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0))) as 'média vencimento',
		COUNT(e.employee_id)
	FROM hr.employees e
	WHERE AVG(e.SALARY) < 7500		
	GROUP BY e.department_id;
-- ERR: WHERE s� se aplica a linhas

-- Filtros com fun��o de grupo: HAVING	
-- ex. 1: departamentos com média de vencimentos inferior a 7500   
SELECT 	e.department_id, 
		AVG(e.SALARY) As 'média base', 
		MIN(e.SALARY) As 'minimo base', 
		MAX(e.SALARY) As 'máximo base', 
		e.COMMISSION_PCT,
		AVG(e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0))) as 'média vencimento',
		COUNT(e.employee_id)
	FROM hr.employees e
	GROUP BY e.department_id
	HAVING AVG(e.SALARY) < 7500;	

-- Juntando WHERE e HAVING 
-- Calculos para média de departamento, mas apenas com funcionários com vencimento base < 7500
SELECT 	e.department_id,
		AVG(e.SALARY) As 'média base', 
		MIN(e.SALARY) As 'minimo base', 
		MAX(e.SALARY) As 'máximo base', 
		e.COMMISSION_PCT,
		AVG(e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0))) as 'média vencimento',
		COUNT(e.employee_id)
	FROM hr.employees e
	WHERE e.SALARY < 7500
	GROUP BY e.department_id
	HAVING AVG(e.SALARY) < 5000;
	
-- Caso particular com COUNT()
SELECT COUNT(*),COUNT(e.DEPARTMENT_ID),
		COUNT(*) - COUNT(e.DEPARTMENT_ID) as 'linhas n�o preenchidas' -- S� para exemplifica��o, um simples WHERE e.department_id IS NULL temo mesmo resultado
	FROM hr.employees e;
-- COUNT(*) - Conta linhas, incluindo NULL
-- COUNT(�coluna�) - omite linhas com NULL
	
-- ex. 2: Detec��o de duplicados de apelidos
SELECT e.LAST_NAME AS 'apelido', COUNT(e.employee_id) AS 'contagem'	
	FROM hr.employees e
	GROUP BY e.LAST_NAME
	HAVING COUNT(e.employee_id) > 1; -- apenas nomes com duplicados
	
-- introdu��o subquerie: filtros com valores agregado da mesma tabela
-- Um subquery � um query a correr dentro de outro, do mesmo modo que as subfun��es em matem�tica	
-- ex. 1: funcionário com vencimento superior � média
-- 1. Calculo da média de vencimentos
SELECT AVG(e.SALARY) FROM hr.employees e;

-- 2. Vencimentos superiores � média
-- 		SUBQUERY
SELECT 	e.department_id, 
		e.SALARY As 'base',
		e.COMMISSION_PCT,
		e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0)) as 'vencimento'
	FROM hr.employees e
	WHERE e.SALARY >= (SELECT AVG(e2.SALARY) FROM hr.employees e2);	
-- Sint�ticamente, o uso de um subquery n�o � mais do que substituir uma constante por uma fun��o que produz um resultado compat�vel
-- Neste caso, o resultado compat�vel � um valor num�rico 

-- Tamb�m se podem aplicar subqueries em filtros de grupo (HAVING)
-- ex.: Departamentos suja média de vencimentos seja superior � média de vencimentos da empresa
SELECT 	e.department_id, 
		AVG(e.SALARY) As 'média base', 
		MIN(e.SALARY) As 'minimo base', 
		MAX(e.SALARY) As 'máximo base', 
		e.COMMISSION_PCT,
		AVG(e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0))) as 'média vencimento',
		COUNT(e.employee_id)
	FROM hr.employees e
	GROUP BY e.department_id
	HAVING AVG(e.SALARY) >= (SELECT AVG(e2.SALARY) FROM hr.employees e2);	
	
-- Fun��es de conjunto:
-- UNION; INTERSECT; MINUS  
-- Estas fun��es agregam queries independentes num resultado �nico

-- 1. UNION: Jun��o de dois queries distintos num �nico resultado
-- ex.: calculo de médias, segmentando funcon�rios com comissão e sem
SELECT 	'Sem comissão' as 'tipo',
        FORMAT(AVG(e.SALARY),2) As 'média base', 
		FORMAT(MIN(e.SALARY),2) As 'minimo base', 
		FORMAT(MAX(e.SALARY),2) As 'máximo base', 
 		0 as 'comissão',
		FORMAT(AVG(e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0))),2) as 'média vencimento',
		COUNT(e.employee_id)
	FROM hr.employees e 
        WHERE 	e.COMMISSION_PCT IS NULL
UNION
SELECT 	'Com comissão' as 'tipo',
        FORMAT(AVG(e.SALARY),2) As 'média base', 
		FORMAT(MIN(e.SALARY),2) As 'minimo base', 
		FORMAT(MAX(e.SALARY),2) As 'máximo base', 
		FORMAT(AVG(IFNULL(e.COMMISSION_PCT,0)),2) as 'comissão',
		FORMAT(AVG(e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0))),2) as 'média vencimento',
		COUNT(e.employee_id)
	FROM hr.employees e 
        WHERE 	e.COMMISSION_PCT IS NOT NULL
ORDER BY 1;
-- O numero de colunas tem que ser igual em todos os queries em operador de conjunto   
-- Quando a contagem n�o � igual, acrescentam-de colunas a NULL ou com literais  
-- (Retirem/acrescentem os coment�rio abaixo para obter resultados diferentes no query)       
SELECT 	'Sem comissão' as 'tipo',
        FORMAT(AVG(e.SALARY),2) As 'média base', 
		FORMAT(MIN(e.SALARY),2) As 'minimo base', 
		FORMAT(MAX(e.SALARY),2) As 'máximo base', 
-- 		0 AS comissão,
-- 		NULL,
        FORMAT(AVG(e.SALARY),2) as 'média vencimento',
		COUNT(e.employee_id)
	FROM hr.employees e 
        WHERE 	e.COMMISSION_PCT IS NULL
UNION
SELECT 	'Com comissão' as 'qualquer coisa',
        FORMAT(AVG(e.SALARY),2) As 'média base', 
		FORMAT(MIN(e.SALARY),2) As 'minimo base', 
		FORMAT(MAX(e.SALARY),2) As 'máximo base', 
		FORMAT(AVG(IFNULL(e.COMMISSION_PCT,0)),2) as 'comissão',
		FORMAT(AVG(e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0))),2) as 'média vencimento',
		COUNT(e.employee_id)
	FROM hr.employees e 
        WHERE 	e.COMMISSION_PCT IS NOT NULL;
       
-- o titulo das colunas � sempre o do primeiro query
-- o tipo de dados tem que ser compativel, embora o MySQL converta para tipo compativel, sempre que poss�vel   

-- UNION suporta qualquer quantidade de query
SELECT 	'Sem comissão' as 'tipo',
        FORMAT(AVG(e.SALARY),2) As 'média base', 
		FORMAT(MIN(e.SALARY),2) As 'minimo base', 
		FORMAT(MAX(e.SALARY),2) As 'máximo base', 
		0,
        FORMAT(AVG(e.SALARY),2) as 'média vencimento',
		COUNT(e.employee_id)
	FROM hr.employees e 
        WHERE 	e.COMMISSION_PCT IS NULL
UNION
SELECT 	'Com comissão' as 'tipo',
        FORMAT(AVG(e.SALARY),2), 
		FORMAT(MIN(e.SALARY),2), 
		FORMAT(MAX(e.SALARY),2), 
		FORMAT(AVG(IFNULL(e.COMMISSION_PCT,0)),2) AS 'comissão',
		FORMAT(AVG(e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0))),2),
		COUNT(e.employee_id)
	FROM hr.employees e 
        WHERE 	e.COMMISSION_PCT IS NOT NULL
UNION        
SELECT  'Total',
        FORMAT(AVG(e.SALARY),2), 
		FORMAT(MIN(e.SALARY),2), 
		FORMAT(MAX(e.SALARY),2), 
		FORMAT(AVG(IFNULL(e.COMMISSION_PCT,0)),2),
		FORMAT(AVG(e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0))),2),
		COUNT(e.employee_id)
	FROM hr.employees e;
 
 -- Ordena��o             
SELECT 	'Sem comissão' as 'tipo',
        FORMAT(AVG(e.SALARY),2) As 'média base', 
		FORMAT(MIN(e.SALARY),2) As 'minimo base', 
		FORMAT(MAX(e.SALARY),2) As 'máximo base', 
		0 AS comissão,
        FORMAT(AVG(e.SALARY),2) as 'média vencimento',
		COUNT(e.employee_id)
	FROM hr.employees e 
        WHERE 	e.COMMISSION_PCT IS NULL
UNION
SELECT 	'Com comissão' as 'tipo',
        FORMAT(AVG(e.SALARY),2), 
		FORMAT(MIN(e.SALARY),2), 
		FORMAT(MAX(e.SALARY),2), 
		FORMAT(AVG(IFNULL(e.COMMISSION_PCT,0)),2),
		FORMAT(AVG(e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0))),2),
		COUNT(e.employee_id)
	FROM hr.employees e 
        WHERE 	e.COMMISSION_PCT IS NOT NULL
UNION        
SELECT  'Total',
        FORMAT(AVG(e.SALARY),2), 
		FORMAT(MIN(e.SALARY),2), 
		FORMAT(MAX(e.SALARY),2), 
		FORMAT(AVG(IFNULL(e.COMMISSION_PCT,0)),2),
		FORMAT(AVG(e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0))),2),
		COUNT(e.employee_id)
	FROM hr.employees e
ORDER BY tipo;  -- tamb�m se pode utiliza o ordinal da coluna: ORDER BY 1
                -- O ORDER s� � aplicado ap�s calculo do resultado final, � o ultimo parametro a ser calculado

-- Como os queries s�o independentes, � boa-pr�tica introduzir uma coluna adicional com constante para garantir a ordena��o pretendida
SELECT 	'1' as ordem,
		'Sem comissão' as 'tipo',
        FORMAT(AVG(e.SALARY),2) As 'média base', 
		FORMAT(MIN(e.SALARY),2) As 'minimo base', 
		FORMAT(MAX(e.SALARY),2) As 'máximo base', 
		0 AS comissão,
        FORMAT(AVG(e.SALARY),2) as 'média vencimento',
		COUNT(e.employee_id)
	FROM hr.employees e 
        WHERE 	e.COMMISSION_PCT IS NULL
UNION
SELECT 	'1' as ordem,
		'Com comissão' as 'tipo',
        FORMAT(AVG(e.SALARY),2), 
		FORMAT(MIN(e.SALARY),2), 
		FORMAT(MAX(e.SALARY),2), 
		FORMAT(AVG(IFNULL(e.COMMISSION_PCT,0)),2),
		FORMAT(AVG(e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0))),2),
		COUNT(e.employee_id)
	FROM hr.employees e 
        WHERE 	e.COMMISSION_PCT IS NOT NULL
UNION        
SELECT 	'2' as ordem,
		'Total',
        FORMAT(AVG(e.SALARY),2), 
		FORMAT(MIN(e.SALARY),2), 
		FORMAT(MAX(e.SALARY),2), 
		FORMAT(AVG(IFNULL(e.COMMISSION_PCT,0)),2),
		FORMAT(AVG(e.SALARY + (e.SALARY * IFNULL(e.COMMISSION_PCT,0))),2),
		COUNT(e.employee_id)
	FROM hr.employees e
ORDER BY 1,2 DESC;
                