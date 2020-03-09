function Parse-Query {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Query,
        [Parameter(Mandatory = $true)]
        [String]
        $Header
    )
    
    $array = [System.Collections.ArrayList]::new()
    $i = 0
    $max = $Query.Length
    $BracketCounter = 0
    $ColumnBuilder = [System.Text.StringBuilder]::new()
    $Query = $Query -replace "`r`n",""

    #Este while parsea el query
    while ($i -lt $max ) {
        
        switch ($Query[$i]) {            
            '('{
                ++$BracketCounter
                [Void]$ColumnBuilder.Append($_)
            }
            ')'{
                --$BracketCounter
                [Void]$ColumnBuilder.Append($_)
            }
            #Si es una coma o el fin de string
            {($_ -eq ',' ) -or ($i -eq ($max-1))} {
                #Si todos los paréntesis abiertos están cerrados
                if ($BracketCounter -eq 0) {
                    #Fin de columna
                    [Void]$array.Add($ColumnBuilder.ToString())
                    [Void]$ColumnBuilder.Clear()
                    $BracketCounter = 0
                } else {
                    [Void]$ColumnBuilder.Append($_)
                }     
                Break; 
             }
            Default {
                [Void]$ColumnBuilder.Append($Query[$i])
                Break;
            }
        }        

        ++$i
    }
    
    if($ColumnBuilder.Length -gt 0){
        if ($BracketCounter -gt 0) {
            $ErrorMsg = "Hay $BracketCounter parentesis sin cerrar en el Query."
        } else {
            $BracketCounter *= -1 
            $ErrorMsg = "Hay $BracketCounter parentesis de cierre demas."
        }
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                ([System.Management.Automation.RuntimeException]$ErrorMsg),
                -2,
                [System.Management.Automation.ErrorCategory]::ParserError,
                $Null
            )
        )
    }

    $SelectBuilder = [System.Text.StringBuilder]::new()
    $i = 0
    $headerArray = $header.Split(',')
    $HeaderLength = $headerArray.Length
    $ColumnsCount = $array.Count
    
    if ($HeaderLength -ne $ColumnsCount) {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                ([System.Management.Automation.RuntimeException]"La cantidad de columnas del HEADER($HeaderLength) y del SELECT($ColumnsCount) no coinciden."),
                -1,
                [System.Management.Automation.ErrorCategory]::ParserError,
                $Null
            )
        )
    }

    $array | ForEach-Object{
        $index = $array.IndexOf($_)
        [Void]$SelectBuilder.Append($_ + ' as ' + "'" + $headerArray[$index].Trim() + "'")
        if($index -ne $array.Count -1){
            [Void]$SelectBuilder.AppendLine(',')
        }

    }
    $SelectBuilder.ToString()
}

