/********************************************************************************
 * Aula 07														  23/10/2024 	*
 * LIG/LEI/LCD/LMC															 	*
 *																			 	*
 * DDL: Definição de estrutura:						 							*
 *		Definir tabelas: CREATE													*
 *		- Sintaxe base															*
 *		- Tipos de dados														*
 *		Restrições																*
 *		- Qualidade de dados: CHECK; NN											*
 *		- Integridade: PK; UK/AK/UN												*
 ********************************************************************************/
use ULHT_DB25;
 

-- Conjunto de instruções DDL: CREATE, ALTER e DROP
-- Objectos de DDL: TABLE, VIEW e INDEX

/********************************************************************************
 * 1. Criação de tabelas: CREATE                                                *
 ********************************************************************************/
CREATE TABLE temp (
    EMPLOYEE_ID 	int 			NOT NULL,
    FIRST_NAME 		nvarchar(20) 	DEFAULT NULL, 	--  pode ficar vazio
    LAST_NAME 		nvarchar(25) 	NOT NULL, 		--  preenchimento obrigatorio
    EMAIL 			varchar(25),
    PHONE_NUMBER 	varchar(20) 	NULL,
    HIRE_DATE 		date 			DEFAULT GETDATE() NOT NULL,
    JOB_ID 			varchar(10) 	NOT NULL,
    SALARY 			decimal(12,2) 	NULL,
    COMMISSION_PCT 	decimal(3,2) 	DEFAULT 0 NULL, --  por defeito o funcionario não tem comissão
    MANAGER_ID 		int 			NULL,
    DEPARTMENT_ID 	int 			NULL,
    CONSTRAINT EMP_EMAIL_UK UNIQUE (EMAIL),
    CONSTRAINT EMP_EMP_ID_PK PRIMARY KEY (EMPLOYEE_ID)
);

INSERT INTO temp (EMPLOYEE_ID, LAST_NAME, JOB_ID,HIRE_DATE,COMMISSION_PCT,EMAIL)
VALUES (2, 'Silva', '1',DEFAULT,NULL,'' );

SELECT * FROM temp;

SELECT CAST(0 AS DATETIME);
SELECT CAST(45938.1 AS DATETIME);
SELECT DATEDIFF(DAY,GETDATE(), CAST(0 AS DATETIME));
-- TIPOS DE DADOS (básicos)
-- 1. Alfanuméricos
-- 	  VARCHAR(n) : String de dimensão variável com «n» caracteres de comprimento máximo
-- 	  CHAR(n)	 : String de dimensão fixa com «n» caracteres, espaço extra preenchido com " " (espaço)
--    TEXT       : String de dimensão vairável com comprimento máximo de 2GB
--      NOTA: 
--      Todos os tipos alfabéticos têm versão UNICODE (preceder o tipo por N - e.g.: NVARCHAR(n))
--       Idêntico a VARCHAR, mas com texto guardado em UNICODE; ocupa mais espaço por incluir a tipificação de idioma	
-- 2. Numéricos
--    DECIMAL(n[,m]): Numeral em notação decimal, «n» digitos dos quais «m» são decimais
-- 	  MSSQL suporta valores numéricos em notação binária 
-- 		Inteiros:(TINYINT (8), SMALLINT (16), INT (32), BIGINT(64))
-- 		Decimais:(REAL (32), FLOAT (64))
-- 3. Tempo
-- 	  TIME: hora em formato "hh:mm:ss"
-- 	  DATE: data em formato "aaaa-mm-dd"
-- 	  DATETIME/DATETIME2: data e hora em formato "aaaa-mm-dd hh:mm:ss.ffffff"
-- 	  DATETIMEOFFSET: data e hora em formato "aaaa-mm-dd hh:mm:ss.ffffff"
-- 		DATETIME e DATETIMEOFFSET são semelhantes, diferindo apenas no facto da segunda converter o valor para UTC
-- 		o que significa que guarda a TIMEZONE da data e garante unicidade do valor
-- 		Em consequência, DATETIMEOFFSET tem range mais reduzido pela necessidade de guardar a TIMEZONE	
-- 4. Outros (que são muitos...), apenas os mais relevantes
-- 	  SQL_VARIANT       : guarda informação não tipificada
--    UNIQUEIDENTIFIER  : Utilizado para gerar identificadores 
-- 	  JSON/XML          : guarda informação em formato nativo 
--    IMAGE             : Semelhante a TEXT, mas em formato binário
--    CURSOR            : Variavel de iteração
--
--      NOTA: O MS-SQL permite tipo de dados de utilizador sobre a forma de tabelas
-- 
-- Mais informação em: https://learn.microsoft.com/en-us/sql/t-sql/data-types/data-types-transact-sql?view=sql-server-ver16

