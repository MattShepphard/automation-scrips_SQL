DECLARE @CONFIRM INT = 1
IF @CONFIRM <> 1
      SELECT 'NO ENVIAR'			
ELSE 
    DECLARE @FECHA DATE = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE);
DECLARE @ASUNTO VARCHAR(200) = CONCAT('ACTUALIZACION DE MARCAS - BCO. PACIFICO ADMINISTRATIVA AL ', CONVERT(VARCHAR(10), @FECHA, 103));
DECLARE @tablaHTML NVARCHAR(MAX);

set	 @tablaHTML  =
				N'<html>
<head>
<style>
    body { font-family: Arial, sans-serif; font-size: 12px; }
	 p { font-size: 14px; }
</style>
</head>
<body>
<p>Buenos días/tardes.<br><br>
Estimados,<br>
Las marcas de la cartera administrativa fueron actualizadas al 
 <b>' + CONVERT(VARCHAR(10), @FECHA, 103) + '</b>:</p>
				<p>Quedo atento a cualquier novedad. <br>
Saludos cordiales, 
</p>	
			<img src="F:\MAPI\CORREO\Sis-Matias Pinto1.png">'+
				N'<body>'+
				N'<html>';

EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'Procesos_EJR',
    @copy_recipients = 'mpinto@romerodyasociados.com',
    @subject = @asunto,
    @body = @tablaHTML,
    @body_format = 'HTML';