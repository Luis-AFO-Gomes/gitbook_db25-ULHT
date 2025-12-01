/********************************************************************************
 * Aula 09														  27/10/2025 	*
 * LIG/LEI/LCD/LMC															 	*
 *																			 	*
 * DDL: Operador Relacional - Junção Horizontal									*
 *		- (produto) INTERNA														*
 *		- (produto) EXTERNA														*
 *		Impacto com relacionamento (FK)				 							*
 *		Desnormalização															*
 ********************************************************************************/
 use ULHT_DB25;

SELECT * FROM HR.EMPLOYEES e;
SELECT * FROM HR.JOB_HISTORY j;

-- Junções Horizontais
-- 1. EXTERNA: Junção de tabelas sem necessidade de elementos comuns
SELECT * FROM HR.EMPLOYEES e,HR.JOB_HISTORY
--	WHERE e.EMPLOYEE_ID =100
	ORDER BY e.EMPLOYEE_ID;
-- verificação de dimensão do query
SELECT COUNT(employee_id) FROM HR.EMPLOYEES e; 	-- > 107
SELECT COUNT(employee_id) FROM HR.JOB_HISTORY jh; 	-- > 10

-- Boas-práticas:
-- Deve-se utilizar alias para facilitar identificação, filtros e ordenaçãoo
-- particularmente quando há colunas com o mesmo nome, caso onde aliasing é obrigatório 

-- Pode-se utilizar filtros para tratar comunalidade de dados e reduzir a dimensão do resultado
SELECT * FROM HR.EMPLOYEES AS e, HR.JOB_HISTORY jh 
	WHERE 	e.EMPLOYEE_ID = jh.EMPLOYEE_ID  AND
		e.DEPARTMENT_ID != jh.DEPARTMENT_ID
--			e.EMPLOYEE_ID =100;

-- Funcionários com mais do que uma função ao longo do tempo
SELECT DISTINCT e.*,jh.JOB_ID as JOB 
	FROM HR.EMPLOYEES e,HR.JOB_HISTORY jh 
	WHERE e.EMPLOYEE_ID = jh.EMPLOYEE_ID
	ORDER BY e.EMPLOYEE_ID,JOB;
-- O uso de aliasing permite tratar os dados originários em cada uma das tabelas de forma diferente

-- Sendo simples de implementar, tem impacto muito relevante na performance
-- A 1º acção do DBEngine é criar o domínio do query, que, neste caso, implica construir
-- o conjunto com o produto externo das tabelas utilizada, com o consequente consumo de memória e processamento

-- 2. INTERNA: JOIN
-- 		requer um elemento comum entre as tabelas agregadas
-- 		particularmente adequada é desnormalização (junção de tabelas com base em FK)
SELECT * 
	FROM HR.EMPLOYEES e JOIN
		HR.JOB_HISTORY jh ON e.EMPLOYEE_ID = jh.EMPLOYEE_ID;

SELECT * 
	FROM HR.JOB_HISTORY e JOIN
		HR.EMPLOYEES jh ON e.EMPLOYEE_ID = jh.EMPLOYEE_ID;		

-- Em versões mais antigas de alguns SGBD - e.g. MySQL - a sintaxe da junção podia utilizar USING
-- mas apenas quando o nome da coluna de junção fosse igual em ambas as tabelas
-- SELECT * 
-- 	FROM HR.EMPLOYEES e JOIN
-- 		HR.JOB_HISTORY jh USING employees_id;
	

SELECT e.EMPLOYEE_ID as '@employees',jh.EMPLOYEE_ID AS '@job_history' 
	FROM HR.EMPLOYEES e LEFT JOIN
		HR.JOB_HISTORY jh ON e.EMPLOYEE_ID = jh.EMPLOYEE_ID;
	
-- SINTAXE GERAL:
-- 	SELECT «lista_colunas»
-- 		FROM «tabela_1» [alias_1»] [INNER|LEFT|RIGHT|FULL] JOIN
-- 			«tabela_2» [«alias_2»] ON «JOIN_EXP»
-- 		[WHERE «filtro»]	
-- 		[GROUP BY «group_exp»]
-- 		[HAVING «group_filter»]
-- 		[ORDER BY «ordem»]	

