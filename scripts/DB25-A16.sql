/********************************************************************************
 * Aula 16														  	12/2025 	*
 * LIG/LEI/LCD/LMC															 	*
 *																			 	*
 * Programação Parte IV: Tratamento de Erros									*
 *	- TRY ... CATCH																*
 ********************************************************************************/
USE ULHT_DB25;

/************************************************************************************************************************************************************************
 * Eventos: TRIGGER																																						* 
 ************************************************************************************************************************************************************************/
 
/************************************************************************************************************************************************************************
 * No forma exemplificado, o procedimento pode ser utilizado para garantir a coerência dos dados numa alteração à tabela, mas exige que se invoque um procedimento		*
 * Podemos associar este comportamento a instruções correntes do SQL, por exemplo, forçar a escrita em JOB_HISTORY (com ERROR HANDLING) sempre que seja alterado o JOB	*
 * de um funcionário, sem a necessidade de utilizar instruções solidárias mas mantendo o comportamento ACID da BD														*
 * Para esse efeito, utiliza-se o objecto TRIGGER																														*
 ************************************************************************************************************************************************************************
 * Os TRIGGER, tal como funções e procedimentos, são módulos programaveis e fazem parte do sub-set DDL																	*
 * 																																										*
 * TRIGGER é um evento detectado pelo DB ENGINE e que permite evocar a execução diferida de código, ou seja, código que não faz parte do comando executado. Este código *
 * podem ser instruções simples, inserida no próprio TRIGGER, ou compostas (Procedimento), chamado a partir do código do TRIGGER										*
 * Mais detalhes sobre TRIGGERS em https://dev.mysql.com/doc/refman/8.4/en/triggers.html																				*
 * 																																										*
 * O TRIGGER tem três caracteristicas particulares resultantes do seu comportamento diferido:																			*
 * 1. Por ser uma instrução diferida, não chamado do DB Client, o TRIGGER não apresenta resultados para utilizador. Pretendendo-se passar alguma informação, incluíndo	*
 *	  de tratamento de excepções, ao utilizador/cliente, será necessário que a mesma seja transmitida ao código que invocou o TRIGGER									*
 * 2. Declaração do evento que 'dispara' o TRIGGER																														*
 *	  Os TRIGGER pode ser associados a qualquer das instruções de transação - INSERT, UPDATE e DELETE - e pode ser executados antes ou depois da insrtução. É possivél	*
 *	  definir TRIGGER para tratar simultaneamente multiplas instruções, mas cada TRIGGER apenas pode ter um tipo														*
 *	  Assim, a sintaxe do TRIGGER, qualquer que seja a implementação, terá a seguinte estrutura base:																	*
 *		CREATE TRIGGER «trigger_name»																																	*
 *			«trigger_action» «trigger_events»																															*
 *		Onde:																																							*
 *			«trigger_events» ::= «trigger_event»|«trigger_event»,«trigger_events»																						*
 *			«trigger_event» ::= {INSERT|UPDATE|DELETE}																													*
 *			«trigger_action» varia consoante a implementação																											*
 *			A indicação do objecto ancora para o trigger também irá varias com a implementação																			*
 * 3. Tratamento de erros																																				*
 *	  Como já referido em 1., o TRIGGER é executado de forma diferida, i.e., é executado num thread diferente da instrução/módulo que gera o evento que o chama, o que 	*
 *	  significa que tem um âmbito diferente para o tratamento de excepções. Um erro que ocorra no TRIGGER interrompe a execução do código, do próprio mas também do que	*
 *    evento que o chamou, mas a causa não é visível fora do próprio TRIGGER, o que impossibilita a sua apresentação no cliente											*
 *	  Para contornar esta limitação, 'recicla-se' o erro do TRIGGER de modo a que seja detectável no thread do evento.													*
 *	  Esta reciclagem tem sintaxe diferente consoante a implementação:																									*
 *		- em MySQL é colocada como parâmetro do HANDLER de excepção:																									*
 *			DECLARE [EXIT|CONTINUE] HANDLER FOR «execpcion» RESIGNAL «handler_code»																						*
 *		  O RESIGNAL passa ao código base o erro ocorrido no TRIGGER, sem permitir qualquer alteração																	*
 *		  Também se pode utilizar o SQLSTATE SIGNAL, que veremos mais à frente
 *		- em MS-SQL sinala-se um erro/excepção no final do bloco CATCH																									*
 *			...																																							*
 *			END TRY																																						*
 *			BEGIN CATCH																																					*
 *				«catch_code»																																			*
 *				RAISE [ERROR|EXCEPTION] «error_code»																													*
 *			END CATCH																																					*
 *		  O MS-SQL tem a vantagem de poder reportar erro personalizado , diferente do que se verificou dentro do TRIGGER												*
 *	  Note-se que, em ambos os casos, ao ser assinalado um erro para o evento que chama o TRIGGER, a resposta deste será tratada por HANDLER/CATCH e dependerá deste 	*
 *	  para cancelar ou não a transação																																	*
 *	  																																									*
 ************************************************************************************************************************************************************************
 * Os TRIGGER pode ser utilizados em qualquer instruçãoo que implique transação: INSERT, UPDATE e DELETE																*
 * 																																										*
 * Embora os TRIGGER funcionem sobre todos os comandos de transação, eles próprio não podem conter transações (na prática, não podem conter COMMIT ou ROLLBACK, seja	*
 * implicitamente ou explicitamente) uma vez que o TRIGGER actua dentro da transação que é criada pelo comando que gerou o evento										*
 *	  																																									*
 ************************************************************************************************************************************************************************
 *	Para poder perceber bem a operação de um TRIGGER, é necessário rever o funcionamento de transações e o processo interno no DB Engine entre o comando de alteração e *
 *	a escrita desta na DB Store de forma persistente																													*
 *	De uma forma resumida, sempre que há uma transação, o DB Engine guarda 2 cópias das entidades a alterar. Não é uma cópia integral, mas, neste momento, os detalhes 	*
 *	não são importantes, como também não é analisar o comportamento quando a transação implica alterações solidária em multiplas entidades.								*
 *	Estas cópias, efémeras por natureza, existem apenas na sessão a proprietária da transação e não podem ser consultadas, ou de qualquer forma manipuladas por código	*
 *	do cliente... mas podem ser acedidas em programação que seja executada dentro desse mesmo âmbito efémero, ou seja, TRIGGER											*
 *	  																																									*
 *	Assim, o DB Engine tem acesso a duas entidades efémeras (pseudo entidades) durante a execução do TRIGGER: 															*
 *		Entidade com novos dados (MySQL: NEW; MS-SQL: INSERTED) 																										*
 *		Entidade com dados removidos (MySQL: OLD; MS-SQL: DELETED) 																										*
 *		- Não há entidade com dados alterados, a alterações terá 1 registo em cada uma das tabelas 																		*
 *	De notar que em MySQL, particularmente como o uso da indicação FOR EACH ROW, a entidade efemera é um tupulo único com a estrutura da tabela onde inside o TRIGGER; 	*
 *	enquanto que em MS-SQL, a entidade é uma tabela 																													*
 *	Outra diferença é que em MS-SQL não se deve utilizar a tabela base dentro do TRIGGER, a arquitectura do MS-SQL indicará sempre que esta tabela já tem o valor final	*
 *	O correcto é verificar o valor anterior utilizando a pseudo-tabela DELETED e o novo estado utilizando a INSERTED. Já em MySQL, esta comparação será realizada		*
 *	comparando os valores de OLD e NEW com a tabela base do TRIGGER																										*
 *	  																																									*
 *	Tendo acesso a estas entidades, o código do TRIGGER pode ser bastante complexo, inclusive, pode altear os dados a inserir na tabela, calculando valores que não 	*
 *	constem da isntrução ou mesmo alterar os que dela constem 																											*
 ************************************************************************************************************************************************************************/
