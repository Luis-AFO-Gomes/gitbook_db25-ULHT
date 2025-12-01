/********************************************************************************
 * Aula 11														  20/11/2024 	*
 * LIG/LEI/LCD/LMC															 	*
 *																			 	*
 * Transacções																	*
 * Isolamento 																	*
 * Acesso concorrencial e isolamento											*
 ********************************************************************************/
 USE ULHT_DB25;

-- Isolamento de instuções

-- 	ANTES DE INICIAR:
-- 	Verificar se a ligação tem o autocommit desligado
-- 	Normalmente, os IDE têm o AUTOCOMMIT ligado, o que resulta em que as alterações sobre a base de dados são aplicadas automáticamente assim que a instrução é concluida
-- 	Para trabalharmos com isolamento de instuções - transacções - temos que desactivar o parâmetro  
-- Em MS-SQL
select IIF(@@OPTIONS & 2 = 0, 'OFF', 'ON');
SET IMPLICIT_TRANSACTIONS OFF; -- > Apenas para o query executado depois da instrução

-- EM MySQL/MariaDB
-- SHOW VARIABLES WHERE Variable_name='autocommit';
-- SET autocommit=0;

-- Verificar nível de isolamento actual
-- Em MS-SQL
DBCC USEROPTIONS;

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

-- Em MariaDB
-- SHOW VARIABLES WHERE variable_name ='tx_isolation';
-- SHOW VARIABLES WHERE variable_name ='transaction_isolation';


-- Definir o nivel de isolamento para a sessão (DEFAULT: READ COMMITED)
-- 	Em MS-SQL
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- 	Em MySQL/MariaDB
-- SET SESSION transaction_isolation = 'repeatable-read';	

/****************************************************************************************************************************
 * O modelo relacional tem um conjunto de caracterisitcas vulgarmente designadas por ACID:                                  *
 * (A)tomicidade: Cada transacção é executada na totalidade ou não o é de todo, não se podendo ter instuções realizadas		*
 *    parcialmente                                   																		*
 * (C)onsistencia: Todas as transacões são realizadas de forma consistente e obedecendo às regras de integridade de dados 	*
 *    e referencial                                																			*
 * (I)solamento: Cada transacção é realizada de forma independente das restante, não afectando nem sendo afectada por qual-	*
 *    quer outra transacção concorrente             																		*
 * (D)urabilidade: Todos os escritos na base de dados pemanecem nela até que seja removidaos e alterados por alguma instru-	*
 * 	  ção válida                                     																		*
 *                                                                                                                          *
 * Sendo um SGBD(R) um serviço, por natureza, orientado a multiplos utilizadores concorrenciais, torna-se importante perce-	*
 * ber os mecanismos que garantem este funcionamento, particularmente, o modo como se garante o isolamento e se evita a 	*
 * inconsistência em acesso concrrenciais a dados                                      										* 
 ****************************************************************************************************************************/

/********************************************************************************
 * Para efeito da demonstração, abrir duas sessões simultâneas do cliente		*
 ********************************************************************************/

-- 1.	Transacções
-- 		COMMIT & ROLLBACK
-- 		Para exemplificação, utilizaremos um cenário com duas sessões simultaneas - em 2 IDE diferenes - e a tabela [DEPT], 
-- 		por ser simples e facilmente manipulavel
SELECT * FROM information_schema.columns WHERE TABLE_NAME = 'dept';

-- 		Limpar a tabela DEPT
DELETE FROM Scott.dept WHERE deptno >= 50;
COMMIT;
-- 		Verificar o conteudo da tabela DEPT
SELECT * FROM Scott.dept d;

-- Desligar o autocommit para a sessão (se não estiver desligado)
-- v. acima

-- 		Isolamento de transação
-- 		Consolidar as alterações: COMMIT
INSERT INTO Scott.dept
        VALUES(50,'IT','LISBOA');
-- 		Com autocommit desligado, veja-se o que acontece com a 2ª sessão...       
        
-- 		Garantir a escrita das alterações por código: COMMIT
-- 		Força a execução de todas as instuções da sessão, escrevendo na base de dados as alterações realizadas na sessão
-- 		pode ser escrito sem outra instrução
COMMIT;      
ROLLBACK;   


-- 		ou como parte da instrução
INSERT INTO scott.dept
        VALUES(60,'Logistica','PORTO');
COMMIT;

