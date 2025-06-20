
--1. PROCESO DE ASIGNACION DE CUENTAS CAMPAÑAS PREDICTIVO

USE BD_COBROS
declare @fecha datetime set @fecha = '06-06-2025'
declare @grupos varchar(200) = 'ADM'
declare @productos varchar(200) = '4,19'
declare @ejec_cpñ INT 

DECLARE @RUTA VARCHAR(150),@GRUPO VARCHAR(5), @table_html nvarchar (max),@DOC_RESULT NVARCHAR(2000), @sCommand varchar(8000), 
		@NombreArchivo varchar(200),@NombreArchivo2 varchar(200), @TIPOS_GESTION VARCHAR(MAX), @SCRIPT NVARCHAR(MAX), @ASUNTO VARCHAR(150), @PRODUCTO_ARCHIVO VARCHAR(100)

/* OBTENER CODIGOS DE CARTERA QUE SE ENVIAN POR PARAMETRO (@productos) Y OBTENER LOS CODIGOS DE PRODUCTO RELACIONADOS A ESA CARTERA*/
DECLARE @TABLAPRODUCTOS TABLE(COD_PRODUC TINYINT, NOM_CARTERA VARCHAR(50), ORDEN TINYINT, SI_PRELEGAL BIT) 
INSERT INTO @TABLAPRODUCTOS 
SELECT DISTINCT P.COD_PRODUC, C.NOM_CARTERA, C.ORDEN, ISNULL(C.SI_PRELEGAL,0)
FROM BD_COBROS.dbo.Split(@productos,',') S
JOIN BD_COBROS..PROD_CARTERA P ON p.COD_PRODUC = S.splitdata AND P.SI_ACTIVO = 1
JOIN BD_COBROS..CARTERA C ON P.COD_CARTERA = C.COD_CARTERA AND C.SI_ACTIVO = 1


SELECT 	@PRODUCTO_ARCHIVO = CASE WHEN P.COD_PRODUC IN (4,19) AND @grupos ='P' THEN 'PRELEGAL'
                                 WHEN P.COD_PRODUC IN (10) THEN 'BOL'
								 WHEN  P.COD_PRODUC IN (4,19) THEN CONCAT('ADMINISTRATIVA - GRUPO ',@GRUPOS)
								 WHEN P.COD_PRODUC IN (50,54,55,70) THEN CONCAT('COMPRADA - GRUPO ',@GRUPOS)
								 WHEN P.COD_PRODUC IN (68) THEN CONCAT('CRECOS - GRUPO ',@GRUPOS)
								 ELSE 'OTROS' END,
		@ejec_cpñ = CASE WHEN P.COD_PRODUC IN (4,19) THEN 634
		                 WHEN P.COD_PRODUC IN (10) THEN 634
								 WHEN P.COD_PRODUC IN (50,54,55,70) THEN 634
								 WHEN P.COD_PRODUC IN (68) THEN 634
								 WHEN P.COD_PRODUC IN (4,19,50,54,55,70,10) THEN 634
								 ELSE 'OTROS' END
FROM @TABLAPRODUCTOS P


/* OBTENER GRUPOS QUE SE ENVIAN POR PARAMETRO (@grupos)*/
DECLARE @TABLAGRUPOS TABLE(GRUPO VARCHAR(50), NOM_USUARI VARCHAR(200), NUM_USUARI INT) 
INSERT INTO @TABLAGRUPOS 
SELECT G.GRUPO, G.NOM_USUARI, G.NUM_USUARI
FROM BD_COBROS.dbo.Split(@grupos,',') S
JOIN BD_COBROS..GRUPOS G ON G.GRUPO = S.splitdata 


SET @TIPOS_GESTION = 'CP,CI,CD'
set @NombreArchivo = 'PREDICTIVO_ROMERO_'+@PRODUCTO_ARCHIVO+'_'+CONVERT(VARCHAR(10),@fecha,112)+'.xls'
set @NombreArchivo2 = 'CAMBIOS_PREDICTIVO_'+@PRODUCTO_ARCHIVO+'_'+CONVERT(VARCHAR(10),@fecha,112)+'.txt'
PRINT @NombreArchivo

--Códigos efectivos para asignación
DECLARE @TBL_COD_GESTIO TABLE(COD_GESTIO VARCHAR(5)) 
INSERT INTO @TBL_COD_GESTIO 
SELECT DISTINCT G.COD_GESTIO
FROM BD_COBROS.dbo.Split(@TIPOS_GESTION,', ') S
JOIN BD_COBROS..GESTION G ON G.COD_GESTIO= S.splitdata

	CREATE TABLE ##LISTADO_ASIGNA (
		COD_PRODUC INT,					COD_DEUDOR INT,						PORTAFOLIO VARCHAR(250),				
		APE_DEUDOR VARCHAR(MAX),					
		NOM_DEUDOR VARCHAR(MAX),		CEDULA VARCHAR(15),					NUM_PRODUC VARCHAR(25),
		MINIMO MONEY,					CAPITAL MONEY,						FEC_GESTIO DATETIME,				
		DES_GESTIO VARCHAR(MAX),		COD_GESTIO VARCHAR(5),				DES_SEGUIM VARCHAR(MAX),		
		FEC_ULTMOD DATETIME,			CODUSU_ULTMOD INT,					USU_ULTMOD VARCHAR(250),		
		CONTACTO VARCHAR(250),			TIPO_CONTACTO VARCHAR(250),			FEC_GESTIOAB DATETIME,				
		DES_GESTIOAB VARCHAR(MAX),		
		COD_GESTIOAB VARCHAR(5),		MONTO_CP MONEY,						FEC_ULTMODAB DATETIME,			
		CODUSU_ULTMODAB INT,			USU_ULTMODAB VARCHAR(MAX),			COD_NUEVO_EJE INT,				
		NUEVO_EJEC VARCHAR(MAX),		CAMBIAR BIT DEFAULT 0,				TIPO_CPÑ VARCHAR(100),
		ID_REGISTRO INT			
	)