-- Ex. 1: TRIGGER para inserção de histórico (com ERROR HANDLING) sempre que seja alterada a função de um funcionário

/************************ 
 * 	MS-SQL				* 
 ****************************************************************************************
 *	SINTAXE:																			*
 *	CREATE TRIGGER [«schema_name».]«trigger_name»										*
 *		ON «trigger_object»																*
 *		«trigger_action» «trigger_events» 												*
 *		AS																				*
 *		Onde:																			*
 *			«trigger_events» ::= «trigger_event»|«trigger_event»,«trigger_events»		*
 *			«trigger_event» ::= {INSERT|UPDATE|DELETE}									*
 *			«trigger_action» ::= {FOR|INSTEAD OF|AFTER}									*
 *			«trigger_object» ::= «table_name»											*
 *																						*
 *	FOR:		o TRIGGER é executado antes de se concretizar o efeito do código que o	*
 *				chamou, podendo impedir que esse código seja concluído					*
 *	INSTED OF:	O TRIGGER é executado em substituição do evento, que não surtirá efeito	*
 *				Ao contrário dos outros, APENAS PODE EXISTIR 1 PARA CADA EVENTO na 		*
 *				mesma tabela															*
 *	AFTER:		o TRIGGER é executado após conclusão do código que lhe deu origem. 		*
 *				Permte acções complementares, não reverte os efeitos do código original	*
 ****************************************************************************************/
 IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[hr].[tr_NewJob]')
                  AND type = N'TR')
	DROP TRIGGER [hr].[tr_NewJob];