/****************************************************************************************************************************
 *	NOTA: o COMMIT sem transacção iniciada irá resultar num erro															*
 *																															* 
 * Sempre que há uma transacção, é colocado um LOCK na tabela para evitar falhas de consistência no acesso concorrencial.	*
 * O LOCK evita que outras sessões possam realizar a mesma acção em simultâneo, o que resultaria em falha de (I)solamento e	*
 * (C)onsistencia. Naturalmente, haverá problemas de bloqueio no acesso que, para o cliente, terão todo o aspecto de falha 	*
 * de desempenho e performance																								*
 *																															*
 * Os problemas de bloqueio podem ser contornados utilizando parametro NO LOCK, que é profundamente desaconselhado por 		*
 * causa dos problemas mencionados, embora possa resultar em melhoria de performance por retirar o bloqueio e espera		*  
 ****************************************************************************************************************************/       
INSERT INTO scott.emp
    VALUES(1,'Gomes','QQ',NULL,'2021-12-07',0,NULL,50);

SELECT * FROM scott.emp e;
   
-- 		Reverter as alterações: ROLLBACK
-- 		Descarta as alterações realizadas na sessão        
-- 		Utiliza-se nas mesmas duas formas que indicadas para o COMMIT
ROLLBACK;       

-- 		A mesma experiência pode ser realizada com DELETE e UPDATE
-- 	Ex.1: DELETE
DELETE FROM scott.dept 
	WHERE DEPTNO >= 50;

SELECT * FROM scott.dept d;

ROLLBACK;

-- 	Ex.2: UPDATE 
UPDATE scott.dept
	SET DNAME = 'TI' 
	WHERE DEPTNO = 50;

COMMIT;
 
/****************************************************************************************************************************
 * O isolamento evita que ocorram problemas de consistência com multiplos utilizadores simultaneos, funcionando como uma	* 
 * especie de semáforo na escrita permanente de dados. Os impactos mais relevantes são impedir a partilha directa de dados 	*
 * entre sessões e a garantia de consistência em instruções sequenciais														*
 * 																															*
 * Em MariaDB, o ISOLAMENTO em TRANSACÇÕES é definido pela variavel de sessão [tx_isolation]								*
 *-- SHOW VARIABLES WHERE variable_name ='tx_isolation';																	*
 *-- SHOW VARIABLES WHERE variable_name ='transaction_isolation';															*		
 *																															*
 * Em MS-SQL é mais complexo, já que a variável de sessão que indica o nível de isolamento é numérica:						*/
 -- 	SELECT CASE transaction_isolation_level 																			
 --					WHEN 0 THEN 'Unspecified'  																				
 --  				WHEN 1 THEN 'ReadUncommitted'  																			
 --  				WHEN 2 THEN 'ReadCommitted'  																			
 --  				WHEN 3 THEN 'Repeatable'  																				
 --  				WHEN 4 THEN 'Serializable'  																			
 --  				WHEN 5 THEN 'Snapshot' END AS TRANSACTION_ISOLATION_LEVEL  												
 -- 		FROM sys.dm_exec_sessions  																						
 -- 		WHERE session_id = @@SPID 																						
/* Onde @@SPID identifica a sessão onde está a ser executado o query. Retirando esta linha, serão apresentados o estados de	*
 * isolamento de todas as sessões do SGBD 																					* 
 ****************************************************************************************************************************
 * O valor do parâmetro pode ser alterado de 3 formas:																		*
 * 1. No ficheiro de configuração do SGBD, aplicando-se a todas as sessões abertas posteriormente							*
 * 2. Na própria sessão (não disponível em MS-SQL):																									*/
-- SET SESSION tx_isolation = 'read-committed';
-- SET SESSION transaction_isolation = 'read-committed';

/* 3. Para cada comando isolado																								*/
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
/* 	  Em MS-SQL apenas esta forma está disponível																			*/

/* Em MySQL, versão 8, a estado de ISOLAMENTO em TRANSACÇÕES é definido pela variavel de sistema:							*
 * -	@@global.transaction_ISOLATION ou 																					*
 * -	@@transaction_ISOLATION 																							*
 * para servidor e sessão respectivamente																					*
 * SELECT @@global.transaction_ISOLATION;																					*
 *																															*
 * O valor pode ser definido pelo utilizador para cada sessão utilizando o comando SET TRANSACTION ISOLATION LEVEL 			*
 * SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;																	*
 * SELECT @@transaction_ISOLATION;																							*/