-- onde «JOIN_EXP» ::= «join_criteria»|«join_criteria» «logic_operatior» «JOIN_Exp»
-- e	«join_criteria» ::= [«alias_1»].«coluna_tabela_1» = «coluna_tabela_2»
-- e	«logic_operator» ::= AND|OR

-- A sintaxe correcta utiliza a palavra reservada [INNER] como parte da instrução para separar o JOIN simples do lateralizado. 
-- No entanto, boa parte das implementações deixaram de o obrigar, aplicando o versão simples da junção sempre que não haja outra indicação
-- A expreção de junção - «JOIN_Exp» - pode ser bastante mais complexa do que indicado na sintaxe, mas esses conceitos excedem o ambito presente da disciplina

-- Em termos de performance, o JOIN tem grandes diferenças face o PRODUTO EXTERNO
-- A junção passa por analisar ambas as tabelas e filtrar os elementos comuns, portanto
-- há uma pesquisa (filtro) sobre a segunda relação a cada novo valor da primeira.
-- Usando indices, o JOIN torna-se bastante mais eficiente que o PRODUTO EXTERNO  	

-- Lateralidade
-- Incluir elementos de uma tabela mesmo quando não há correspondência na junção
-- 3 tipos: LEFT, RIGHT e FULL [OUTER] 
SELECT e.EMPLOYEE_ID, jh.* 
	FROM HR.EMPLOYEES e FULL JOIN
		HR.JOB_HISTORY jh ON e.EMPLOYEE_ID = jh.EMPLOYEE_ID
	ORDER BY e.EMPLOYEE_ID ;

SELECT * 
	FROM HR.EMPLOYEES e LEFT JOIN 
		HR.DEPARTMENTS d ON e.DEPARTMENT_ID = d.DEPARTMENT_ID
	WHERE d.DEPARTMENT_ID IS NULL;

SELECT * FROM HR.EMPLOYEES e,HR.DEPARTMENTS d;

-- A junção lateralizada associada a filtro de nulos permite identificar elementos de cada uma das tabelas que não participam na junção
-- Ex. 1: Departamentos sem funcionários
SELECT e.EMPLOYEE_ID, d.* 
	FROM HR.EMPLOYEES e LEFT JOIN 
		HR.DEPARTMENTS d ON e.DEPARTMENT_ID = d.DEPARTMENT_ID
	WHERE e.DEPARTMENT_ID IS NULL;

-- Ex. 2: Detecção de erros de concistência: detecção de registos históricos que não indiquem funcionário válido
SELECT e.EMPLOYEE_ID, jh.* 
	FROM HR.EMPLOYEES e RIGHT JOIN
		HR.JOB_HISTORY jh ON e.EMPLOYEE_ID = jh.EMPLOYEE_ID
	ORDER BY e.EMPLOYEE_ID ;

-- Ex. 3: Todas as funções de um funcionário
SELECT e.EMPLOYEE_ID, e.JOB_ID, jh.* 
	FROM HR.JOB_HISTORY jh  RIGHT JOIN
		HR.EMPLOYEES e ON e.EMPLOYEE_ID = jh.EMPLOYEE_ID
	ORDER BY e.EMPLOYEE_ID ;
-- Apresenta todos os funcionários, mesmo os que não tiveram outras funções (não existem em JOB_HISTORY)
-- Nestes casos, as colunas referentes à tabela JOB_HISTORY são apresentada a [NULL]:
SELECT e.EMPLOYEE_ID as '@employees',jh.EMPLOYEE_ID AS '@job_history' 
	FROM HR.EMPLOYEES e LEFT JOIN
		HR.JOB_HISTORY jh ON e.EMPLOYEE_ID = jh.EMPLOYEE_ID;
	
