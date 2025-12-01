/********************************************************************************
 * Aula 15														  	11/2025 	*
 * LIG/LEI/LCD/LMC															 	*
 *																			 	*
 * Programação Parte III: Condicionais e Ciclos									*
 *	- Condicional: IF															*
 *	- Ciclos: WHILE																*
 *			  Outros															*	
 *	- CURSOR																	*
 *  - Encadeamento de módulos programados										*
 ********************************************************************************/
USE ULHT_DB25;
GO

/************************************************************************************************************************************************************************
 * Programação																																							* 
 ************************************************************************************************************************************************************************/
-- 3.	IF
-- Classificação qualitiativa em avaliação 0-20
IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[hr].[ufn_sql15_IF]')
                  AND type = N'FN')
	DROP FUNCTION [hr].[ufn_sql15_IF];
GO

CREATE OR ALTER FUNCTION [hr].[ufn_sql15_IF](
	 @p_classIFication decimal(4,2)) RETURNS VARCHAR(100)
AS	 
BEGIN
	IF @p_classIFication <= 8
		RETURN 'Reprovado (' + CAST(@p_classIFication AS VARCHAR(5)) + '): 2ª época';
    ELSE IF @p_classIFication <= 9.5
    	RETURN 'Nota mínima (' + CAST(@p_classIFication AS VARCHAR(5)) + '): Aguarda nota complementar';

   	RETURN 'Aprovado(' + CAST(@p_classIFication AS VARCHAR(5)) + ')';
	-- Uma função tem que acabar obrigatoriamente com RETURN, o que pode levar a alguns problemas com blocos condicionais complexos
	-- é recomendável que o RETURN seja colocado no final da função, com a atribuição do valor a devolver feita em variável intermédia
END;
GO

-- Chamada à função
DECLARE @myGradeNumber decimal(4,2);
SET @myGradeNumber  = 15;
SELECT hr.ufn_sql15_IF(@myGradeNumber) AS resultado;

SET @myGradeNumber = 10;
SELECT hr.ufn_sql15_IF(@myGradeNumber) AS resultado;

SET @myGradeNumber  = 7;
SELECT hr.ufn_sql15_IF(@myGradeNumber) AS resultado;

/********************************
 * 4. Ciclos					*
 ********************************
 * 4.1. Ciclo WHILE			*
 ****************************/
 -- 1. Ciclo simples, sem dados

/************************
 * 	MS-SQL				* 
 ************************/
--		A sintaxe MS-SQL é mais rigorosa, mas não muito distante das diferenças vistas anterioremente com tratamento de variáveis e módulos programados
--		O mesmo exemplo pode ser realizado sem a construção de um módulo programado, o MS-SQL não requer esse encapsulamento
--
IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[sp_mssql15_WHILE]')
                  AND type = N'P')
	DROP PROCEDURE [dbo].[sp_mssql15_WHILE];
GO

CREATE PROCEDURE sp_mssql15_WHILE 
AS
BEGIN
	DECLARE @i int = 1
	DECLARE @j int = 1
	DECLARE @s varchar(200) = ''
	
	WHILE @i<5
	BEGIN
		SET @s = CONCAT(@s,'i=',CAST(@i AS VARCHAR(2)),CHAR(13) + CHAR(10))
		SET @j = @i
		WHILE @j<10
		BEGIN
			SET @s = CONCAT(@s,'  ',CAST(@j AS VARCHAR(2)))
			SET @j = @j + 1
		END
		SET @s = CONCAT(@s,CHAR(13) + CHAR(10))
		SET @i = @i + 1
	END
	PRINT @s
END;
GO

EXEC sp_mssql15_WHILE;

--		Note-se, no entanto, que há algumas diferenças sintáticas relevantes
--		1. 	Em MS-SQL, não se usa o 'DO' no início do ciclo:
--		2.	Em MS-SQL, o WHILE não inicia um bloco, tendo que ser declarado explicitamente um se a repetição tiver mais do que 1 linha
--			{MySQL} WHILE «condiçao» DO
--						«instruções»
--					END
--			{MS-SQL} WHILE «condiçao»
--					 BEGIN
--						«instruções»
--					 END

-- Ex. 2:	Calculo com dados
--			somar ordenados mais baixos até atingir o mais alto
/************************
 * 	MS-SQL				* 
 ************************/
-- Sem módulo programado 
DECLARE  @AddedSalary	AS NUMERIC(6) = 0		-- Acumulado da soma de ordenados mais baixos
		,@SalaryAtPos	AS NUMERIC(3) = 1		-- variavel de iteração, contagem de ordenados somados até alcançar o valor MAX
		,@maxSalary		AS NUMERIC(6) = (SELECT MAX(salary) FROM [HR].[EMPLOYEES]) 