GO

CREATE TRIGGER hr.tr_NewJob
	ON hr.employees
	FOR UPDATE
	AS
BEGIN 
-- Decalaração de variáveis locais
	DECLARE @oldStart_date DATE;
	DECLARE	@oldJob_ID 	VARCHAR(10);
	DECLARE @oldDepartment_ID int;

	DECLARE @inEmployee_ID int;

	BEGIN TRY
		SET @inEmployee_ID = (SELECT i.employee_ID FROM INSERTED i) 
		
		IF ((SELECT d.job_id FROM DELETED d) <> (SELECT i.job_id FROM INSERTED i)) 
													-- > DELETED 	:: identificação da tabela temporária com dados APAGADOS
													-- > INSERTED 	:: identificação da tabela temporária com dados INSERIDOS
		BEGIN
-- inserir linha em [Job_history]			
			SELECT @oldJob_ID = e.job_id, @oldDepartment_ID = e.department_id
				FROM employees e
				WHERE e.EMPLOYEE_ID = @inEmployee_ID;
		
			SET @oldStart_date = COALESCE((SELECT TOP 1 jh.END_DATE 
												FROM hr.job_history jh 
												WHERE jh.EMPLOYEE_ID = @inEmployee_id 
												ORDER BY jh.END_DATE DESC)
										,(SELECT e.Hire_date 
												FROM hr.employees e 
												WHERE e.EMPLOYEE_ID = @inEmployee_ID));
		   
		    INSERT INTO hr.job_history(employee_id,START_DATE,END_DATE,JOB_ID,DEPARTMENT_ID)
		    	VALUES(@inEmployee_ID,@oldStart_date,GETDATE(),@oldJob_ID,@oldDepartment_ID);
		END
	END TRY
	BEGIN CATCH
		DECLARE	 @ErrorMessage	nvarchar(4000) = CONCAT('tr_NewJob',ERROR_MESSAGE())
				,@ErrorSeverity int = ERROR_SEVERITY()
				,@errorState int = ERROR_STATE()
		RAISERROR(@ErrorMessage,@ErrorSeverity,@errorState)
	END CATCH
END -- TRIGGER
GO

SELECT * FROM hr.employees e WHERE EMPLOYEE_ID = 100;
SELECT * FROM hr.job_history jh WHERE jh.EMPLOYEE_ID = 100;
SELECT * FROM hr.jobs j;

SELECT * FROM hr.departments d;

UPDATE hr.employees 
	SET job_id = 'AD_PRES' WHERE EMPLOYEE_ID = 100;