/* **************************************************************************************************************************
 * Nestas duas implementações (bem como nas outras), há quatro niveis de isolamento:                                        *
 * ---------------------------------------------------------------------------                                              *
 * |Isolation Level     | Dirty Read   |Non Repeatable Read   |	   Phantom   |                                              *
 * ---------------------------------------------------------------------------                                              *
 * | READ UNCOMMITTED   | Pode ocorrer |      Pode ocorrer    | Pode ocorrer |                                              *
 * | READ COMMITTED     | Não ocorre   |      Pode ocorrer    |	Pode ocorrer |                                              *
 * | REPEATABLE READ    | Não ocorre   |      Não ocorrer     | Pode ocorrer |                                              *
 * | SERIALIZABLE       | Não ocorre   |      Não ocorrer     |	Não ocorre   |                                              *
 * ---------------------------------------------------------------------------   											*
 * Onde:																													*
 * 	- READ UNCOMMITED: permite que os dados de alterações sejam lido mesmo não existindo COMMIT								*
 *	- READ COMMITED: Permite que os dados alterados sejam lidos logo que ocorra um COMMIT, mesmo que existam outras transa-	*
 *	    			 cções pendentes (encadeadas)																			*
 *	- REPEATABLE READ: Só permite leitura de dados alterados após todas as transacções pedendetes serem consolidadas 		*
 *					   (COMMIT/ROLLBACK)																					*
 *	- SERIALIZABLE: Actua sobre transacções concorrenciais, garantindo que alterações sobre a mesma tabela são aplicadas de	* 
 *					forma sequencial sem perda de instruções																*
 * E:																														*
 *	- Dirty Read: habilidade de ler valores inseridos mas que ainda não foram consolidados (INSERT/UPDATE/DELETE whithout 	*
 *				  COMMIT)																									*
 *	- Non Repeatable Read:																									* 
 *	- Phantom Read: O mesmo query pode devolver valores diferentes sem que haja alterações na base de dados					*
 *	  				A base de ocorrência é a mesma dao Dirty Read (operação sem COMMIT), a diferença ocorre no ponto onde o *
 *					COMMIT faz efeito																						*
 *																															*
 * Mais informações sobre cada nivel de isolamento em MS-SQL:																*
 * https://learn.microsoft.com/en-us/sql/t-sql/statements/set-transaction-isolation-level-transact-sql?view=sql-server-ver16*
 * Mais informações sobre cada nivel de isolamento em MySQL:																*
 * 		https://dev.mysql.com/doc/refman/8.0/en/innodb-transaction-isolation-levels.html                                	*
 * Mais informações sobre cada nivel de isolamento em MariaDB:																*
 * 		https://mariadb.com/kb/en/mariadb-transactions-and-isolation-levels-for-sql-server-users/							*
 *																															*
 * Por defeito, o nivel de isolamento em MS-SQL é definido para READ COMMITTED                                              *
 * Já em MySQL/MariaDB (InnoDB), o nivel de isolamento é definido para REPEATABLE READ                                      *
 * Existe um 5º nivel - Snapshot, com comportamento idêntico ao Serializable - que não é implementado em MySQL				* 
 *                                                                                                                          *
 * É importante ter em conta que quanto maior for o nivel de isolamento, maior é o impacto na performance do SGDB           *															 
 ****************************************************************************************************************************/
-- 	Experiencia com transacções (Leitura em multiplas sessões)
-- 	1. READ UNCOMMITTED																			
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DELETE FROM scott.dept WHERE deptno >= 50;
COMMIT; 

INSERT INTO scott.dept
        VALUES(50,'IT','LISBOA');
        
SELECT * FROM scott.dept;   
SELECT @@TRANCOUNT;
ROLLBACK;


-- 	2. READ COMMITTED 					
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;			

DELETE FROM scott.dept WHERE deptno >= 50;
COMMIT; 

INSERT INTO scott.dept 
        VALUES(50,'IT','LISBOA');
-- Ler (SELECT) tabel EMP noutra sessão antes do COMMIT --> A segunda sessão fica em espera até que haja COMMIT/ROLLBACK		

SELECT * FROM scott.dept;

COMMIT; 