WHILE (@AddedSalary < @maxSalary)
BEGIN
	SET @AddedSalary = @AddedSalary + (SELECT t.SALARY 
											FROM (SELECT 
														ROW_NUMBER() OVER(ORDER BY SALARY ASC) AS ordem,
														SALARY
													FROM [HR].[EMPLOYEES]) AS t
											WHERE t.ordem = @SalaryAtPos)
	SET @SalaryAtPos = @SalaryAtPos + 1
END
PRINT	'somados os ' 							-- O MS-SQL dispõe do comando PRINT que direcciona o resultado para consola em ves do StdIO
		+ CAST(@SalaryAtPos - 1 AS VARCHAR(3))	-- a subtração de 1 é necessária para reverter o ultimo incremento da variavel
		+ ' salarios mais baixos, no total de ' 
		+ CAST(@addedSalary AS VARCHAR(6)) 
		+ ', para ultrapassar os ' 
		+ CAST(@maxSalary AS VARCHAR(6)) 
		+ ' do salario mais alto'
GO

/************************************
 * EXTRA							*
 * Exemplo completo de ROW_NUMBER	*
 ************************************
 * 	MS-SQL				* 
 ************************/
 -- Indicar a ordem dos funcionários por ordenado e por ID
SELECT 
	 EMPLOYEE_ID
	, LAST_NAME + ', ' + FIRST_NAME
	,ROW_NUMBER() OVER(ORDER BY SALARY ASC) AS ordem	--> ordenação de ROW_NUMBER() é independente 
														--	da ordenação do resultado (dada por ORDER BY no final do query)
	,ROW_NUMBER() OVER(ORDER BY EMPLOYEE_ID)			--> O mesmo query pode ter varios ROW_NUMBER
														--	com ordenação pro colunas diferentes
	,SALARY
FROM [HR].[EMPLOYEES]
ORDER BY LAST_NAME
GO

/****************************
 * 4.2. Ciclo LOOP/FOR		*
 * 4.3. Ciclo REPEAT		*	
 ****************************************************************
 * O MS-SQL não tem ciclos FOR/LOOP, apenas WHILE				* 
 * Consultar ficheiro separado para exemplos em MySQL/MariaDB	*
 ****************************************************************/


/****************************
 * 4.4.	CURSOR				*
 * Iteração com tabelas		*
 ************************************************************************************************************************************************************************
 * Os motores de base de dados, particularmente os relacionais, têm outro formato de ciclo que opera percorrendo a tabelas e aplicando lógica de negócio a cada linha.	*
 * A tabela/relação que o ciclo vai percorrer, num formato que se pode comparar com uma estrutura FOR...EACH, pode ser parte do modelo de dados ou ser criada 			*
 * especificamente para o ciclo																																			*
 * 																																										*
 * Este tipo de estruturas designam-se por CURSOR																														*
 * 																																										*
 ************************************************************************************************************************************************************************
 * Um CURSOR tem uma estrutura algo complexa porque obriga a 4 elementos:																								*
 * 1. Declaração e definição da relação a iterar:																														*
 * 		DECLARE «cursor_name» CURSOR FOR «select_statement»																												*
 * 2. Controlo de estado do CURSOR																																		*
 * 		OPEN «cursor_name»/CLOSE «cursor_name»																															*																																				
 * 3. Iteração pelas linhas da relação																																	*	
 * 	  A iteração utiliza ciclo LOOP/FOR (...EACH), com leitura por FETCH																								* 
 * 		FETCH «cursor_name» INTO «variable_list»																														*
 *	  Podendo «select_statement» ter mais do que uma coluna, o FETCH poderá ler mais do que um valor a cada Iteração													*
 *	  A «variable_list»	terá que ter tantas variáveis quantas as colunas em «select_statement» 																			*
 *	  As variáveis em «variable_list» terão que ser declaradas antes do inicio do cursor (DECLARE CURSOR) e com tipo compatível com as colunas lidas					*	
 * 4. Controlo de paragem																																				*
 * 		No MS-SQL (e noutras implementações) a iteração é realizada com ciclo WHILE, com paragem em FETCH vazio [WHILE @@FETCH_STATUS = 0]								*
 *		mas sem necessidade de controlo de excepções (@@FETCH_STATUS = 0 indica que a leitura do FETCH não tem erro)													*
 *		Em contrapartida, as variaveis a tratar pelo cursor - «variable_list» - têm que ser iterada manualmente, visto o WHILE não as actualizar. Na prática, isto		*
 *		significa que tem que existir um segundo FETCH no código do CURSOR																								*
 * 																																										*
 *	-- MS-SQL																																							*
 * 		DECLARE «cursor_name» CURSOR FOR «select_statement»																												*
 *		OPEN «cursor_name»;																																				*
 *			FETCH «cursor_name» INTO «varaibal_list»;																													*
 *			WHILE @@FETCH_STATUS = 0																																	*
 *			BEGIN																																						*
 *				«cursor_code»																																			*
 *				FETCH «cursor_name» INTO «varaibal_list»																												*
 *			END 																																						*
 *		CLOSE «cursor_name»																																				*
 *		DEALLOCATE «cursor_name»																																		*
 *																																										*
 * 		Um CURSOR pode ter todos mecanismos de controlo de execução, incluíndo controlo de erros - TRY - e de aplicação do modelo ACID (transacções) que se demonstram 	*
 *		na aula 14.																																						*
 * 		Também aqui, é necessário ter particular cuidado com a o posicionamento de TRY...CATCH e TRANSACTION face à iteração pois podem afectar uma iteração e/ou a 	*
 *		totalidade DO CURSOR, o que terá grande impacto na performance mas também na reversão de transações																* 
 ************************************************************************************************************************************************************************/

