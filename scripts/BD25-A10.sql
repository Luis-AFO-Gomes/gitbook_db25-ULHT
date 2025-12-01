/********************************************************************************
 * Aula 10														  13/11/2024 	*
 * LIG/LEI/LCD/LMC															 	*
 *																			 	*
 * DDL: Operador Relacional - Junção Vertical									*
 *		- sub-queires															*
 *		Extras										 							*
 *		- CTE																	*
 *		- Recursividade (Arvore)												*
 ********************************************************************************/
USE ULHT_DB25;

/****************************************************************************************
 * Junção Vertical: Subqueries															*
 * 3 tipos																				*
 *	1. 	inline ou de substituição: Colocados no parametro SELECT, servem principalmente *
 *		para substituir chaves de referência por valores em tabelas atributivas			*
 *	2. 	Como tabelas temporárias escritas dentro do query principal: Colocados no para-	*
 *		metro FROM, servem para manipulação de dados em vários niveis					*
 *	3. 	Como parte do filtro: Colocados no parametro WHERE ou HAVING, servem para fil-	*
 *		trar por conjunto ou com teoria de conjuntos									*
 ****************************************************************************************/

-- 1. Inline (queries de substituição)
-- 	Ex.: Substituir código de função e de departamento
SELECT employee_id,first_name,last_name,job_id,department_id FROM HR.EMPLOYEES;

SELECT j.EMPLOYEE_ID, COUNT(*) FROM HR.JOB_HISTORY  j GROUP BY j.EMPLOYEE_ID,j.job_id,j.start_date HAVING COUNT(*) > 1;
-- se resultado vazio, tabela está em 2FN

SELECT * FROM HR.EMPLOYEES;
SELECT * FROM HR.DEPARTMENTS;
SELECT * FROM HR.JOBS;

-- R.1: JOIN
SELECT e.employee_id,e.first_name,e.last_name,j.job_title,d.department_name, d.location_id
        FROM HR.EMPLOYEES e 
                LEFT JOIN HR.JOBS j ON e.job_id = j.job_id 
                LEFT JOIN HR.DEPARTMENTS d ON e.department_id = d.department_id
        ORDER BY e.employee_id
        ;

-- R.2: Subqueries
SELECT   employee_id
        ,first_name
        ,last_name
        ,(SELECT j.job_title FROM HR.JOBS j WHERE j.job_id=e.job_id) AS job_title
        ,(SELECT d.department_name FROM HR.DEPARTMENTS d WHERE d.department_id=e.department_id) AS department_name
     ,(SELECT d.LOCATION_ID FROM HR.DEPARTMENTS d WHERE d.department_id=e.department_id) AS department_location
    FROM HR.EMPLOYEES e;
-- o subquery (em substituição) só pode devolver 1 valor
-- mesmo quando são necessários dois valores da mesma tabela, terão que se utilizar 2 sub-queries
GO

CREATE VIEW vw_EMPLOYEES AS  
SELECT   employee_id
        ,first_name
        ,last_name
        ,(SELECT j.job_title FROM HR.JOBS j WHERE j.job_id=e.job_id) AS job_title
        ,(SELECT d.department_name FROM HR.DEPARTMENTS d WHERE d.department_id=e.department_id) AS department_name
    FROM HR.EMPLOYEES e;
GO	

 SELECT * FROM vw_employees;   

-- 2. Tabela temporária
-- Ex.1: Listar departamentos ordenando pela média de vencimentos do departamento
-- tabela de média de vencimentos por departamento
-- 1. query de substituição para nome do departamento
SELECT  (SELECT d.DEPARTMENT_NAME
			FROM HR.DEPARTMENTS d
			WHERE d.DEPARTMENT_ID = e.DEPARTMENT_ID) AS DEPARTMENT
	,COUNT(e.EMPLOYEE_ID) as employees
	,AVG(e.SALARY) as average
   FROM HR.EMPLOYEES e
   GROUP BY e.DEPARTMENT_ID
   HAVING COUNT(e.EMPLOYEE_ID) > 1
   ORDER BY 3;

-- query sobre resultado de query (subquery) de análise estatistica de salários
SELECT * 
	FROM(SELECT  (SELECT d.DEPARTMENT_NAME FROM HR.DEPARTMENTS d WHERE d.DEPARTMENT_ID = e.DEPARTMENT_ID) AS DEPARTMENT
				,COUNT(e.EMPLOYEE_ID) as employees
				,AVG(e.SALARY) as average
			FROM HR.EMPLOYEES e
			GROUP BY e.DEPARTMENT_ID
		) AS t
	WHERE t.EMPLOYEES > 1
	ORDER BY t.average DESC;

