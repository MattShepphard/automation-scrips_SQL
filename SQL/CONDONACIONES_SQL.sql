/*
-INSTRUCCIONES:
LA CONSULTA PROPORCIONA INFORMACI�N A VERIFICAR EN LA CARTA DE CONDONACI�N.
- FECHA DE LA CARTA DEBE SER IGUAL A LA �LTIMA FECHA DE PAGO
- EL PRODUCTO (VISA/MASTERCARD) DEBE DETALLARSE EN LA CARTA
- VALIDAR QUE NOMBRES Y C�DULA DEL CLIENTE SEA CORRECTOS
- VALOR DE LA PROPUESTA DEBE SER IGUAL A LA SUMA TOTAL DE PAGOS DEL CLIENTE EN EL MES
- VALIDAR QUE CIFCOD Y ULTIMOS 5 N�MEROS DE TARJETA SEAN CORRECTOS
- SI EL VALOR A CONDONAR ES MAYOR A $2000.00 EL CLIENTE DEBE ADJUNTAR COMPROBANTES DE PAGO Y DETALLAR EL MOTIVO O JUSITIFICATIVOS DE NO PAGO CASO CONTRARIO NO APLICA
- UNIFICAR ARCHIVOS EN CASO DE EXISTIR NECESIDAD DE ADJUNTAR COMPROBANTES O JUSTIFICATIVOS
- SI EL CLIENTE ES FALLECIDO DEBE ADJUNTARSE EL CERTIFICADO DE DEFUNCION Y LA COPIA DE CEDULA DEL TITULAR JUNTO CON LA CARTA
- EN LA CARTA DEBE VALIDAR QUE LA FIRMA SEA CORRECTA Y NO ESTE ADULTERADA / SE PERMITE FIRMA ELECTR�NICA

*/
USE BD_COBROS
DECLARE @FECHA DATETIME SET @FECHA = GETDATE()-15	 --SI LA CARTA CORRESPONDE A UN MES ANTERIOR DEBE ESPECIFICAR LA FECHA
DECLARE @CLIENTE NVARCHAR(MAX) = 'I10330' -- INGRESAR CIFCOD
DECLARE @FECPM DATETIME SET @FECPM = (SELECT CONVERT(VARCHAR(25),DATEADD(DD,-(DAY(@FECHA)-1),@FECHA),105))
DECLARE @FECUL DATETIME SET @FECUL = (SELECT CONVERT(VARCHAR(25),DATEADD(DD,-(DAY(DATEADD(MM,1,@FECHA))),DATEADD(MM,1,@FECHA)),105))

SELECT D.NUM_PROOTR CIFCOD, CASE WHEN D.COD_PRODUC = 4 THEN 'VISA BCO. PACIFICO' ELSE 'MASTERCARD' END PRODUCTO,
        D.COD_DEUDOR,D.NUM_CEDRUC+ ' - ' + APE_DEUDOR + ' ' + NOM_DEUDOR CLIENTE, 
       SUBSTRING(D.NUM_PRODUC,12,6) NUM_TARJETA , CAST(MAX(PP.FEC_PAGO) AS DATE) ULT_FEC_PAGO ,
           (SELECT SUM(PP.VAL_DEPOSI) FROM BD_COBROS..PAGOS AS PP
             WHERE D.COD_PRODUC=PP.COD_PRODUC AND D.COD_DEUDOR=PP.COD_DEUDOR AND
			PP.EST_PAGO=3 AND PP.FEC_DEPOSI BETWEEN @FECPM AND @FECUL) AS PAGADO, 
			CASE WHEN D.VAL_SALDO >= 2000 THEN 'DEBE ADJUNTAR JUSTIFICATIVOS' ELSE 'NO APLICA' END JUSTIFICACION
FROM DEUDOR D 
LEFT JOIN PAGOS PP ON PP.COD_PRODUC = D.COD_PRODUC AND PP.COD_DEUDOR = D.COD_DEUDOR
WHERE D.NUM_PROOTR = @CLIENTE AND D.COD_PRODUC IN (4,19) AND D.SI_RETIRA = 0
GROUP BY  D.NUM_PROOTR, D.COD_DEUDOR ,D.NUM_CEDRUC ,D.COD_PRODUC, NOM_DEUDOR,APE_DEUDOR, D.NUM_PRODUC, VAL_SALDO