SELECT P.* into #ctas FROM PLANCAMPAÑAS P
JOIN @TABLAPRODUCTOS TP ON TP.COD_PRODUC = P.COD_PRODUC
WHERE P.FECDESDE = @fecha
AND P.COD_EJECUT = @ejec_cpñ
AND P.PROCESADO = 'True'
AND NOT SUBSTRING(P.APE_DEUDOR,1,3) IN ('CP.', 'CD.', 'CI.')

--SELECT * FROM #ctas

INSERT INTO ##LISTADO_ASIGNA (COD_PRODUC, COD_DEUDOR, PORTAFOLIO, APE_DEUDOR, NOM_DEUDOR, CEDULA, NUM_PRODUC, MINIMO, CAPITAL, FEC_GESTIO, DES_GESTIO,
								COD_GESTIO, DES_SEGUIM, FEC_ULTMOD, CODUSU_ULTMOD, USU_ULTMOD, CONTACTO,TIPO_CONTACTO,
								FEC_GESTIOAB, DES_GESTIOAB, COD_GESTIOAB, MONTO_CP, FEC_ULTMODAB, CODUSU_ULTMODAB, 
								USU_ULTMODAB,TIPO_CPÑ, ID_REGISTRO)
select	DISTINCT p.cod_produc, p.cod_deudor , 
		CTR.NOM_CARTERA,
		p.ape_deudor, p.nom_deudor, deu.num_cedruc, deu.num_produc, 
		ma.min_mes, ma.saldo_capital, d.fec_gestio, REPLACE(replace(REPLACE(BD_COBROS.dbo.FX_ELIMINAENTER(D.DES_gestio),CHAR(9),' '),'  ',' '),'  ',' '), d.cod_gestio, REPLACE(replace(REPLACE(BD_COBROS.dbo.FX_ELIMINAENTER(D.DES_SEGUIM),CHAR(9),' '),'  ',' '),'  ',' '),
		d.fec_ultmod, d.usu_ultmod, d.nom_usuari, d.nom_est, d.tipo_cont, d1.fec_gestio, REPLACE(replace(REPLACE(BD_COBROS.dbo.FX_ELIMINAENTER(D1.DES_gestio),CHAR(9),' '),'  ',' '),'  ',' '), 
		d1.cod_gestio, d1.monto_cp, d1.fec_ultmod, d1.usu_ultmod, d1.nom_usuari, 4, P.ID_REGISTRO
from #ctas c
JOIN BD_COBROS..PROD_CARTERA PRC ON PRC.COD_PRODUC = c.COD_PRODUC
JOIN BD_COBROS..CARTERA CTR ON CTR.COD_CARTERA = PRC.COD_CARTERA
join plancampañas p on p.id_registro = c.id_registro
join deudor deu on deu.cod_produc = c.cod_produc and deu.cod_deudor= c.cod_deudor
LEFT JOIN BD_LICITACION..[Ama_Matriz_Amazonas] MA ON MA.CREDITO = deu.NUM_PRODUC AND MA.IDENTIFICACION = deu.NUM_CEDRUC
left join (select * from(
				select d.cod_produc, d.cod_deudor, d.fec_gestio, d.des_gestio, d.cod_gestio, d.des_seguim, d.fec_ultmod, d.usu_ultmod, u.nom_usuari, e.nom_est,
							isnull(case when e.cod_est in (17,18) then 'directo'
						when e.est_op2= 1 then 'indirecto'
						else 'sin contacto' end, 'sin contacto') as tipo_cont,
						row_number() over (partition by d.cod_produc, d.cod_deudor order by d.fec_ultmod desc) id_gest
				from bd_cobros..diario d
				join bd_cobros..usuarios u on u.num_usuari = d.usu_ultmod and u.tip_usuari = 'E'
				left join bd_cobros..estados e on e.cod_est = d.cod_contact and e.tip_est ='ctcllam'
				join #ctas c on c.cod_produc= d.cod_produc and c.cod_deudor = d.cod_deudor
				where d.fec_ultmod = (select max(r.fec_ultmod) from diario r
									  join bd_cobros..gestion g on g.cod_gestio = r.cod_gestio and g.si_campaña_bjr = 1
									  where c.cod_produc= r.cod_produc and c.cod_deudor = r.cod_deudor and r.fec_ultmod >= @fecha
									  AND NOT r.USU_ULTMOD IN (824,260)
									  and r.si_gestion = 1 )
				and d.si_gestion = 1 and D.fec_ultmod >= @fecha
				AND NOT D.USU_ULTMOD IN (824,260)
				) d where d.id_gest=1
) d on d.cod_produc = c.cod_produc and d.cod_deudor = c.cod_deudor
left join (select * from(
				select d.cod_produc, d.cod_deudor, d.fec_gestio, d.des_gestio, d.cod_gestio, d.des_seguim, d.fec_ultmod, d.usu_ultmod, u.nom_usuari, d.val_saldo as monto_cp,
						row_number() over (partition by d.cod_produc, d.cod_deudor order by d.fec_ultmod desc) id_gest
				from bd_cobros..diario d
				JOIN @TBL_COD_GESTIO T ON T.COD_GESTIO = d.COD_GESTIO
				join bd_cobros..usuarios u on u.num_usuari = d.usu_ultmod and u.tip_usuari = 'E'
				join #ctas c on c.cod_produc= d.cod_produc and c.cod_deudor = d.cod_deudor
				where d.fec_ultmod = (select max(r.fec_ultmod) from diario r
									  JOIN @TBL_COD_GESTIO T ON T.COD_GESTIO = r.COD_GESTIO
									  join bd_cobros..usuarios uR on uR.num_usuari = r.usu_ultmod and uR.tip_usuari = 'E'
									  where c.cod_produc= r.cod_produc and c.cod_deudor = r.cod_deudor
									  and r.fec_ultmod >= @fecha
									  --and r.cod_gestio in ('cp', 'ci', 'cd', 'ccd', 'co')
									  and r.si_gestion = 0)
				and d.si_gestion = 0  and d.fec_ultmod >= @fecha
				--and d.cod_gestio in ('cp', 'ci', 'cd', 'ccd', 'co')
				) d1 where d1.id_gest=1
) d1 on d1.cod_produc = c.cod_produc and d1.cod_deudor = c.cod_deudor
order by d1.cod_gestio desc