-- No mesmo exemplo, podemos isolar os funcionários sem histórico	
-- ex. comum de uso: funcionários sem histórico:	
SELECT e.EMPLOYEE_ID as '@employees',jh.EMPLOYEE_ID AS '@job_history' 
	FROM HR.EMPLOYEES e LEFT JOIN
		HR.JOB_HISTORY jh ON e.EMPLOYEE_ID = jh.EMPLOYEE_ID
	WHERE jh.EMPLOYEE_ID  IS NULL
	ORDER BY e.EMPLOYEE_ID;
	
-- A lateralidade é vista pela ordem de tabelas no FROM e não no ON
SELECT e.EMPLOYEE_ID as '@employees',jh.EMPLOYEE_ID AS '@job_history' 
	FROM HR.JOB_HISTORY jh LEFT JOIN
		HR.EMPLOYEES e ON jh.EMPLOYEE_ID = e.EMPLOYEE_ID;
	
-- FULL JOIN: Corresponde à sobreposição das duas lateralidades
--			  Apresenta todos os dados de ambas as tabelas, complementando a NULL quando não exista correspondência
-- O MariaDB não suporta o FULL JOIN, ao contrário das restantes implementações
-- versão MySQL, MS-SQL e PostgreSQL
SELECT e.EMPLOYEE_ID,e.LAST_NAME + ', ' + e.FIRST_NAME , e.DEPARTMENT_ID, d.DEPARTMENT_ID,d.DEPARTMENT_NAME
	FROM HR.EMPLOYEES e FULL  JOIN
		HR.DEPARTMENTS d ON e.DEPARTMENT_ID = d.DEPARTMENT_ID;
	
-- Em MariaDB à necessário recorrer a operação UNION:
SELECT e.EMPLOYEE_ID, jh.*  
	FROM HR.EMPLOYEES e LEFT JOIN
		HR.JOB_HISTORY jh ON e.EMPLOYEE_ID = jh.EMPLOYEE_ID
UNION 
SELECT e.EMPLOYEE_ID, jh.*  
	FROM HR.EMPLOYEES e RIGHT JOIN
		HR.JOB_HISTORY jh ON e.EMPLOYEE_ID = jh.EMPLOYEE_ID
ORDER BY 1;
	
-- SINTAXE passa a ser (com a diferença já referida para o MariaDB):
-- 	SELECT «lista_colunas»
-- 		FROM «tabela_1» [«alias_1»] [[INNER]|LEFT|RIGHT|FULL[ OUTER]] JOIN
-- 			«tabela_2» [«alias_2»] ON «JOIN_EXP»
-- 		[WHERE «filtro»]	
-- 		[GROUP BY «group_exp»]
-- 		[HAVING «group_filter»]
-- 		[ORDER BY «ordem»]	

-- Auto-Junção ou junção própria
-- o problema principal é a correcta identificação das colunas no output já que existe uma duplicação inegral de atributos
SELECT ISNULL(e1.FIRST_NAME + ' ' + e1.LAST_NAME,'PATRÃO') as 'chefe', e2.FIRST_NAME + ' ' + e2.LAST_NAME as 'funcionário'
	FROM HR.EMPLOYEES e1 INNER JOIN
		HR.EMPLOYEES e2 ON e1.EMPLOYEE_ID = e2.MANAGER_ID;

-- De notar que não são apresentados funcionários sem chefia...
-- 
-- Multipla junção
-- Corresponde a juntar mais do que 2 tabelas
-- Pode ter 2 formas:
-- 1. Encadeado:
SELECT * 
	FROM HR.DEPARTMENTS d JOIN
		HR.LOCATIONS l ON d.LOCATION_ID =l.LOCATION_ID 
		JOIN 
		HR.COUNTRIES c ON l.COUNTRY_ID =c.COUNTRY_ID 
		JOIN 
		HR.REGIONS r ON c.REGION_ID =r.REGION_ID;
	
-- 2. Agregado
SELECT * 
	FROM (HR.DEPARTMENTS d JOIN
			HR.LOCATIONS l ON d.LOCATION_ID =l.LOCATION_ID) 
		JOIN 
		 (HR.COUNTRIES c JOIN 
			HR.REGIONS r ON c.REGION_ID =r.REGION_ID)
		ON l.COUNTRY_ID =c.COUNTRY_ID ;