SELECT AVG(salary) FROM HR.EMPLOYEES;
 
-- calcular a média das médias
SELECT AVG(average)
	FROM(SELECT  (SELECT d.DEPARTMENT_NAME FROM HR.DEPARTMENTS d WHERE d.DEPARTMENT_ID = e.DEPARTMENT_ID) AS DEPARTMENT
				,COUNT(e.EMPLOYEE_ID) as employees
				,AVG(e.SALARY) as average
			FROM HR.EMPLOYEES e
			GROUP BY e.DEPARTMENT_ID
			HAVING COUNT(e.employee_id) > 1
		) AS t;
-- Obrigatoriamente, o subquery tem que ser delimitado por ()
-- e tem que ter aliasing
-- ex: ... FROM (SELECT ) AS «alias»
-- 
-- Além disso, todas as colunas do subquery também têm que ter alias
-- de outra forma, a coluna não é identificada pelo query externo

-- 3. filtro
-- 	Ex.1: Funcionários com vencimento acima da média
SELECT AVG(salary) FROM HR.EMPLOYEES;

SELECT * FROM HR.EMPLOYEES e1
        WHERE e1.salary >= (SELECT AVG(e2.salary) FROM HR.EMPLOYEES e2)
        ORDER BY e1.salary;

-- 	Ex.2: Funcionários com vencimento médio acima da média do próprio departamento
-- 		  Condicionar o sub-queiry a valores do query externo       
SELECT 	 e1.EMPLOYEE_ID 
		,e1.LAST_NAME 
		,e1.FIRST_NAME 
		,e1.DEPARTMENT_ID 
		,e1.SALARY 
		,(SELECT AVG(e2.SALARY) 
			FROM HR.EMPLOYEES e2 
			WHERE e2.DEPARTMENT_ID = e1.DEPARTMENT_ID 
			GROUP BY e2.DEPARTMENT_ID ) AS media
	FROM HR.EMPLOYEES e1
	WHERE e1.SALARY > (SELECT AVG(e2.SALARY) 
                                FROM HR.EMPLOYEES e2 
                                WHERE e2.DEPARTMENT_ID = e1.DEPARTMENT_ID 
                                GROUP BY e2.DEPARTMENT_ID )
        ORDER BY e1.salary DESC;
        
-- Ex.3: Duplicados
-- Funcionário com vencimento mais elevado em cada departamento com mais do que 1 funcionário
-- 1. identificar departamentos com + 1 funcionário
SELECT e1.department_id, COUNT(e1.employee_id)
        FROM HR.EMPLOYEES e1       
        GROUP BY e1.department_id
        HAVING COUNT(e1.employee_id) > 1;

-- 2. identificar funcionários destes departamentos
SELECT e2.department_id,max(e2.salary),COUNT(DEPARTMENT_ID)
		FROM HR.EMPLOYEES e2
        WHERE e2.department_id IN (SELECT e1.department_id
                                        FROM HR.EMPLOYEES e1       
                                        GROUP BY e1.department_id
                                        HAVING COUNT(e1.employee_id) > 1)
        GROUP BY e2.department_id;  

-- 3. Funcionários com os salários identificados
SELECT 	 e3.EMPLOYEE_ID,e3.LAST_NAME,e3.FIRST_NAME 
		,e3.DEPARTMENT_ID,e3.SALARY 
		,(SELECT MAX(e2.SALARY) 
			FROM HR.EMPLOYEES e2 
			WHERE e2.DEPARTMENT_ID = e3.DEPARTMENT_ID 
			GROUP BY e2.DEPARTMENT_ID ) AS maior 
	FROM HR.EMPLOYEES e3
        JOIN (SELECT e2.department_id AS department, max(e2.salary) AS salary
                FROM HR.EMPLOYEES e2
                WHERE e2.department_id IN (SELECT e1.department_id
                                                FROM HR.EMPLOYEES e1       
                                                GROUP BY e1.department_id
                                                HAVING COUNT(e1.employee_id) > 1)
                GROUP BY e2.department_id) AS t 
            ON 	e3.department_id = t.department AND 
            	e3.salary = t.salary
         ORDER BY e3.DEPARTMENT_ID;
 
 -- para relevancia estatistica, apenas departamentos com mais que 1 funcionário
 -- Na realidade, não altera resultado...