--SELECT * FROM ##LISTADO_ASIGNA WHERE NOT USU_ULTMOD IS NULL

--C. DETERMINAR CUENTAS A ASIGNAR
		UPDATE L
		SET L.FEC_GESTIOAB = R1.FEC_GESTIO,
			L.DES_GESTIOAB = BD_COBROS.dbo.FX_ELIMINAENTER(R1.DES_GESTIO),
			L.COD_GESTIOAB = R1.COD_GESTIO,
			L.MONTO_CP = R1.MONTO_CP,
			L.FEC_ULTMODAB = R1.FEC_ULTMOD,
			L.CODUSU_ULTMODAB = R1.USU_ULTMOD,
			L.USU_ULTMODAB = R1.NOM_USUARI
		FROM ##LISTADO_ASIGNA L
		JOIN (SELECT  R1.COD_PRODUC, R1.COD_DEUDOR, R1.FEC_GESTIO, R1.DES_GESTIO, R1.COD_GESTIO,R1.VAL_SALDO AS MONTO_CP,
								R1.FEC_ULTMOD, R1.USU_ULTMOD, U.NOM_USUARI 
						FROM BD_COBROS..DIARIO R1
						JOIN BD_COBROS..USUARIOS U ON U.NUM_USUARI = R1.USU_ULTMOD --AND U.TIP_USUARI ='E'
						WHERE R1.COD_PRODUC IN (50,54,55,70) AND R1.SI_GESTION = 0
						AND R1.FEC_ULTMOD >= @fecha
						AND R1.fec_ultmod = (select max(r.fec_ultmod) from bd_cobros..diario r
											where R1.cod_produc= r.cod_produc and R1.cod_deudor = r.cod_deudor
											and r.fec_ultmod >= @fecha
											and r.si_gestion = 0)) R1 ON R1.COD_PRODUC = L.COD_PRODUC AND R1.COD_DEUDOR= L.COD_DEUDOR
		WHERE COD_GESTIOAB IS NULL


		UPDATE L
		SET CAMBIAR = 1,
			COD_NUEVO_EJE = CODUSU_ULTMODAB ,
			NUEVO_EJEC =  USU_ULTMODAB 
		from ##LISTADO_ASIGNA L 
		join BD_COBROS..DEUDOR D ON D.COD_PRODUC= L.COD_PRODUC AND D.COD_DEUDOR = L.COD_DEUDOR
		JOIN @TABLAGRUPOS G ON G.NUM_USUARI = L.CODUSU_ULTMODAB
		JOIN @TBL_COD_GESTIO T ON T.COD_GESTIO = COD_GESTIOAB
		--WHERE D.COD_EJECUT<>CODUSU_ULTMODAB
		



--determina cuentas a asignar
	--relacionadas
	select distinct L.cod_produc, L.cod_deudor, L.CEDULA, L.num_produc, L.NUEVO_EJEC, L.COD_NUEVO_EJE, 'PRD' AS TIPO_ASIGNA
	INTO ##CAMBIAR_EJEC
	FROM ##LISTADO_ASIGNA L
	JOIN DEUDOR D ON D.COD_PRODUC = L.COD_PRODUC AND D.COD_DEUDOR = L.COD_DEUDOR
	JOIN @TABLAPRODUCTOS TP ON TP.COD_PRODUC = D.COD_PRODUC
	--LEFT JOIN GRUPOS G ON G.NUM_USUARI = D.COD_EJECUT AND NOT G.GRUPO = 'CC' 
	WHERE L.CAMBIAR = 1 AND D.COD_EJECUT <> L.COD_NUEVO_EJE
	and not D.COD_EJECUT in (select num_usuari from GRUPOS where GRUPO in('cc','es'))
	
	

	INSERT INTO ##CAMBIAR_EJEC
	select distinct d.cod_produc, d.cod_deudor, d.num_cedruc, d.num_produc, L.NUEVO_EJEC, COD_NUEVO_EJE, 'REL' AS TIPO_ASIGNA
	from deudor d
	join ##LISTADO_ASIGNA L ON L.CEDULA = D.NUM_CEDRUC and L.NUM_PRODUC <> D.NUM_PRODUC
	JOIN @TABLAPRODUCTOS TP ON TP.COD_PRODUC = D.COD_PRODUC
	join situacio s on s.cod_situac = d.cod_situac 
	where d.si_retira = 0
	and s.si_ctavig = 1
	and d.dias_vencidos >= 0
	and d.cod_ejecut <> L.COD_NUEVO_EJE
	AND L.CAMBIAR = 1
	AND NOT EXISTS (SELECT * FROM ##CAMBIAR_EJEC C
					WHERE C.NUM_PRODUC = D.NUM_PRODUC)
	
	
	DELETE C
	FROM ##CAMBIAR_EJEC C
	JOIN BD_COBROS..DEUDOR D ON D.COD_PRODUC = C.COD_PRODUC AND D.COD_DEUDOR = C.COD_DEUDOR AND D.MARCA='ADMINISTRATIVA'
	JOIN BD_COBROS..GRUPOS G ON G.NUM_USUARI = C.COD_NUEVO_EJE AND G.GRUPO='P'
	WHERE D.COD_PRODUC IN (4,19)

	/*
	DELETE C
	FROM ##CAMBIAR_EJEC C
	JOIN BD_COBROS..DEUDOR D ON D.COD_PRODUC = C.COD_PRODUC AND D.COD_DEUDOR = C.COD_DEUDOR 
	join BD_COBROS..SITUACIO S ON S.COD_SITUAC = D.COD_SITUAC AND (S.SI_CONVEN=1 OR S.SI_CONVES = 1)
	WHERE D.COD_PRODUC IN (4,19) AND D.MARCA <>'ADMINISTRATIVA'
	*/
	SELECT	/*COD_PRODUC, COD_DEUDOR, APE_DEUDOR, NOM_DEUDOR, CEDULA, NUM_PRODUC, MINIMO, CAPITAL, CONVERT(VARCHAR(10),FEC_GESTIO,103) AS FEC_GESTIO,
			DES_GESTIO, COD_GESTIO, DES_SEGUIM, CONVERT(VARCHAR(19), FEC_ULTMOD,120) AS FEC_ULTMOD,	CODUSU_ULTMOD,	
			USU_ULTMOD,	CONTACTO,	CONVERT(VARCHAR(10),FEC_GESTIOAB,103) AS FEC_GESTIOAB,	DES_GESTIOAB,
			COD_GESTIOAB,	MONTO_CP,	CONVERT(VARCHAR(19),FEC_ULTMODAB,120) AS FEC_ULTMODAB, CODUSU_ULTMODAB,	
			USU_ULTMODAB,	COD_NUEVO_EJE,	NUEVO_EJEC, CAMBIAR, CASE WHEN TIPO_CPÑ = 1 THEN 'CAMPAÑA' WHEN TIPO_CPÑ = 2 THEN 'ATC' WHEN TIPO_CPÑ = 3 THEN 'DIARIO'
			WHEN TIPO_CPÑ = 4 THEN 'PREDICTIVO'  END AS TIPO_CPÑ, ID_REGISTRO*/
			*
	INTO ##LISTADO_REPORTE 
	FROM ##LISTADO_ASIGNA
	