-- o Hint NO LOCK (not recommended)
-- A utilização de niveis de isolamento que não o READ UNCOMMITTED implica que o SGBD aplique bloqueios de leitura e escrita
-- à tabela, o que melhora a segurança (Consistência), mas pode levar a problemas de performance e deadlocks (o sistema parece
-- estar bloqueado)
-- Para contornar este problema, pode-se utilizar o Hint NO LOCK na leitura, que instrui o SGBD a contornar o bloqueio para 
-- fazer leituras mesmo quando o nivel de isolamento não o permita
-- Na prática, o Hint NO LOCK tem o mesmo efeito do nivel READ UNCOMMITTED
-- O SGBD não altera o nível de isolamento, mas o Hint permite que a transacção leia dados não confirmados, mas pode levar a
-- resultados inconsistentes, tal como acontece do READ UNCOMMITTED.
-- O hint só é aplicavél em leitura, mas é desaconselhado o seu uso por causa dos problemas de consistência que pode provocar
-- No entanto, pode ser útil em situações onde a performance é mais importante que a consistência dos dados ou em casos
-- específicos de análise e diagnóstico ou de risco controlado, e.g. sub-queries de desnormalização
-- Exemplo de utilização do Hint NO LOCK
SELECT * FROM scott.dept WITH (NOLOCK) WHERE deptno >= 50;

-- 	3. REPEATABLE READ
DELETE FROM scott.dept WHERE deptno >= 50;	
COMMIT

SELECT * FROM scott.dept; --> na outra sessão, alterar um linha - e.g. mudar o nome do departamento 50 - e repetir SELECT

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;

SELECT * FROM scott.dept;
SELECT @@TRANCOUNT;

-- Verificar o estado da outra sessão antes de fazer COMMIT
COMMIT;

ROLLBACK

-- Para o modo de isolamento de REPEATABLE READ e SERIALIZABLE, as transacções bloqueiam leituras concorrenciais
-- obrigando a COMMIT/ROLLBACK para que as acções sejam concluídas
-- O ROLLBACK é necessário para libertar o bloqueio, mas, na realiaddee, não há alterações a reverter

-- O REPEATBLE READ garante que não há alterações aos dados entre leituras sucessivas, desde que se inicie uma transação 
-- No entanto, não impede que outras transacções/sessões insiram novas linhas que possam influenciar os resultados das leituras

--  4. SERIALIZED TRANSACTION
DELETE FROM scott.dept WHERE deptno >= 50;	
COMMIT

SELECT * FROM scott.dept; --> na outra sessão, alterar um linha - e.g. mudar o nome do departamento 50 - e repetir SELECT

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;

SELECT * FROM scott.dept;

-- Verificar o estado da outra sessão antes de fazer COMMIT
COMMIT;
ROLLBACK;

-- O modo SERIALIZABLE garante que não há alterações no dominio dos dados entre leituras sucessivas, desde que se inicie uma transação 
-- Além de não permitir alteração de daods, também impede que outras transacções/sessões insiram novas linhas na(s) tabela(s) envolvidas na transacção
-- aberta na sessão de leitura, até que haja COMMIT/ROLLBACK nesta sessão
-- Também aqui, o ROLLBACK é necessário para libertar o bloqueio, mas, na realidade, não há alterações a reverter

/****************************************************************************************************************************
 * O modo de isolamento a utilizar depender do equilibrio entre a segurança pretendido e os recursos consumidos do SGBD ou 	*
 * mesmo da experiência de utilização. Um nivel mais baixo, como o READ UNCOMMITTED, irá beneficiar a performance mas tem 	*
 * erros relevantes; no outro extremo, os modos SERIALIZED ou REPEATABLE READ garante a melhor segurança, mas requerem		*
 * muitos resursos de sistema e irão produzir frequentes situações de aparente paragem do sistema                           *
 * Tendo em conta que uma transacção envolve uma sessão até que seja realizado COMMIT/ROLLBACK, este tempo de espera ou 	*
 * consumo de recursos pode ser bastante relevante 																			*
 *                                                                                                                          *
 * Uma forma de contornar este problema é utiliza um modo equilibrado, o padrão READ COMMITTED com LOCK é bastante adequado	* 
 * é função, e recorrer a TRANSACÇÕES DECLARADAS, isto é, iniciar transacções por código e forçar COMMIT/ROLLBACK no final	*
 * de cada instrução. Deste modo, controna-se os impacto adversos do isolamento com programação                             *
 *                                                                                                                          *
 * SINTAXE:                                                                                                                 *
 *      BEGIN TRAN[SACTION] [«nome_transacção»]                                                                             *
 *      COMMIT [«nome_transacção»]                                                                                          *
 *                                                                                                                          *
 * Havendo a necessidade de determinar se a instrução é executada corretamente, utiliza-se ERROR HANDLING, como abaixo se 	*
 * demonstra                               																					*
 ****************************************************************************************************************************/
DELETE FROM scott.dept WHERE deptno >= 50;
COMMIT; 