-- Ex.: Lista de endereços de mail dos funcionários de um departamento
/************************
 * 	MS-SQL				* 
 ************************/
SELECT * FROM HR.departments d;
SELECT * FROM HR.employees e WHERE e.DEPARTMENT_ID  = 20;

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[hr].[sp_maillist]')
                  AND type = N'P')
	DROP PROCEDURE [hr].[sp_maillist];
GO

CREATE PROCEDURE [hr].[sp_maillist](
		 @c_department INTEGER
		,@c_mails VARCHAR(MAX) OUT
		) AS
BEGIN
	DECLARE @c_mail		NUMERIC(4)

	DECLARE cursorMail CURSOR FOR
		SELECT e.EMPLOYEE_ID FROM HR.employees e WHERE e.DEPARTMENT_ID = @c_department
	
	OPEN cursorMail
		FETCH NEXT FROM cursorMail 
			INTO @c_mail
		WHILE @@FETCH_STATUS = 0
		BEGIN
-- descomentar linha abaixo para verificar progresso (tem que se apagar e criar novamente a SP)	
-- 			SELECT @c_mail,@c_mails
			IF @c_mails = '' 
				SET @c_mails = [hr].[ufn_email](@c_mail) -- usa-se a função criada na aula anterior para obter o email do funcionário na versão mais actual
			ELSE
				SET @c_mails = CONCAT(@c_mails,'; ',[hr].[ufn_email](@c_mail))
			FETCH NEXT FROM cursorMail 
				INTO @c_mail
		END
	CLOSE cursorMail
	DEALLOCATE cursorMail
END;
GO

DECLARE @mailList VARCHAR(MAX) =''
EXEC hr.sp_maillist 60,@mailList OUT
SELECT @mailList
GO

/************************************
 * 5.	Encadeamento de módulos		*
 * Programação modular avançada		*
 ************************************************************************************************************************************************************************
 * Um módulo programado pode chamar outros módulos programados, o que permite criar programas complexos com base em módulos mais simples								*
 * Esta técnica é designada por Encadeamento de Módulos Programados (ou Modular Programming Chaining)																	*
 * O encadeamento pode ser feito entre funções, entre procedimentos ou entre funções e procedimentos																	*
 * No entanto, há limitações e regras específicas para cada motor de base de dados. Apresentam-se exemplos para MS-SQL, mas estão disponíveis para MySQL/MariaDB em 	*
 * ficheiro separado 																																					*
 ************************************************************************************************************************************************************************/
-- Função para calcular a média de ordenados num departamento
-- Será chamada pelo procedimento a definir mais abaixo
IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[hr].[ufn_media]')
                  AND type = N'FN')
	DROP FUNCTION [hr].[ufn_media];
GO

CREATE FUNCTION [hr].[ufn_media](
	@department VARCHAR(4) = NULL 	--> departamento identificado como VARCHAR para tratar casos não numéricos (devolve média 0)
									--> definie-se DEFAULT NULL para permitir chamada sem argumento
) RETURNS NUMERIC(9,3)  
AS
BEGIN
 	DECLARE  @media NUMERIC(9,3)
			,@department_id NUMERIC(4)

	SET @department_id = TRY_CAST(@department AS NUMERIC(4))	--> verificação de parametro numérico

 	IF (@department IS NULL)  
 		SET @media = (SELECT AVG(SALARY) FROM employees)
 	ELSE
 		SET @media = (SELECT AVG(SALARY) FROM employees e WHERE e.DEPARTMENT_ID=@department_id)

	RETURN ISNULL(@media,0)
END
GO

