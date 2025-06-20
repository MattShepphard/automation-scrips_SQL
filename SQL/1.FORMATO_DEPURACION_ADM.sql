USE BD_COBROS
	
	SELECT * INTO #DEPURA
	 FROM OPENROWSET(
	'Microsoft.ACE.OLEDB.12.0',
	'Excel 12.0;Database=C:\SALDOS\BDP_DATOS\BDP_ASIGNACION_ADM.xlsX;HDR=YES',
	'SELECT * FROM [Hoja1$]')

SELECT * FROM #DEPURA 

SELECT CASE WHEN MARCA = 'MC' THEN 'MCE'
            WHEN MARCA = 'VS' THEN '012'
			ELSE 'REVISAR' END [Codigo empresa para cobro], 
			'G10' [Codigo de abogado], 'LEGAL' [Tipo de Cartera], 
			CIFCOD [Numero de tarjeta], [Nombre Completo] Nombre, [Titular Cedula] Cedula, 
			CAST(GETDATE() AS DATE) [Fecha asignacion abogado], 'POR DOCUMENTOS' MOTIVO, 'N' [Indicador de juicio], '.00'
			[Valor al inicio mes S/.], '.00' [Valor pagado al mes S/.], '//'[Fecha de ultimo pago S/.], [CAPITAL TOTAL] [Valor al inicio mes $], 
			'.00'[Valor pagado al mes $], '//' [Fecha de ultimo pago $], '.00' [Saldo Honor. Legal],
			'.00'[Total Honor. Legal Pagado], '.00' [Saldo Int. Mora Legal], '.00'[Total Int.Mora Legal Pagado], 
			[Nombre Ciudad Domicilio] [Ciudad domicilio],
			NULL [Direccion Domicilio], 
			CASE WHEN [Telefono Domic#2] IS NULL THEN '0' ELSE [Telefono Domic#2] END [Telfono 1 Domicilio], 
			CASE WHEN [Telefono Domic#3] IS NULL THEN '0' ELSE [Telefono Domic#3] END [Telfono 2 Domicilio],
		    [Nombre Ciudad Domicilio]  [Ciudad Comercial], 
			NULL [Direccion comercial], 
			CASE WHEN [Telefono Empresa 1] IS NULL THEN '0' ELSE [Telefono Empresa 1] END [Telefono 1 Comercial], 
			CASE WHEN [Telefono Empresa 2] IS NULL THEN '0' ELSE [Telefono Empresa 2] END[Telefono 2 Comercial], '021' [Razon Sts], 'DPTO. LEGAL' [Desc.Razon], CIFCOD Cifcod, 
			[Dirección E-mail] [Direccion e-mail], [Dias de Morocidad][Dias Vencidos]


FROM #DEPURA 