--E. CREAR DIRECTORIO
	SET @RUTA = 'c:\REPORTES\CAMPANAS_PREDICTIVO\GRUPO\'+CAST(YEAR(@fecha) AS VARCHAR)+'\'+CAST(MONTH(@fecha) AS VARCHAR)+'.'+UPPER(DATENAME(MONTH,@fecha))+'\'+CONVERT(VARCHAR(10),@fecha,112)
	SET @SCRIPT ='xp_cmdshell '+CHAR(39)+'mkdir '+ @RUTA +CHAR(39)
	EXECUTE sp_executesql @SCRIPT

	--F. GUARDA INFORMACION EN EL DOCUMENTO
		-- Cabecera
		select  TOP 1 @SCRIPT = 'SELECT ' +stuff( (SELECT ', '''+p2.COLUMN_NAME+''''
						   FROM tempdb.INFORMATION_SCHEMA.COLUMNS p2
						   WHERE TABLE_NAME = '##LISTADO_REPORTE'
						   AND P2.TABLE_NAME = T.TABLE_NAME
						   FOR XML PATH(''), TYPE).value('.', 'varchar(max)')
						,1,1,'')
		from  tempdb.INFORMATION_SCHEMA.COLUMNS T
		WHERE TABLE_NAME = '##LISTADO_REPORTE'

		
		SET  @sCommand  = 'bcp '+'"'+@SCRIPT+'"'+
						' queryout C:\REPORTES\CAMPANAS_PREDICTIVO\GRUPO\CABECERA.XLS -T  -c'
		PRINT @sCommand
		EXEC xp_cmdshell @sCommand 
		
		-- Datos
		SET  @sCommand  = 'bcp '+'"select * from ##LISTADO_REPORTE "'+
						' queryout C:\REPORTES\CAMPANAS_PREDICTIVO\GRUPO\DATOS.XLS -T  -c'
		PRINT @sCommand
		EXEC xp_cmdshell @sCommand 
		
		-- Merge de ambos archivos
		SET @DOC_RESULT = 'copy /b "C:\REPORTES\CAMPANAS_PREDICTIVO\GRUPO\CABECERA.XLS"+"C:\REPORTES\CAMPANAS_PREDICTIVO\GRUPO\DATOS.XLS" "'+@RUTA+'\'+ @NombreArchivo+'"'
		PRINT @DOC_RESULT
		exec master..xp_cmdshell @DOC_RESULT

		-- Borramos archivos intermedios
		exec master..xp_cmdshell 'del "C:\REPORTES\CAMPANAS_PREDICTIVO\GRUPO\DATOS.XLS"'
		exec master..xp_cmdshell 'del "C:\REPORTES\CAMPANAS_PREDICTIVO\GRUPO\CABECERA.XLS"'
		
		--GUARDA REGISTRO DE CAMBIOS
				-- Cabecera
		select  TOP 1 @SCRIPT = 'SELECT ' +stuff( (SELECT ', '''+p2.COLUMN_NAME+''''
						   FROM tempdb.INFORMATION_SCHEMA.COLUMNS p2
						   WHERE TABLE_NAME = '##CAMBIAR_EJEC'
						   AND P2.TABLE_NAME = T.TABLE_NAME
						   FOR XML PATH(''), TYPE).value('.', 'varchar(max)')
						,1,1,'')
		from  tempdb.INFORMATION_SCHEMA.COLUMNS T
		WHERE TABLE_NAME = '##CAMBIAR_EJEC'

		
		SET  @sCommand  = 'bcp '+'"'+@SCRIPT+'"'+
						' queryout C:\REPORTES\CAMPANAS_PREDICTIVO\GRUPO\CABECERA.XLS -T  -c'
		PRINT @sCommand
		EXEC xp_cmdshell @sCommand 
		
		-- Datos
		SET  @sCommand  = 'bcp '+'"select * from ##CAMBIAR_EJEC "'+
						' queryout C:\REPORTES\CAMPANAS_PREDICTIVO\GRUPO\DATOS.XLS -T  -c'
		PRINT @sCommand
		EXEC xp_cmdshell @sCommand 
		
		-- Merge de ambos archivos
		SET @DOC_RESULT = 'copy /b "C:\REPORTES\CAMPANAS_PREDICTIVO\GRUPO\CABECERA.XLS"+"C:\REPORTES\CAMPANAS_PREDICTIVO\GRUPO\DATOS.XLS" "'+@RUTA+'\'+ @NombreArchivo2+'"'
		PRINT @DOC_RESULT
		exec master..xp_cmdshell @DOC_RESULT

		-- Borramos archivos intermedios
		exec master..xp_cmdshell 'del "C:\REPORTES\CAMPANAS_PREDICTIVO\GRUPO\DATOS.XLS"'
		exec master..xp_cmdshell 'del "C:\REPORTES\CAMPANAS_PREDICTIVO\GRUPO\CABECERA.XLS"'


			--E. ARMAR REPORTES PARA CORREO
		SELECT  distinct stuff( (SELECT ', ['+T.COD_GESTIO +']'
					    FROM (select distinct COD_GESTIO from @TBL_COD_GESTIO) p2
						JOIN @TBL_COD_GESTIO T ON T.COD_GESTIO = P2.COD_GESTIO
					   ORDER BY T.COD_GESTIO
					   FOR XML PATH(''), TYPE).value('.', 'varchar(max)')
					,1,1,'') as cod
				into #gestiones
				FROM @TBL_COD_GESTIO T2

		select @TIPOS_GESTION = cod from #gestiones

		--PRINT @TIPOS_GESTION
--SET @SCRIPT ='CREATE TABLE ##RESUMEN (EJECUTIVO VARCHAR(100), '+REPLACE(REPLACE(@TIPOS_GESTION, '[CCD],', ''), ']','s] INT')+', SIN_CAMB INT
--			, TOT_GNRAL INT, TOT_EFEC INT, MONTO_CP MONEY)'
		--PRINT @SCRIPT
		--EXECUTE sp_executesql @SCRIPT

		CREATE TABLE ##RESUMEN (EJECUTIVO VARCHAR(100), CPs  INT, CIs  INT, CDs  INT, SIN_CAMB INT, TOT_GNRAL INT, TOT_EFEC INT, MONTO_CP MONEY)

		--Consolidado
		INSERT INTO ##RESUMEN
		SELECT G.NOM_USUARI,ISNULL(L.CP,0),ISNULL(L.CI,0),ISNULL(L.CD,0),
		ISNULL((SELECT COUNT(*) FROM ##LISTADO_ASIGNA A1 WHERE A1.CAMBIAR = 0 AND A1.USU_ULTMOD = G.NOM_USUARI AND A1.TIPO_CPÑ IN (4)),0) AS SIN_CAMB,
		 (SELECT COUNT(*) FROM ##LISTADO_ASIGNA A1 WHERE A1.USU_ULTMOD = G.NOM_USUARI AND A1.TIPO_CPÑ IN (4)) AS TOT_GNRAL,
		 (SELECT COUNT(*) FROM ##LISTADO_ASIGNA A1 WHERE A1.USU_ULTMOD = G.NOM_USUARI AND A1.TIPO_CPÑ IN (4) AND COD_GESTIOAB IN ('CP','CI','CD')) AS TOT_EFEC, 
		 ISNULL((SELECT SUM(MONTO_CP) FROM ##LISTADO_ASIGNA A1 WHERE A1.USU_ULTMOD = G.NOM_USUARI AND A1.TIPO_CPÑ IN (4)),0) MONTO_CP 
		FROM  GRUPOS G
		JOIN @TABLAGRUPOS T ON T.GRUPO=G.GRUPO
		LEFT JOIN (
					SELECT NUEVO_EJEC EJECUTIVO, [CP], [CI], [CD]
					FROM(
								SELECT	NUEVO_EJEC, 
										COD_GESTIOAB TIPO, 
										COUNT(*) AS CTAS
								FROM ##LISTADO_ASIGNA L
								--JOIN @TBL_COD_GESTIO T ON T.COD_GESTIO = L.COD_GESTIOAB
								WHERE CAMBIAR = 1 AND 
								TIPO_CPÑ IN (4)
								GROUP BY NUEVO_EJEC,COD_GESTIOAB 
							) A
					PIVOT (SUM(CTAS) FOR TIPO IN ([CP], [CI], [CD])) AS PVT
					) L ON L.EJECUTIVO = G.NOM_USUARI
			--LEFT JOIN ##LISTADO_ASIGNA A ON A.USU_ULTMOD = ISNULL(L.EJECUTIVO,A.USU_ULTMOD)
			
			GROUP BY G.NOM_USUARI,ISNULL(L.CP,0),ISNULL(L.CI,0),ISNULL(L.CD,0)

			SELECT * FROM ##RESUMEN
/*
SET @SCRIPT = '
					INSERT INTO ##RESUMEN
					SELECT A.USU_ULTMOD,'+REPLACE(REPLACE(REPLACE(@TIPOS_GESTION, '[CCD],', ''),'[', 'ISNULL(['), ']', '],0)')
					+', ISNULL((SELECT COUNT(*) FROM ##LISTADO_ASIGNA A1 WHERE A1.CAMBIAR = 0 AND A1.USU_ULTMOD = A.USU_ULTMOD AND A1.TIPO_CPÑ IN (4)),0)'
					+', (SELECT COUNT(*) FROM ##LISTADO_ASIGNA A1 WHERE A1.USU_ULTMOD = A.USU_ULTMOD AND A1.TIPO_CPÑ IN (4))'
					+', (' + REPLACE(REPLACE(REPLACE(REPLACE(@TIPOS_GESTION, '[CCD],', ''),',','+'),'[', 'ISNULL(['), ']', '],0)') 
					+'), SUM(A.MONTO_CP) MONTO_CP 
					FROM  (
							SELECT NUEVO_EJEC EJECUTIVO, '+REPLACE(@TIPOS_GESTION, '[CCD],', '')+'
							FROM(
								SELECT	NUEVO_EJEC, 
										CASE WHEN COD_GESTIOAB ='+CHAR(39)+'CCD'+CHAR(39)+' THEN '+CHAR(39)+'CD'+CHAR(39)+'
											 ELSE COD_GESTIOAB END AS TIPO, 
										COUNT(*) AS CTAS
								FROM ##LISTADO_ASIGNA L
								--JOIN @TBL_COD_GESTIO T ON T.COD_GESTIO = L.COD_GESTIOAB
								WHERE CAMBIAR = 1 AND 
								TIPO_CPÑ IN (4)
								GROUP BY NUEVO_EJEC, 
										 CASE WHEN COD_GESTIOAB ='+CHAR(39)+'CCD'+CHAR(39)+' THEN '+CHAR(39)+'CD'+CHAR(39)+'
											 ELSE COD_GESTIOAB END
							) A
							PIVOT (SUM(CTAS) FOR TIPO IN ('+REPLACE(@TIPOS_GESTION, '[CCD],', '')+')) AS PVT
					) L
					RIGHT JOIN ##LISTADO_ASIGNA A ON A.USU_ULTMOD = ISNULL(L.EJECUTIVO,A.USU_ULTMOD)
					GROUP BY A.USU_ULTMOD, '+REPLACE(@TIPOS_GESTION, '[CCD],', '')
				
		PRINT @SCRIPT

		EXECUTE sp_executesql @SCRIPT
		*/
		--SELECT * FROM ##RESUMEN
		DELETE FROM ##RESUMEN  
		WHERE NOT  EXISTS (SELECT NOM_USUARI FROM GRUPOS WHERE NOM_USUARI = EJECUTIVO AND GRUPO IN (SELECT DISTINCT GRUPO FROM @TABLAGRUPOS))
		
		SELECT * INTO #FINAL FROM  ##LISTADO_ASIGNA WHERE CAMBIAR = 1

		---GESTIONES DE CUENTAS SIN CONTACTO REALIZADAS POR EL EJECUTIVO
                        SELECT U.NOM_USUARI, E.NOM_EST, COUNT(*)CTAS
                        INTO #GESTIONES_SINCONT
                        FROM DIARIO R
                        JOIN BD_COBROS..USUARIOS U ON U.NUM_USUARI = R.USU_ULTMOD
                        LEFT JOIN BD_COBROS..ESTADOS E ON E.COD_EST = R.COD_CONTACT AND E.TIP_EST ='CTCLLAM'
                        WHERE FEC_GESTIO>=@fecha AND COD_GESTIO IN('PRD','LD')
                        AND R.USU_INGRES = 824 AND U.NOM_USUARI IN (SELECT DISTINCT L.EJECUTIVO FROM ##RESUMEN L)
                        GROUP BY  U.NOM_USUARI, E.NOM_EST
                        


		--F. ENVIAR INFORMACION POR CORREO
	SET @DOC_RESULT = @RUTA + '\' + @NombreArchivo

				set @table_html =
				'<html>	
				<head>
				<style type="text/css">
					p{
						 font-family: Aptos Narrow, sans-serif;
						 font-size:14px;
						 width: 90%;
					}
					table{
						 font-family: Aptos Display, sans-serif;
						 border: solid 2px;
						 border-collapse:collapse;
						 font-size:11px;
						 width: 90%;
						 }
					td	 {
						 text-align:"center";
						 }
					.izq {
						 text-align:left
						 }
					th	 {
						 text-align:"center";
						 background:"#000000"; 
						 color:"#ffc000";
						 }
				</style>
				</head>
				<body>
				<p>Estimados,</p>
				<p>
				Las siguientes cuentas fueron gestionadas el día de hoy en la campaña de predictivo.
				</p>
				<p>
				<br>
				<b>RESULTADO DE GESTION</b>
				</p>
				<table border =''1'' align = "center" width=400px>
				<tr><th>EJECUTIVO</td>
				<th>CPs</th>
				<th>CIs</th>
				<th>CDs</th>
				<th>SIN CAMB</th>
				<th>TOTAL GNRAL</th>
				<th>TOTAL EFEC</th>
				<th>%EFEC</th>
				<th>MONTO_CP</th>
				<th>CONT. DIR</th>
				<th>CONT. IND</th>
				<th>SIN CONT</th>
				</tr>'+
				cast (
				(select  td = EJECUTIVO, '',
						 td = CPs, '',
						 td = CIs, '',
						 td = CDs, '',
						 td = SIN_CAMB,'',
						 td = TOT_GNRAL,'',
						 td = TOT_EFEC,'',
						 td = TOT_EFEC_GEN,'',
						 td = MONTO_CP ,'',
						 td = ISNULL(DIRECTO,0),'',
						 td = ISNULL(INDIRECTO,0),'',
						 td = ISNULL(SIN_CONT,0)
				FROM(
				SELECT R.EJECUTIVO, 
						  ISNULL(CPs,0) CPs, 
						  ISNULL(CIs,0) CIs, 
						  ISNULL(CDs,0) CDs, 
						  ISNULL(SIN_CAMB,0) SIN_CAMB,
						  ISNULL(TOT_GNRAL,0)TOT_GNRAL,
						  ISNULL(TOT_EFEC,0)TOT_EFEC,
						  CASE WHEN TOT_GNRAL > 0 THEN CAST(CAST((CAST(TOT_EFEC AS DECIMAL(18,4))/CAST(TOT_GNRAL AS DECIMAL(18,4)))*100 AS DECIMAL(18,2)) AS VARCHAR)+' %' ELSE '0 %' END TOT_EFEC_GEN,
						  '$ '+CAST(CAST(ISNULL(MONTO_CP,0) AS DECIMAL(18,2)) AS VARCHAR)MONTO_CP,
						  ISNULL(C.DIRECTO,0)DIRECTO,
						  ISNULL(C.INDIRECTO,0)INDIRECTO,
						  ISNULL(C.SIN_CONT,0)SIN_CONT
				from    ##RESUMEN R
				LEFT JOIN (	SELECT USU_ULTMOD, ISNULL([DIRECTO],0) AS DIRECTO, ISNULL([INDIRECTO],0) AS INDIRECTO, ISNULL([SIN CONTACTO],0) AS SIN_CONT
							FROM(
							SELECT USU_ULTMOD, TIPO_CONTACTO, COUNT(*) CLI
							FROM ##LISTADO_ASIGNA
							GROUP BY USU_ULTMOD, TIPO_CONTACTO
							) A
							PIVOT( SUM(CLI) FOR TIPO_CONTACTO IN ([DIRECTO], [INDIRECTO], [SIN CONTACTO])) AS PVT
							) C ON C.USU_ULTMOD = R.EJECUTIVO
							
				UNION ALL
				SELECT 'TOTALES GENERALES', ISNULL(SUM(CPs),0),ISNULL(SUM(CIs),0),ISNULL(SUM(CDs),0),ISNULL(SUM(SIN_CAMB),0),ISNULL(SUM(TOT_GNRAL),0),ISNULL(SUM(TOT_EFEC),0),
				ISNULL(CAST(CAST((CAST(SUM(TOT_EFEC) AS DECIMAL(18,4))/CAST(SUM(TOT_GNRAL) AS DECIMAL(18,4)))*100 AS DECIMAL(18,2)) AS VARCHAR)+' %','0 %'),
				ISNULL('$ '+CAST(CAST(SUM(MONTO_CP) AS DECIMAL(18,2)) AS VARCHAR),'$ 0.00'),ISNULL(AVG(DIRECTO),0),ISNULL(AVG(INDIRECTO),0),ISNULL(AVG(SIN_CONT),0)
				FROM ##RESUMEN R
				CROSS JOIN (SELECT ISNULL([DIRECTO],0) AS DIRECTO, ISNULL([INDIRECTO],0) AS INDIRECTO, ISNULL([SIN CONTACTO],0) AS SIN_CONT 
							FROM(
								SELECT TIPO_CONTACTO, COUNT(*) CLI
								FROM ##LISTADO_ASIGNA
								GROUP BY TIPO_CONTACTO
							) A
							PIVOT( SUM(CLI) FOR TIPO_CONTACTO IN ([DIRECTO], [INDIRECTO], [SIN CONTACTO])) AS PVT) A 
				
				)A
				for xml raw('tr'), elements
				) as nvarchar (max)
				) + N'</table>
				<p>
                                               <br>
                                               <b>DETALLE DE CUENTAS SIN CONTACTO</b>
                                               </p>
                                               <table border =''1'' align = "center" width=400px>
                                               <tr><th>EJECUTIVO</td>
                                               <th>NO CONTESTARON</th>
                                               <th>NUMEROS ERRADOS</th>
                                               <th>CONTESTADORA</th>
                                               <th>COLGO</th>
                                               <th>TOTAL GNRAL</th>
                                               </tr>'+
                                               cast (
                                               (select  td = EJECUTIVO, '',
                                                                       td = ISNULL(NO_CONTESTARON,0), '',
                                                                       td = ISNULL(NUMEROS_ERRADOS,0), '',
                                                                       td = ISNULL(CONTESTADORA,0), '',
                                                                       td = ISNULL(COLGO,0),'',
                                                                       td = ISNULL(NO_CONTESTARON,0) + ISNULL(NUMEROS_ERRADOS,0) + ISNULL(CONTESTADORA,0) + ISNULL(COLGO,0),''
                                               FROM(  SELECT U.EJECUTIVO,    
                                                                       ISNULL((SELECT SUM(CTAS) FROM #GESTIONES_SINCONT G WHERE G.NOM_USUARI = U.EJECUTIVO AND G.NOM_EST = 'NO CONTESTARON'),0) NO_CONTESTARON,
                                                                       ISNULL((SELECT SUM(CTAS) FROM #GESTIONES_SINCONT G WHERE G.NOM_USUARI = U.EJECUTIVO AND G.NOM_EST = 'NUMEROS ERRADOS'),0) NUMEROS_ERRADOS,
                                                                       ISNULL((SELECT SUM(CTAS) FROM #GESTIONES_SINCONT G WHERE G.NOM_USUARI = U.EJECUTIVO AND G.NOM_EST = 'CONTESTADORA'),0) CONTESTADORA,
                                                                       ISNULL((SELECT SUM(CTAS) FROM #GESTIONES_SINCONT G WHERE G.NOM_USUARI = U.EJECUTIVO AND G.NOM_EST = 'COLGO'),0) COLGO
                                               FROM(SELECT DISTINCT EJECUTIVO FROM ##RESUMEN) U
                                               )A
											   ORDER BY (ISNULL(NO_CONTESTARON,0) + ISNULL(NUMEROS_ERRADOS,0) + ISNULL(CONTESTADORA,0) + ISNULL(COLGO,0)) DESC
                                               for xml raw('tr'), elements
                                               ) as nvarchar (max)
                                               ) + N'</table>



				<p>
				<br>
				<b>DETALLE DE CUENTAS EFECTIVAS</b>
				</p>
				<table border =''1'' align = "center" width=600px>
				<tr><th>COD</th>
				<th>PRODUCTO</th>
				<th>CLIENTE</th>
				<th>GESTON</th>
				<th>COD_GESTIO</th>
				<th>SEGUIMIENTO</th>
				<th>CONTACTO</th>
				<th>EJEC. ANT</th>
				<th>NUEV. EJEC</th>
				<th>RESULT</th>
				<th>MONTO_CP</th>
				<th>TIPO_CPN</th>
				</tr>'+
				cast (
				(select  td = F.COD_DEUDOR, '',
						 td = ISNULL(F.PORTAFOLIO,'N/A'),'',
						 td = ISNULL(F.APE_DEUDOR+' '+F.NOM_DEUDOR,'N/A'), '',
						 td = ISNULL(F.DES_GESTIO,'N/A'), '',
						 td = ISNULL(F.COD_GESTIO,'N/A'), '',
						 td = ISNULL(F.DES_SEGUIM,'N/A'), '',
						 td = ISNULL(F.CONTACTO, 'N/A'), '',
						 td = ISNULL(F.NOM_USUARI, 'N/A'),'',
						 td = ISNULL(F.NUEVO_EJEC, 'N/A'), '',
						 td = ISNULL(F.COD_GESTIOAB,'N/A'), '',
						 td = ISNULL('$'+CAST(CAST(F.MONTO_CP AS DECIMAL(18,2)) AS VARCHAR),'$0.00'), '',
						 td = ISNULL(CASE WHEN F.TIPO_CPÑ = 1 THEN 'CPÑ' WHEN F.TIPO_CPÑ= 2 THEN 'ATC' WHEN F.TIPO_CPÑ = 3 THEN 'DIA' WHEN F.TIPO_CPÑ= 4 THEN 'PRD' END,'N/A'), ''
				FROM(
					SELECT F.COD_DEUDOR, F.PORTAFOLIO, F.APE_DEUDOR, F.NOM_DEUDOR,DES_GESTIO,COD_GESTIO,DES_SEGUIM,CONTACTO,U.NOM_USUARI,NUEVO_EJEC,COD_GESTIOAB,MONTO_CP,TIPO_CPÑ
					from    #FINAL F
					JOIN BD_COBROS..DEUDOR D ON D.COD_PRODUC = F.COD_PRODUC AND D.COD_DEUDOR = F.COD_DEUDOR
					JOIN BD_COBROS..USUARIOS U ON U.NUM_USUARI = D.COD_EJECUT
					--ORDER BY COD_GESTIOAB DESC, MONTO_CP DESC
					UNION ALL
					SELECT 0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
				)F
				for xml raw('tr'), elements
				) as nvarchar (max)
				) + N'</table>	
				<br>
				<br>
				<p>Saludos cordiales,</p>	
			<img src="F:\MAPI\CORREO\Sis-Matias Pinto1.png">'+
				N'<body>'+
				N'<html>';

				SET @ASUNTO = 'RESULTADO CPÑ PREDICTIVO '+@PRODUCTO_ARCHIVO+' AL '+ convert(varchar(10),@fecha,103)
				
				set rowcount 0
				EXEC  msdb.dbo.sp_send_dbmail
				@profile_name				= 'Procesos_EJR',
				--@recipients				= 'COBRANZASJYS@ROMERODYASOCIADOS.COM',
				@copy_recipients				= 'mpinto@romerodyasociados.com',
				--@blind_copy_recipients			= 'sistemas@ROMERODYASOCIADOS.COM',
				@subject					= @ASUNTO,
				@body					= @table_html,
			--	@file_attachments 				= @DOC_RESULT,---'''' + @RUTA + '\' + @NombreArchivo + '''',
				@body_format				= 'HTML'
				
				
		/*		
				
--ACTUALIZA CAMPAÑAS DE PREDICTIVO
update p
set p.nom_usuari = c.USU_ULTMOD,
	p.nom_ejecut = c.USU_ULTMOD, 
	p.cod_ejecut= c.CODUSU_ULTMOD
--select *--p.cod_produc, p.cod_deudor, p.nom_usuari,c.USU_ULTMOD,p.nom_ejecut,c.USU_ULTMOD,p.cod_ejecut,c.CODUSU_ULTMOD 
--SELECT COUNT(*)
from ##LISTADO_ASIGNA c
join plancampañas p on p.id_registro = c.id_registro AND NOT USU_ULTMOD IS NULL
*/

/*
--INGRESA INFORMACION A HISTORICO
insert into bd_cobros..HISTEJEC (COD_PRODUC,COD_DEUDOR,COD_EJECUT,FEC_INGRES,HOR_INGRES,USU_INGRES)
select C.cod_produc, C.cod_deudor, C.COD_NUEVO_EJE, convert(varchar(10), getdate(),103), getdate(), 824
from ##CAMBIAR_EJEC C 
JOIN bd_cobros..deudor d ON C.cod_produc = d.cod_produc and C.cod_deudor = d.cod_deudor 
WHERE c.cod_nuevo_eje <> d.cod_ejecut
*/

/*
	INSERT INTO BD_COBROS.dbo.DIARIO ( COD_PRODUC, COD_DEUDOR, FEC_GESTIO, DES_SEGUIM, COD_GESTIO, COD_EJECUT, DES_GESTIO, SI_GESTION, USU_INGRES, USU_ULTMOD, FEC_SISTEM, HORA_MOD, HOR_SISTEM, FEC_ULTMOD )
	SELECT P.COD_PRODUC, P.COD_DEUDOR, CONVERT(VARCHAR(10), GETDATE(), 103), 
	CONVERT(VARCHAR(10), GETDATE(), 112)+ ' SE PROCEDE A ASIGNAR CUENTA POR EFEC. CAMPAÑA PREDICTIVO - EJECUTIVO ASIGNA: '+COD_GESTIOAB, 
	'CEJ', 0, 
	'CAMBIO DE EJECUTIVO', 
	1, 824, 824, GETDATE(),GETDATE(),GETDATE(), GETDATE()
	FROM ##LISTADO_ASIGNA P 
	join deudor d on d.cod_produc = p.cod_produc and d.cod_deudor = P.COD_DEUDOR
	WHERE CAMBIAR = 1 AND D.COD_EJECUT <> P.COD_NUEVO_EJE AND NOT USU_ULTMOD IS NULL
*/

/*
--ASIGNA CUENTAS CON NEGOCIACIONES
update d
set d.cod_ejecut = dt.COD_NUEVO_EJE, D.COD_EJECON = NULL
--select d.cod_produc, d.cod_deudor, d.cod_ejecut, dt.COD_NUEVO_EJE
from bd_cobros..deudor d 
join ##CAMBIAR_EJEC dt on dt.cod_produc = d.cod_produc and dt.cod_deudor = d.cod_deudor 
WHERE DT.cod_nuevo_eje <> d.cod_ejecut
*/

/*
DROP TABLE ##LISTADO_ASIGNA
DROP TABLE ##LISTADO_REPORTE
DROP TABLE ##RESUMEN
DROP TABLE #CTAS
DROP TABLE #CAMBIAR_EJEC

*/