$query = "SELECT CN.CUIT_CUIL,
	 CN.NROCLI,
	 CN.NOMBRE1,
	 CHAR(34)+''+CONVERT(VARCHAR,@V_FECHA_DESDE,103)+''+CHAR(34),
	 CHAR(34)+''+CONVERT(VARCHAR,@V_FECHA_HASTA,103)+''+CHAR(34),
	 ''+@V_NOMBRE_AGENCIA+'',
	 CHAR(34)+CONVERT(VARCHAR,ASIG.TS_BEGIN,103)+CHAR(34),
	 CHAR(34)+ISNULL(CONVERT(VARCHAR,APROD.TS_BEGIN,103),'')+CHAR(34),
	 ISNULL(E.DESCRIPCION,''),
	 CHAR(34)+ISNULL(CONVERT(VARCHAR,HIS.ID_FECHA_ATT,103),'')+CHAR(34),
	 ISNULL(ISNULL(U.USER_NAME,HIS.AGENTE),''),
	 CN.SUCURSAL,
	 CP.SUC,
	 ISNULL(C.NRO_CENTRO,''),
	 CP.TIPOTJ,
	 CP.DESCR_TIPO,
	 CP.NROOPE,
	 CN.CARTERA,
	 (REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(35), CONVERT(MONEY, P.DEUDA_TOTAL_CLI), 1), ',', '%'), '.', ','), '%', '.')),
	 (REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(35), CONVERT(MONEY, P.DEUDA_VENCIDA_CLI), 1), ',', '%'), '.', ','), '%', '.')),
	 (REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(35), CONVERT(MONEY, P.DEUDA_TOTAL_PROD), 1), ',', '%'), '.', ','), '%', '.')),
	 (REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(35), CONVERT(MONEY, P.DEUDA_VENCIDA_PROD), 1), ',', '%'), '.', ','), '%', '.')),
	 (REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(35), CONVERT(MONEY, P.MME_PROD), 1), ',', '%'), '.', ','), '%', '.')),
	 (REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(35), CONVERT(MONEY, P.MTOPAGO), 1), ',', '%'), '.', ','), '%', '.')),
	 CHAR(34)+CONVERT(VARCHAR,P.FECPAGO,103)+CHAR(34),
	 ISNULL(CDO.CAT_DATA_DESC,''),
	 P.CODIGO,
	 P.SUBCODIGO,
	 P.TIPO_MOV,
	 ISNULL(CDF.CAT_DATA_DESC,''),
	 CASE	WHEN P.DEUDA_VENCIDA_CLI = 0 THEN '0'
				ELSE REPLACE(CONVERT(VARCHAR,CONVERT(NUMERIC(30,2),ROUND(P.MTOPAGO/P.DEUDA_VENCIDA_CLI,2)*100)),'.',',') END + '%',
	 CASE	WHEN P.DEUDA_VENCIDA_CLI = 0 THEN ''
				WHEN CONVERT(NUMERIC(30,2),ROUND(P.MTOPAGO/P.DEUDA_VENCIDA_CLI,2)*100) <= '+@V_PGO_PARCIAL+' THEN 'PARCIAL'
	 		WHEN CONVERT(NUMERIC(30,2),ROUND(P.MTOPAGO/P.DEUDA_VENCIDA_CLI,2)*100) > '+@V_PGO_TOTAL+' THEN 'TOTAL'
	 		ELSE '' END,
	 CASE	WHEN P.DEUDA_VENCIDA_CLI = 0 THEN ''
				WHEN CONVERT(NUMERIC(30,2),ROUND(P.MTOPAGO/P.DEUDA_VENCIDA_CLI,2)*100) <= '+@V_PGO_PARCIAL+' THEN (REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(35), CONVERT(MONEY, (P.MTOPAGO * '+@V_COMI_PARCIAL+'/100)), 1), ',', '%'), '.', ','), '%', '.'))
	 		WHEN CONVERT(NUMERIC(30,2),ROUND(P.MTOPAGO/P.DEUDA_VENCIDA_CLI,2)*100) > '+@V_PGO_TOTAL+' THEN (REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(35), CONVERT(MONEY, (P.MTOPAGO * '+@V_COMI_TOTAL+'/100)), 1), ',', '%'), '.', ','), '%', '.'))
	 		ELSE '' END,
	 CASE	WHEN P.DEUDA_VENCIDA_CLI = 0 THEN ''
				WHEN CONVERT(NUMERIC(30,2),ROUND(P.MTOPAGO/P.DEUDA_VENCIDA_CLI,2)*100) <= '+@V_PGO_PARCIAL+' THEN (REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(35), CONVERT(MONEY, (P.MTOPAGO * ('+@V_COMI_PARCIAL+'/100) * 0.21)), 1), ',', '%'), '.', ','), '%', '.'))
	 		WHEN CONVERT(NUMERIC(30,2),ROUND(P.MTOPAGO/P.DEUDA_VENCIDA_CLI,2)*100) > '+@V_PGO_TOTAL+' THEN (REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(35), CONVERT(MONEY, (P.MTOPAGO * ('+@V_COMI_TOTAL+'/100) * 0.21)), 1), ',', '%'), '.', ','), '%', '.'))
	 		ELSE '' END,
	 CASE	WHEN P.DEUDA_VENCIDA_CLI = 0 THEN ''
				WHEN CONVERT(NUMERIC(30,2),ROUND(P.MTOPAGO/P.DEUDA_VENCIDA_CLI,2)*100) <= '+@V_PGO_PARCIAL+' THEN (REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(35), CONVERT(MONEY, (P.MTOPAGO * ('+@V_COMI_PARCIAL+'/100) * 1.21)), 1), ',', '%'), '.', ','), '%', '.'))
	 		WHEN CONVERT(NUMERIC(30,2),ROUND(P.MTOPAGO/P.DEUDA_VENCIDA_CLI,2)*100) > '+@V_PGO_TOTAL+' THEN (REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(35), CONVERT(MONEY, (P.MTOPAGO * ('+@V_COMI_TOTAL+'/100) * 1.21)), 1), ',', '%'), '.', ','), '%', '.'))
	 		ELSE '' END,
	 CASE	WHEN HIS.EFECTO IS NULL THEN 'NULL'
				WHEN HIS.EFECTO IS NOT NULL AND COM.ESTADO_COMISION IS NULL THEN 'NULL'
				WHEN COM.ESTADO_COMISION IS NOT NULL THEN COM.ESTADO_COMISION
				ELSE 'NULL' END"

$Header = 'CUIT, NROCLIENTE,Nombre y Apellido, Fecha Pago Desde, Fecha Pago Hasta, Agencia , Fecha Asignacion Cliente, Fecha Asignacion Producto, Efecto, Fecha Efecto, Usuario, Sucursal Cliente, Sucursal Producto, Centro de Costos, Nro Linea, Descripcion Producto, Operacion, Cartera, Deuda Total Cliente, Deuda Vencida Total Cliente, Deuda Total Producto, Deuda Vencida Producto, MME producto, Importe Pago Acreditado, Fecha de Pago, Origen, Codigo, Subcodigo, Tipo mov., Forma de pago, Porc cobertura, Tipo de Cancelacion, Importe Comision, IVA, Comision Total a Pagar, Estado Comisiones'

Parse-Query `
    -Query  $query `
    -Header  $Header