-- Mesmo com o AUTOCOMMIT OFF, pode-se inicar uma transacção manualmente forçando a consolidação (COMMIT ou ROLLBACK)
BEGIN TRANSACTION
        INSERT INTO scott.dept
                VALUES(50,'IT','LISBOA')
                
        SELECT * FROM scott.dept
COMMIT;

SELECT @@TRANCOUNT;
/****************************************************************************************************************************
 * Em MS-SQL, o script é considerado como uma instrução única, com o ; final a ser colocado no COMMIT (ou ROLLBACK)			*
 * Noutras implementações, e.g. MySQL, cada comando é uma instrução separada. A execução terá que ser realizada juntando 	*
 * todas as instuções como um script único 																					* 																												*
 * Ex.: MySQL																												*
 * BEGIN TRANSACTION;																										*
 * 		INSERT INTO scott.dept																								*
 * 			VALUES(50,'IT','LISBOA');																						*
 * 																															*
 *		SELECT * FROM scott.dept;																							*
 * COMMIT;																													*
 * 																															*
 * NOTA: Há outras diferenças nas sintaxes das várias implementações														*
 ****************************************************************************************************************************
 * Uma transacção não serve apenas para garantir a integridade dos dados, gerindo isolamento e concorrência, mas também 	*
 * cria um certo nível de abstração no código que permite agrupar várias instruções num único bloco de código, garantindo 	*
 * que todas as instruções são executadas com sucesso - COMMIT - ou que nenhuma delas é aplicada - ROLLBACK.				*
 * Permite agrupar várias instruções numa única transacção, garantindo que todas são executadas com sucesso					*
 * Associar transacções com controlo de erros é uma ferramenta poderosa para garantir a robustez e fiabilidade do código ao	*
 * mesmo tempo que se garante consistência nos dados.																		*
 *																															*
 * De notar que o efeitos dos níveis de isolamento continuam a ser aplicados, mesmo em transacções de multiplas linhas, o 	*
 * que pode levar a questões mais relevantes de desempenho, bloqueios e deadlocks se o código não for bem gerido 						*
 ****************************************************************************************************************************/
-- Exemplo: TRANSACÇÃO de multiplas instruções
SELECT * FROM scott.dept d;
SELECT * FROM Scott.emp e;

BEGIN TRANSACTION;
        INSERT INTO scott.dept
                VALUES(50,'IT','LISBOA');
                
        SELECT * FROM scott.dept;
               
		INSERT INTO scott.emp
		        VALUES(1,'Gomes','QQ',NULL,'2021-12-07',0,NULL,60);
-- COMMIT;

 ROLLBACK;

 SELECT @@TRANCOUNT;

-- O mesmo em MS-SQL, mas com error handling...:
-- (fica o exemplo, mas voltaremos ao error handling mais tarde com maior detalhe)
/*
BEGIN TRY
	BEGIN TRANSACTION
	        INSERT INTO hr.dept
	                VALUES(50,'IT','LISBOA')
	                
	        SELECT * FROM hr.dept
	               
			INSERT INTO hr.emp
			        VALUES(1,'Gomes','QQ',NULL,'2021-12-07',0,NULL,60)
	      
	IF @@TRANCOUNT > 0
		COMMIT
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK
	
	SELECT 'erro!'
END CATCH; */

DELETE FROM scott.emp WHERE EMPNO = 1;

/****************************************************************************************************************************
 * EXTRA: ERROR HANDLING em MySQL																							*
 ****************************************************************************************************************************
 * Como complemento formativo, e por ter uma abordagem muito diferente, aborda-se o controlo de erros e excepções próprios	*
 * de MySQL/MariaDB, não só na presente aula mas também nas seguintes, no ambito da programação em SQL.						*						*
 * Em MySQL/MariaDB, o correcto controlo de erros e excepções requer o uso de procedimentos já que não possui as variantes	*
 * existentes noutras implementações, nomeadamente a possibilidade de utilização de condicionais e de verificação de erros	*
 * para consolidar (COMMIT) ou reverter (ROLLBACK) alterações em código não seccionado (sem procedimentos)					*
 * 																															*
 * Como primeira abordagem, deve-se referir que o MySQL não usa a estrutura tradicional de TRY...CATCH.						*
 * Pelo contrário, utiliza HANDLERS, que são pré-condições declaradas como parte do bloco de instruções e activadas sempre 	*
 * que for instanciada uma exepção. Ou seja, o controlo de erro é feito por eventos capturados pelo DBEngine				*
 * 																															*
 * Assim, avançamos com programação e voltaremos ao ERROR HANDLING quando se tiverem abordado a sintaxe necessária			*
 ****************************************************************************************************************************/
