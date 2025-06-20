
--COMPROMISOS DIARIOS BCO. PACIFICO--

SELECT * 
INTO #ASI_ACT
FROM BD_CARTERAS..Asignaciones A
WHERE A.COD_PRODUC IN (4,19) AND A.FECHA_CARGA >= (SELECT CONVERT(VARCHAR(25),DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0),105)) AND A.DESCRIPCION_ESTADO = 'ADMINISTRATIVA' AND LEN(NUM_PRODUC) < 7


DECLARE @FECHA DATE = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE);
DECLARE @ASUNTO VARCHAR(200) = CONCAT('ROMERO D', CHAR(38), ' ASOCIADOS / COMPROMISOS DIARIOS AL ', CONVERT(VARCHAR(10), @FECHA, 103), ' CARTERA PREJURIDICA BCO. PACIFICO');
DECLARE @tablaHTML NVARCHAR(MAX);
set	 @tablaHTML  =
				N'<html>
<head>
<style>
    body { font-family: Arial, sans-serif; font-size: 12px; }
    table { border-collapse: collapse; width: 90%; margin: auto; }
    th, td { border: 1px solid #000000; padding: 6px; text-align: center; }
    th { background-color: #000000; color: #ffc000; }
    p { font-size: 14px; }
</style>
</head>
<body>
<p>Estimados,</p>
<p>Se adjunta el resumen de compromisos generados en la fecha <b>' + CONVERT(VARCHAR(10), @FECHA, 103) + '</b>:</p>
<table>
    <tr>
        <th>FECHA_GESTION</th>
        <th>CIFCODE</th>
        <th>PALETA</th>
        <th>FECHA_PAGO</th>
        <th>CAPITAL</th>
    </tr>'+
				cast (
				(select DISTINCT td = CAST(A.FEC_SISTEM AS DATE), '',
						 td = ASI.NUM_PRODUC, '',
						 td = CASE WHEN A.COD_GESTIO='CI' THEN 'OFRECE REFIN.' ELSE 'OFRECE MINIMO' END, '',
						 td = CAST(
    CASE 
        WHEN A.FEC_COMPROMISO < GETDATE() THEN 
            CAST(GETDATE() AS DATE)

        WHEN A.FEC_COMPROMISO IS NULL THEN 
            CAST(
                CASE 
                    WHEN DATEADD(
                            DAY, 
                            (12 - DATEPART(WEEKDAY, GETDATE())) % 7 + 7, 
                            CAST(GETDATE() AS DATE)
                         ) > EOMONTH(GETDATE()) 
                    THEN
                    
                        CASE 
                            WHEN DATENAME(WEEKDAY, EOMONTH(GETDATE())) = 'Domingo' THEN 
                                DATEADD(DAY, -2, EOMONTH(GETDATE()))
                            WHEN DATENAME(WEEKDAY, EOMONTH(GETDATE())) = 'Sábado' THEN 
                                DATEADD(DAY, -1, EOMONTH(GETDATE()))
                            ELSE 
                                EOMONTH(GETDATE())
                        END
                    ELSE 
                        DATEADD(
                            DAY, 
                            (12 - DATEPART(WEEKDAY, GETDATE())) % 7 + 7, 
                            CAST(GETDATE() AS DATE)
                        )
                END AS DATETIME
            )

        ELSE 
            CAST(A.FEC_COMPROMISO AS DATE)
    END AS DATE
)
,'',
						 td = CONCAT('$',ASI.CAPITAL),''
						 FROM bd_cobros..DIARIO  A
JOIN #ASI_ACT ASI ON ASI.COD_PRODUC = A.COD_PRODUC AND ASI.COD_DEUDOR = A.COD_DEUDOR 
JOIN BD_COBROS..DEUDOR DE ON ASI.COD_PRODUC = DE.COD_PRODUC AND ASI.COD_DEUDOR = DE.COD_DEUDOR 
JOIN BD_COBROS..UBICADEU UD ON UD.COD_PRODUC = DE.COD_PRODUC AND UD.COD_DEUDOR = DE.COD_DEUDOR
JOIN BD_COBROS..UBICACIO UB ON UB.COD_UBICA = UD.COD_UBICA
JOIN BD_COBROS..CATEGORI CA ON CA.COD_CATEGO = DE.COD_CATEGO 
WHERE CONVERT(VARCHAR(10), FEC_SISTEM, 103)=CONVERT(VARCHAR(10), @FECHA, 103) AND 

(	(COD_GESTIO IN ('CP') AND A.val_saldo>=(ASI.PAGO_MINIMO-20)) 
	OR (A.COD_GESTIO='CI' AND UB.NOM_UBICA = 'NEGOCIACIONES' AND CA.NOM_CATEGO = 'POR ABONO Y FIRMA DE DOCUMENTOS')
	)for xml raw('tr'), elements
				) as nvarchar (max)
				) + N'</table>	
				<br>
				<br>
				<p>Saludos cordiales,</p>	
			<img src="F:\MAPI\CORREO\Sis-Matias Pinto1.png">'+
				N'<body>'+
				N'<html>';

EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'Procesos_EJR',
    @copy_recipients = 'mpinto@romerodyasociados.com',
    @subject = @asunto,
    @body = @tablaHTML,
    @body_format = 'HTML';

 DROP TABLE #ASI_ACT