SELECT [hr].[ufn_media](10);
SELECT [hr].[ufn_media](NULL);
SELECT [hr].[ufn_media](888);
SELECT [hr].[ufn_media]	('a');
GO

-- Procedimento para classificar o ordenado de um funcionário face à média do seu departamento
-- Utiliza a função ufn_media definida acima
IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[hr].[sp_salGrade]')
                  AND type = N'P')
	DROP PROCEDURE [hr].[sp_salGrade];
GO

CREATE PROCEDURE [hr].[sp_salGrade]
	 @employee decimal
	,@e_salGrade varchar(100) OUT
	,@e_salary NUMERIC(9,3) OUT
	,@d_average NUMERIC(9,3) OUT
AS
BEGIN
	DECLARE @e_department NUMERIC(4);

	SELECT @e_salary = e.SALARY, @e_department = e.DEPARTMENT_ID 
		FROM hr.employees e 
		WHERE e.EMPLOYEE_ID = @employee;

	SET @d_average = (SELECT [hr].[ufn_media](@e_department));
	
	IF (@e_salary < @d_average) 
    	SET @e_salGrade = 'abaixo da média';
    ELSE
    	IF (@e_salary = @d_average)
    		SET @e_salGrade = 'na média';
    	ELSE
    		SET @e_salGrade = 'acima da média';
END
GO

-- Chamada ao procedimento sp_salGrade
DECLARE  @salGrade VARCHAR(100)
		,@salary NUMERIC(9,3)
		,@average NUMERIC(9,3)

SELECT @salGrade = ' ', @salary = 0, @average = 0;
EXEC hr.sp_salGrade 100, @salGrade OUTPUT,@salary OUTPUT,@average OUTPUT;
SELECT @salGrade AS 'avaliação',@salary AS 'Ordenado',@average AS 'Média';

SELECT @salGrade = ' ', @salary = 0, @average = 0;
EXEC hr.sp_salGrade 180, @salGrade OUTPUT,@salary OUTPUT,@average OUTPUT;
SELECT @salGrade AS 'avaliação',@salary AS 'Ordenado',@average AS 'Média';


-- Note-se que nem todas as invocações são possíveis
-- Por exemplo, há limitações para chamar SP dentro de funções
-- As limitações variam entre implementações, pelo que não se darão exemplos no presente contexto

/************************************
 * EXTRA							*
 * HASHING							*
 ************************************/
 -- Uma forma de encriptar dados é utilizar HASHING, que consiste em gerar um código hash para um valor tornando-o indecifrável
 -- O HASH não é passivél de reversão, verificar um valor com hashing implica produzir uma nova HASH com o valor de pesquisa
 -- e comparar o resultado com a HASH guardada
 -- O método é particularmente ajustado para encriptar passwords, embora requeira alguns cuidados quando utilizada em cliente de base de dados
 -- e.g., O HASHING é feito no servidor, pelo que a string a encriptar é enviada do cliente 'desprotegida'; 
 --		  Todos os queries executados na base de dados são passiveis de registo no T-Log, o que significa que a string ficará aí guardada não encriptada
 --
 -- Quando se trabalha em segurança, e não só, é necessário analisar cenários antes de decidir sobre a solução
 -- No caso do HASHING, é necessário ponderar se há comunicação insegura antes da encriptação e a algoritmia de produção de dados antes da encriptação

 -- A utilização de SALT (string adicional misturada com a string a encriptar) e algoritmos de construção (múltiplas iterações de HASHING) são recomendáveis
 -- para aumentar a segurança do HASHING 
 /************************
  * 	MS-SQL			 * 
  ************************/
 -- Função: HASHBYTE()
 -- Sintaxe:
 --		HASHBYTES ( '«algoritmo»', «string» )
-- ex.:
	SELECT HASHBYTES('SHA2_512', 'mypass');  
	
-- Ao contrário do MySQL, aqui só existe uma função de encriptação, mas podem-se utilizar vários algoritmos
-- Nas versões mais recentes do MS-SQL, apenas estão diponíveis os algoritmos SHA2-256 e SHA2-512
-- Em versões mais antigas estão disponíveis outros algoritmos, como os já referidos para o MysQL - MD5, SHA, SHA1 e outros ainda mais antigos

-- Podem utilizar-se mecanismos para incremento de segurança com SALT e algoritmos de construção 
-- ex.:
 DECLARE @mypass AS VARCHAR(20) = 'mypass';
 DECLARE @salt AS VARCHAR(20) = 'salt';

 SELECT HASHBYTES('SHA2_512',CONCAT(@mypass,@salt));

-- Mais informação para uso de encriptação em MS-SQL, fica o link:
-- https://learn.microsoft.com/en-us/sql/t-sql/functions/cryptographic-functions-transact-sql?view=sql-server-ver16