SELECT 	 e1.EMPLOYEE_ID 
		,e1.LAST_NAME 
		,e1.FIRST_NAME 
		,e1.DEPARTMENT_ID 
		,e1.SALARY 
		,(SELECT MAX(e2.SALARY) 
			FROM HR.EMPLOYEES e2 
			WHERE e2.DEPARTMENT_ID = e1.DEPARTMENT_ID 
			GROUP BY e2.DEPARTMENT_ID ) AS media
	FROM HR.EMPLOYEES e1
	WHERE e1.SALARY > (SELECT AVG(e2.SALARY) 
                                FROM HR.EMPLOYEES e2 
                                WHERE e2.DEPARTMENT_ID = e1.DEPARTMENT_ID 
                                GROUP BY e2.DEPARTMENT_ID ) AND
              e1.department_id IN (SELECT e3.department_id FROM HR.EMPLOYEES e3
                                        GROUP BY e3.department_id
                                        HAVING COUNT(e3.employee_id) > 1)
        ORDER BY e1.salary DESC;
							
-- Questões de performace: junção vertical (subquery) vs. junção horizontal (interna)						
-- Depende...
					
/********************************************************************************
 * Extra: Árvore																*
 ********************************************************************************/
-- Ex. 1: Hierarquia
WITH hierachy AS (
	SELECT 	 e1.EMPLOYEE_ID, e1.MANAGER_ID, e1.FIRST_NAME, e1.LAST_NAME
			,0 as nivel, CAST(e1.EMPLOYEE_ID AS VARCHAR(255)) as hierachy
			,CAST('' AS VARCHAR(255)) as boss
	FROM HR.EMPLOYEES e1 
	WHERE e1.EMPLOYEE_ID = 100
	UNION ALL
	SELECT 	 e2.EMPLOYEE_ID, e2.MANAGER_ID, e2.FIRST_NAME, e2.LAST_NAME
			,nivel + 1
			,CAST(h.hierachy + '.' + CAST(e2.EMPLOYEE_ID AS VARCHAR(255)) AS VARCHAR(255)) as hierachy
			,CAST(h.boss + '.' + CAST(e2.MANAGER_ID AS VARCHAR(255)) AS VARCHAR(255)) as boss
	FROM HR.EMPLOYEES e2 
	  JOIN hierachy h ON h.EMPLOYEE_ID = e2.MANAGER_ID 
)
SELECT *
	FROM hierachy
	WHERE nivel >= 0
	ORDER BY hierachy;
-- O query sobre a recursividade terá que ser realizado em conjunto com o próprio,
-- o resultado da expressão WITH não é retido
	
/********************************************************************************
 * Extra: Common Table Expression (CTE)											*
 ********************************************************************************/	
-- 	Muito semelhante à utilização de subqueries como tabelas temporárias, mas com a tabela a ser definida como objecto	
WITH salary_cte (department,employees,qq_coisa) 
	AS (SELECT  (SELECT d.DEPARTMENT_NAME FROM HR.DEPARTMENTS d WHERE d.DEPARTMENT_ID = e.DEPARTMENT_ID) AS DEPARTMENT
					,COUNT(e.EMPLOYEE_ID) as employees
					,AVG(e.SALARY) as average
				FROM HR.EMPLOYEES e
				GROUP BY e.DEPARTMENT_ID
	)
	SELECT * FROM salary_cte cte
		WHERE cte.employees > 1
		ORDER BY qq_coisa DESC;
-- O query sobre o o CTE terá que ser realizado em conjunto com o próprio, 
-- tal como no exemplo anterior com o WITH, o resultado do CTE não é retido

-- naturalmente, o resultado é igual ao visto anteriormente
-- Note-se que a Árvore é um caso particular de CTE com recursividade
	
-- Em relação ao subquery, uma CTE tem a vantagem de permitir multiplas definições de tabelas

-- SINTAXE:
-- WITH [RECURSIVE] «CTE_table_name» [(«column_list»)] AS
-- 		(«query»)	
-- 		[, «CTE_table2_name» («column_list»)
-- 			(«query»)]	
-- «outer_query»
-- 
-- Onde:
-- 	«outer_query» é um query sql referindo todas as CTE definidas previamente	