SELECT * FROM information_schema.COLUMNS t WHERE t.TABLE_NAME LIKE '%temp%'; 

CREATE TABLE temp (
	EMPNO		DECIMAL(4)				NOT NULL, 
	ENAME		VARCHAR(10)		DEFAULT		NULL,
	JOB			VARCHAR(9)		DEFAULT		NULL, 
	MGR			NUMERIC(4,0)	DEFAULT		NULL, 
	HIREDATE	DATE			DEFAULT		NULL, 
	SAL			NUMERIC(7,2)	DEFAULT		NULL, 
	COMM		NUMERIC(7,2)	DEFAULT 0	NULL, 
	DEPTNO		NUMERIC(2,0)	DEFAULT		NULL
);
-- NOTA:
-- Não indicando SCHEMA, qualquer nova tabela será adiciona ao schema padrão [dbo]
-- EXTRA: obter informação de uma tabela em MS-SQL
-- forma simples, com função de SGBD
EXECUTE sp_help 'temp';
GO
--  NOTA:
--  Para maior detalhe, é necessário utilizar sysObjects 
SELECT * FROM INFORMATION_SCHEMA.COLUMNS c WHERE c.TABLE_NAME = 'temp' AND c.TABLE_SCHEMA = 'dbo';

-- Formato MySQL: SHOW
-- SHOW CREATE TABLE temp;

-- Apagar tabela - DROP - antes de novo exemplo
-- -> Mais detalhes sobre o DROP mais à frente
DROP TABLE temp;

-- CREATE TABLE (com controlo de erro)
IF OBJECT_ID('temp', 'U') IS NULL
    CREATE TABLE temp (
        EMPNO		NUMERIC(4,0)				NOT NULL, 
        ENAME		VARCHAR(10)		DEFAULT		NULL,
        JOB			VARCHAR(9)		DEFAULT		NULL, 
        MGR			NUMERIC(4,0)	DEFAULT		NULL, 
        HIREDATE	DATE			DEFAULT		NULL, 
        SAL			NUMERIC(7,2)	DEFAULT		NULL, 
        COMM		NUMERIC(7,2)	DEFAULT 0	NULL, 
        DEPTNO		NUMERIC(2,0)	DEFAULT		NULL
    );

-- Criar chaves
-- 1. Chaves primárias
-- 	  3 possibilidades:	
-- 		(i). No CREATE em linha: Indicação de PRIMARY KEY é indicada na coluna apropriada

IF OBJECT_ID('temp', 'U') IS NULL
    CREATE TABLE temp (
            EMPNO		NUMERIC(4,0)	NOT NULL PRIMARY KEY, 
            ENAME		VARCHAR(10)		DEFAULT	NULL,
            JOB			VARCHAR(9)		DEFAULT	NULL, 
            MGR			NUMERIC(4,0)	DEFAULT	NULL, 
            HIREDATE	DATE			DEFAULT	NULL, 
            SAL			NUMERIC(7,2)	DEFAULT	NULL, 
            COMM		NUMERIC(7,2)	DEFAULT 0	NULL, 
            DEPTNO		NUMERIC(2,0)	DEFAULT	NULL
    );