UPDATE hr.employees 
	SET DEPARTMENT_ID = 100 WHERE EMPLOYEE_ID = 100;

UPDATE hr.employees 
	SET job_id = 'AD_VP' , DEPARTMENT_ID = 100 WHERE EMPLOYEE_ID = 100;
	

DELETE FROM hr.job_history WHERE EMPLOYEE_ID = 100;

UPDATE hr.employees 
	SET job_id = 'ERRO' WHERE EMPLOYEE_ID = 100;
	
/************************************************************************************************************************************************************************
 * NOTAS para MSSQL: (Des)Activar eventos/TRIGGER																														*
 * 	Em grande medida, um TRIGGER é um mecanismo para implementar regras de negócio, pode-se dizer que funciona como uma CONSTRAINT, mas de forma mais elaborada pois 	*
 *	permite acção diferida ou implementação de logica funcional complexa e não restringe de forma rígida os dados dda tabela (tem mais flexibilidade).					*
 * 	Sendo comparavel com o uso de CONSTRAINT, retem destas alguns comportamentos uteis, nomeadamente a possibilidade de ser (des)activado progrmaticamente mediante as 	*
 *	necessidades																																						*
 ************************************************************************************************************************************************************************/
-- 1. Desactivar TRIGGER
ALTER TABLE [HR].[EMPLOYEES] DISABLE TRIGGER [tr_NewJob]

-- 2. Antes do evento
SELECT * FROM hr.EMPLOYEES WHERE employee_id=100
SELECT * FROM HR.JOB_HISTORY WHERE EMPLOYEE_ID=100

-- 3. Evento de UPDATE
UPDATE HR.EMPLOYEES			
	SET  job_id = 'AD_PRES'
	WHERE EMPLOYEE_ID = 100

-- 4. Após evento
SELECT * FROM hr.EMPLOYEES WHERE employee_id=100
SELECT * FROM HR.JOB_HISTORY WHERE EMPLOYEE_ID=100

-- 5. Activar TRIGGER
ALTER TABLE [HR].[EMPLOYEES] ENABLE TRIGGER [tr_NewJob]
 
-- Ex. 2: TRIGGER para impedir eliminação de linhas (UNDELETE)
/************************ 
 * 	MS-SQL				* 
 ************************/
IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[hr].[tr_NewJob]')
                  AND type = N'TR')
	DROP TRIGGER [hr].[tr_NoDelJobHistory];
GO

CREATE TRIGGER [HR].[tr_NoDelJobHistory]
ON [HR].[JOB_HISTORY]
FOR DELETE
AS 
BEGIN
	IF @@TRANCOUNT = 0
		RETURN
	ELSE
	BEGIN
		RAISERROR ('Nao se pode apagar registos de cadastro',10, 1) --> serve apenas para feedback aplicacional
		ROLLBACK
	END
END

SELECT * FROM hr.employees e WHERE e.EMPLOYEE_ID  = 100;
SELECT * FROM hr.job_history jh;

UPDATE hr.employees 
	SET job_id = 'AD_VP' , DEPARTMENT_ID = 60 WHERE EMPLOYEE_ID = 100;
	
DELETE FROM hr.job_history WHERE EMPLOYEE_ID = 100;
/************************************************************************************************************************************************************************
 * 	NOTAS:																																								*
 * 	O TRIGGER acima impede a eliminação de registos na tabela JOB_HISTORY, mas o erro assinalado não é capturado no cliente, apenas o ROLLBACK é efectuado.				*
 *	Para se conseguir reportar o erro ao cliente, deve-se utilizar tratamento de excepções visto anteriormente, envolvendo o código do TRIGGER em TRY/CATCH				*
 ************************************************************************************************************************************************************************/
-- Exercicio: TRIGGER para UPDATE INSTEAD OF INSERT
-- 			  O TRIGGER deve detectar se a chave já existe e, em caso verdadeiro, passar a UPDATE do registo

-- Antes da resolução: 	Será que se cria conflito com TRIGGER em cascata?
--						De que forma o TRIGGER irá impedir o erro (duplicação de PK)?