-- 		Restrições:
-- 		. Só permite PK simples, não pode ser utilizada caso a PK tenha mais do que 1 coluna
-- 		. não permite nome personalizado para a PK
--         
-- 		(ii). No CREATE como instrução independente: CONSTRAINT
IF OBJECT_ID('temp', 'U') IS NULL
    CREATE TABLE temp (
            EMPNO		NUMERIC(4,0)	NOT NULL,          --  Não esquecer a virgula...
                CONSTRAINT PK_EMP PRIMARY KEY(empno), 
            ENAME		VARCHAR(10)		DEFAULT	NULL,
            JOB			VARCHAR(9)		DEFAULT	NULL, 
            MGR			NUMERIC(4,0)	DEFAULT	NULL, 
            HIREDATE	DATE			DEFAULT	NULL, 
            SAL			NUMERIC(7,2)	DEFAULT	NULL, 
            COMM		NUMERIC(7,2)	DEFAULT 0	NULL, 
            DEPTNO		NUMERIC(2,0)	DEFAULT	NULL
        );
-- 		Restrições:
-- 		. Permite qualquer número de colunas separadas por virgula (,)
-- 		. Permite atribuição de nome é restrição
-- 		NOTA:
-- 		Embora a sintaxe SQL permita a atribuição de nomes a qualquer CONSTRAINT, incluindo PK,
-- 		o MSSQL ignora esta indicação utilizando sempre o nome 'PRIMARY'
-- 
-- 		Sintaxe:
-- 			CREATE(
-- 				...,
-- 				CONSTRAINT [«identificador»] PRIMARY KEY («colunas»)
-- 			
-- 			onde:
-- 				«colunas» ::= «coluna»|«coluna»,«colunas»
-- 
-- 		(iii). De forma autonoma: Adição de constraint em instruçãoo separada ALTER
-- 			1. Criar tabela
IF OBJECT_ID('temp', 'U') IS NULL
    CREATE TABLE temp (
            EMPNO		NUMERIC(4,0)				NOT NULL, 
            ENAME		VARCHAR(10)		DEFAULT		NULL,
            JOB			VARCHAR(9)		DEFAULT		NULL, 
            MGR			NUMERIC(4,0)	DEFAULT		NULL, 
            HIREDATE	DATE			DEFAULT		NULL, 
            SAL			NUMERIC(7,2)	DEFAULT		NULL, 
            COMM		NUMERIC(7,2)	DEFAULT 0	NULL, 
            DEPTNO		NUMERIC(2,0)	DEFAULT		NULL
        );
-- 			A tabela tem que ser criada sem PK, caso contrário haverá erro na segunda tentativa de criação de chave
-- 
-- 			2. Adicional PK: ALTER
ALTER TABLE temp
        ADD CONSTRAINT PK_EMP PRIMARY KEY(empno);
--  NOTA:
--  Também aqui, pode ser utilizada a verificação de exitência da tabela para evitar erros
--  O código passa a ser:
--      IF OBJECT_ID('temp', 'U') IS NOT NULL
--          ADD CONSTRAINT PK_EMP PRIMARY KEY(empno);
       
ALTER TABLE temp
	DROP CONSTRAINT PK_EMP;
-- 		NOTA:
-- 		EM MySQL, como a PK não tem nome, a sintaxe passa a:
-- 		ALTER TABLE temp
--			DROP PRIMARY KEY;	


-- 	Convém verificar se a tabela existe antes de criar a chave, caso contrário haverá erro...
-- 	Para evitar o erro de criar um PK quando já existe, pode-se verificar a existência de PK antes de a tentar criar
-- 	Para isso recorre-se ao INFORMATION_SCHEMA
SELECT * FROM information_schema.TABLE_CONSTRAINTS tc 
		WHERE tc.TABLE_NAME = 'temp';
-- 			Note-se que 'TEMP' na instrução é o valor de uma coluna (numa tablea de sistema),
--          não o nome de uma tabela, daí ser referido como literar ('TEMP') e não como objecto ([TEMP])


/********************************************************************************
 * 2. Altração de tabelas: ALTER                                                *
 ********************************************************************************/
-- 1. adicionar colunas ADD
IF OBJECT_ID('temp', 'U') IS NOT NULL
ALTER TABLE temp
	ADD NIF CHAR(9) NOT NULL;  

SELECT * FROM temp;    

-- 1.1. Multiplas colunas
IF OBJECT_ID('temp', 'U') IS NOT NULL
ALTER TABLE temp ADD 
	 NIF CHAR(9) NOT NULL
	,morada VARCHAR(100) DEFAULT NULL
;

-- 	A utilização de NOT NULL na adição de colunas pode levantar problemas caso a tabela tenha dados
--  Para evitar este erro deve-se adicionar o parâmetro DEFAULT:  
IF OBJECT_ID('temp', 'U') IS NOT NULL
ALTER TABLE temp
	ADD NIF CHAR(9) NOT NULL;
-- Deve ser substituido por:
IF OBJECT_ID('temp', 'U') IS NOT NULL
ALTER TABLE temp
	ADD NIF CHAR(9) DEFAULT '999999999' NOT NULL;
-- Após adição da nova coluna (com valor DEFAULT) pode-se alterar a nulidade da coluna para garantir a qualidade dos dados    

SELECT * FROM temp t;

-- 2. adicionar restrições: ADD CONSTRAINT
--    Já se viu uma pequena amostra antes com PK...
IF OBJECT_ID('temp', 'U') IS NOT NULL
ALTER TABLE temp
	ADD CONSTRAINT AK_emp_nif UNIQUE(NIF);
-- o tipo UNIQUE implementa o conceito de CHAVE CANDIDATA ou CHAVE ALTERNATIVA
-- Garantindo a unicidade de outra coluna, ou conjunto de colunas, além da PK
-- É importante para a implementação de referência entre tabelas, como se verá futuramente
-- Mais sobre tipos de restrições na próxima aila

-- 3. Eliminar colunas
IF OBJECT_ID('temp', 'U') IS NOT NULL
ALTER TABLE temp
	DROP COLUMN nif;
--  NOTA: A coluna é eliminada de forma irreversível mesmo que contenha valores 
--        MAs não será eliminada se for referenciada por chave estrangeira (a ver futuramente)   

SELECT * FROM temp t;

-- 4. alterar colunas: ALTER ... ALTER COLUMN
--    As alterações a colunas são limitadas e podem recorrer a sintaxe diferente consoante a alteração
--    Em MSSQL só se permite alterar tipo de dados e nulidade
--    Alteração de nome e valor DEFAULT têm sintaxe própria
IF OBJECT_ID('temp', 'U') IS NOT NULL
ALTER TABLE temp
	ALTER COLUMN NIF VARCHAR(12); -- possivel porque o tipo de dados é compativel
-- 	
-- NOTA: uma coluna não pode ser alterada se sobre ela insidirem dependências 
--      ex.: pelo código acima, a coluna [NIF] tem restrições DEFAULT e UNIQUE
-- 		Esta regra pode ser implementada de forma diferente consoante o fabricante
-- 		e pode ter impactos diferentes caso a tabela esteja povoada ou não	

-- 4.1. Alterar nome de uma coluna
--      EM MSSQL utiliza-se uma função própria: sp_rename
EXEC sp_rename 'temp.nif', 'nfiscal', 'COLUMN';

-- Nas outras implementações, a sintaxe correcta utiliza ALTER TABLE (...) RENAME
-- O comando anterior passaria a 
--  ALTER TABLE temp
--      RENAME COLUMN nif TO nfiscal;

-- 4.2. Adicionar DEFAULT
--      Nas versões mais recentes, o DEFAULT é tratado como CONSTRAINT, assumindo a sintaxe vista anteriormente
--      ex.:
IF OBJECT_ID('temp', 'U') IS NOT NULL
ALTER TABLE temp
    ADD CONSTRAINT df_nif DEFAULT '999999999' FOR nfiscal;

-- O MSSQL continua a permitir que o DEFAULT seja definido na instrução CREATE (ou ALTER (...) ADD)
-- Mas é mais adequado a adopção de modelo CONSTRAINT porque permite maior flexibilidade, como veremos à frente no DROP

-- 5. retirar colunas: ALTER TABLE ... DROP COLUMN
IF OBJECT_ID('temp', 'U') IS NOT NULL
ALTER TABLE temp
	DROP COLUMN nfiscal; 
-- 	
-- NOTA: Mantêm-se as restrições referidas acima  

-- 6. retirar constraints: ALTER TABLE ... DROP CONSTRAINT
IF OBJECT_ID('temp', 'U') IS NOT NULL
ALTER TABLE temp
        DROP CONSTRAINT AK_emp_nif;
--        
-- É preciso saber o nome da CONSTRAINT...

-- 6.1. Caso particular do DEFAULT
--      Quando o DEFAULT é definido na instrução CREATE ou ALTER (...) ADD, não lhe é atribuído explicitamente um nome
--      O nome é gerado pelo próprio SGBD, para garantir a integridade do INFORMATION_SCHEMA
--      Para eliminar o DEFAULT, é necessário descobrir esse nome:
SELECT d.name
FROM sys.default_constraints d
INNER JOIN sys.columns c ON d.parent_object_id = c.object_id AND d.parent_column_id = c.column_id
WHERE c.object_id = OBJECT_ID('temp') AND c.name = 'nfiscal';

--      De seguida, elimina-se a CONSTRAINT com o nome devolvido pelo query anterior
IF OBJECT_ID('temp', 'U') IS NOT NULL
ALTER TABLE temp
        DROP CONSTRAINT DF__temp__NIF__7F2BE32F;
-- NOTA:
--  1. O nome da CONSTRAINT é gerado automaticamente e de forma aleatória, será sempre diferente a cada utilização
--  2. Não se podem utilizar subqueries para flexibilizar o código
--     Apenas o uso de código dinâmico permitira esse funcionamento, como veremenos em aulas futuras

-- Noutras implementações e em versões antigas do SGBD MSSQL, o DROP DEFAULT é mais simples
-- Mas requer um tratamento diferenciado dos sysobjects
-- O comando acima seria:
--  ALTER TABLE temp
--    ALTER COLUMN nfical DROP DEFAULT;

/********************************************************************************
 * 3. Apagar tabelas: DROP                                                      *
 ********************************************************************************/
-- Provavelmente, a instrução mais simples de toda a linguagem...
-- ... Mas também a mais perigosa:
-- 
-- Apagar uma tabela: DROP TABLE
DROP TABLE temp;    -- E é só...
                    -- Toda a tabela e o seu conteúdo é apagada definitivamente

-- Apagar tabela: DROP TABLE (com controlo de execução)
IF OBJECT_ID('temp', 'U') IS NOT NULL
    DROP TABLE temp;
-- 
-- NOTA:
-- A instrução DROP é irreversível...
-- ... mas não será executada caso existam restrições de integridade sobre colunas, como referido antes
       
-- Extra: LOAD
-- 		  Importar dados de ficheiros externo
-- 		NOTA:
-- 		Só é permitido carregar dados para tabelas existentes
-- 		Comecemos por criar uma tabela com o formato dos dados a importar
CREATE TABLE temp(
		 empno	    NUMERIC(4)				NOT NULL 	PRIMARY KEY
		,enome	    VARCHAR(10)	            NOT	NULL
		,sal	    NUMERIC(7,2)		    DEFAULT 0	NULL
        ,hiredate   DATE                    DEFAULT     NULL
	);  

/********************************************************************************
 * Importar dados de ficheiros											        *
 * NOTAS:                                                                       *
 * A sintaxe apresentada é específica para MS-SQL a correr em container Docker  *
 * com acesso directo por terminal (alojado em host local)                      *
 * O comando é executado primáriamente para docker - docker run - e, dentro     *
 * para o servidor MS-SQL - bcp                                                 *
 * A execução do comando requer a instalação da extensão mssql-tools para SQL - *
 * --mcr.microsoft.com/mssql/server:2022-latest - que só será processado caso   *
 * não existam já                                                               *
 * A versão adequada para exportar ficheiros em servidores não containerizados  *
 * ou não locais pode ser muito diferente                                       *
 *                                                                              *
 * A sintaxe importa ficheiro em formato unicode sem cabeçalho (parametro -F)   *
 ********************************************************************************/
-- Em Windows (executar em terminal powershell)
docker run --rm -v ${PWD}:/work --entrypoint /opt/mssql-tools18/bin/bcp mcr.microsoft.com/mssql/server:2022-latest «TABELA» in /work/«nomeFicheiro».csv -S host.docker.internal,1433 -U sa -P "«PASSWORD»" -u -c -t "," -r "\r\n" -F 1
-- onde
--  «PASSWORD»      ::= MSSQL_SA_PASSWORD do servidor local
--  «TABELA»        ::= Tabela onde serão colocados os dados importados
--                      A inserção segues as regras gerais de INSERT, incluíndo verificação de restrições, integridade e referências
--                      Como o script é executado a partir da shell, tem que ser definido contexto
--                      e.g. comando USE ou URL completo na identificação da tabela
--  «nomeFicheiro»  ::= Nome do ficheiro a importar
--                      No exemplo, o ficheiro está na pasta onde é executado o comando - '.\' 
--                      A localização pode ser alterada indicando caminho completo, mas é necessário ter atenção a permnissões de escrita
-- A importação acrescenta dados à tabela, se as restrições desta o permitirem

-- Em MacOS/Linux (executar em teminal/bash) 
docker run --rm -v "$PWD":/work --entrypoint /opt/mssql-tools18/bin/bcp mcr.microsoft.com/mssql/server:2022-latest «TABELA» in /work/«nomeFicheiro».csv -S host.docker.internal,1433 -U sa -P '«PASSWORD»' -u -c -t "," -r "\n" -F 1
-- onde
--  «PASSWORD»      ::= MSSQL_SA_PASSWORD do servidor local
--  «TABELA»        ::= Tabela onde serão colocados os dados importados
--                      A inserção segues as regras gerais de INSERT, incluíndo verificação de restrições, integridade e referências
--                      Como o script é executado a partir da shell, tem que ser definido contexto
--                      e.g. comando USE ou URL completo na identificação da tabela
--  «nomeFicheiro»  ::= Nome do ficheiro a importar
--                      No exemplo, o ficheiro está na pasta onde é executado o comando
--                      A localização pode ser alterada indicando caminho completo, mas é necessário ter atenção a permnissões de escrita
-- A importação acrescenta dados à tabela, se as restrições desta o permitirem

-- Verificar importação
SELECT * FROM dbo.temp;

DELETE FROM temp;

DROP TABLE temp;

-- Tambem se pode importar com comando SQL e directamente de ficheiros do host do servidor 
-- Neste caso, o ficheiro tem que ser local ou mapeada para o container
-- Como se utilizam vários dominios de segurança diferentes - File System e SQL Server, acrescidos de Docker 
-- se ambiente containerizado - há complexidade e dificuldade acrescidas 

-- A sintaxe base será
BULK INSERT temp
FROM '«caminho»\ficheiroDados.csv'  -- Atenção ao separador de pastas: '\' em Windos; '/' em MacOS, Linux e Containers Docker
WITH (
    FIELDTERMINATOR = ',', -- Indicação de separador de calores (e.g.',' em ficheiros CSV)
    ROWTERMINATOR = '\n',  -- Mudança de linha (e.g.'\n' ou '\r\n' em ficheiros de base Windows)
    FIRSTROW = 2           -- Linhas a retiorar no inicio (Util se o ficheiro tiver cabeçalho)
);

-- O MSSQL também permite aceder directamente a um ficheiro externo utilizando a função OPENROWSET
-- para o efeito, é ncessário configurar a opção Ad Hoc Distributed Queries 
-- Também aqui, o ficheiro tem que ser local ou mapeado para container
EXEC sp_configure 'show advanced options', 1;       --> permitir configuração avançado do servidor
RECONFIGURE;                                        --> força a aplicação das alkterações
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;  --> activar a opção Ad Hoc Distributed Queries
RECONFIGURE;

-- Aceder ao ficheiro 
SELECT *
FROM OPENROWSET(
    BULK '«caminho»\ficheiroDados.csv',  -- Atenção ao separador de pastas: '\' em Windos; '/' em MacOS, Linux e Containers Docker
    FORMATFILE = 'C:\Path\To\YourFormatFile.xml',
    SINGLE_BLOB
) AS DataFile;

 
/********************************************************************************
 * Exportar ficheiros											                *
 * NOTAS:                                                                       *
 * A sintaxe apresentada é específica para MS-SQL a correr em container Docker  *
 * com acesso directo por terminal (alojado em host local)                      *
 * O comando é executado primáriamente para docker - docker run - e, dentro     *
 * para o servidor MS-SQL - sqlcmd                                              *
 * A execução do comando requer a instalação da extensão mssql-tools para SQL - *
 * --rm mcr.microsoft.com/mssql-tools:latest - que só será processado caso não  *
 * existam já                                                                   *
 * A versão adequada para exportar ficheiros em servidores não containerizados  *
 * ou não locais pode ser muito diferente                                       *
 *                                                                              *
 * A sintaxe exporta ficheiro em formato unicode sem cabeçalho                  *
 * Também se pode exportar em formato XML e com adição de cabeçalho, sendo que  *
 * este é introduzido por código ou por APPEND aos dados de tabela              *
 ********************************************************************************/
-- Em Windows (executar em terminal powershell)
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S host.docker.internal,1433 -U sa -P "«PASSWORD»" -C -Q "SET NOCOUNT ON; «QUERY»" -s "," -W -h -1 | Out-File -FilePath .\«nomeFicheiro».csv -Encoding utf8
-- onde
--  «PASSWORD»      ::= MSSQL_SA_PASSWORD do servidor local
--  «QUERY»         ::= Script SQL a executar
--                      Tem que produzir resultado em formato de tabela, mas pode ser código complexo
--                      Como o script é executado a partir da shell, tem que ser definido contexto
--                      e.g. comando USE ou URL completo na identificação da tabela (ou outra origem de dados)
--  «nomeFicheiro»  ::= Nome do ficheiro de saida de dados
--                      No exemplo, o ficheiro será colocado na pasta onde é executado o comando - '.\' 
--                      A localização pode ser alterada indicando caminho completo, mas é necessário ter atenção a permnissões de escrita
-- A exportação pode acrescentar dados a ficheiro existente colocando o parametro '-append' no final da instrução
-- (...)| Out-File -FilePath .\«nomeFicheiro».csv -Encoding utf8 -append
 
-- Em MacOS/Linux (executar em teminal/bash)
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S host.docker.internal,1433 -U sa -P '«PASSWORD»' -C -Q "SET NOCOUNT ON; «QUERY»" -s "," -W -h -1 > «nomeFicheiro».csv
-- onde
--  «PASSWORD»  ::= MSSQL_SA_PASSWORD do servidor local
--  «QUERY»     ::= Script SQL a executar
--                  Tem que produzir resultado em formato de tabela, mas pode ser código complexo
--                  Como o script é executado a partir da shell, tem que ser definido contexto
--                  e.g. comando USE ou URL completo na identificação da tabela (ou outra origem de dados)
--  «nomeFicheiro»  ::= Nome do ficheiro de saida de dados
--                      No exemplo, o ficheiro será colocado na pasta onde é executado o comando
--                      A localização pode ser alterada indicando caminho completo, mas é necessário ter atenção a permnissões de escrita
-- A exportação pode acrescentar dados a ficheiro existente utilizando sintaxe própria de Unix/Linux (> passa a >>)
--  (...) -W -h -1 >> «nomeFicheiro».csv

-- Mais informação em: https://learn.microsoft.com/en-us/sql/relational-databases/import-export/overview-import-export?view=sql-server-ver16
