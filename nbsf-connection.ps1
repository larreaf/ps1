[cmdletbinding()]
param()

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.Data") | Out-Null

$secpasswd = ConvertTo-SecureString "@SAENG@2008" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ("ENGAGENBSF", $secpasswd)
$ServerName = '172.16.1.92'
$DatabaseName = 'ENGAGENBSF'

Write-Verbose 'Parametros de conexion creados'

$ErrorActionPreference = 'Stop'

$RUTA = 'D:\Users\FLarrea\Documents\PowerShell'
$ESQUEMA_OBJ = 'ENGAGENBSF'
#$TNS=$args[0]
$TIPO_OBJ='PROCEDURE'
$NOMBRE_OBJ='PA_TR15_LISTADO_INTEGRACION'

$Salida="$RUTA\\OUTPUT\\"
#\\$ESQUEMA_OBJ.$NOMBRE_OBJ.sql"
#$fin="$RUTA\\OUTPUT\\$TIPO_OBJ $ESQUEMA_OBJ.$NOMBRE_OBJ.sql"

$options = New-Object "Microsoft.SqlServer.Management.SMO.ScriptingOptions"
$options.AllowSystemObjects = $false
$options.IncludeDatabaseContext = $true
$options.IncludeIfNotExists = $true
$options.ClusteredIndexes = $true
#$options.ScriptForCreateDrop = $true
$options.Default = $false
$options.DriAll = $true
$options.Indexes = $true
$options.NonClusteredIndexes = $true
$options.IncludeHeaders = $true
$options.ToFileOnly = $true
$options.AppendToFile = $true
$options.ScriptDrops = $false
$options.WithDependencies = $false

$scripter = New-Object "Microsoft.SqlServer.Management.Smo.Scripter"

$userName = $Credential.UserName
$password = $Credential.GetNetworkCredential().Password

#Begin connection
try {

    #region creates sqlClient connection
    $connectionString = 'Data Source={0};database={1};User ID={2};Password={3}' -f $ServerName,$DatabaseName,$userName,$password
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
    $sqlConnection.Open()
    #endregion 

    ## This will run if the Open() method does not throw an exception

    #region creates sqlServerConnection
    $sqlServerConnection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection $sqlConnection
    $sqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server $sqlServerConnection
    Write-Verbose 'Conectado a Santa Fe'
    $scripter.Server = $sqlServer
    $scripter.Options = $options
    #$db = New-Object Microsoft.SqlServer.Management.SMO.Database
    $db = $sqlServer.Databases[$DatabaseName]
    #endregion

    Write-Verbose $db.Schemas[$ESQUEMA_OBJ].Name
    Write-Verbose 'Guardo la db en $db'

    $StoredProcedures = $db.StoredProcedures 
    #$StoredProcedures = $StoredProcedures | Where-Object {$_.Name -eq $NOMBRE_OBJ}
    #$StoredProcedures = $StoredProcedures.StoreProcedureCollection
    Write-Verbose 'Filtro los procedimientos'
    $options.FileName = $Salida + "\$($DatabaseName)_stored_procs.sql"
    New-Item $options.FileName -type file -force | Out-Null
    $sp = $StoredProcedures | Where-Object {$_.Name -eq $NOMBRE_OBJ} | Select-Object -first 1
    $options.ScriptDrops = $false
    $options.IncludeIfNotExists = $true
            
    $scripter.Script($sp)
    <#
    ForEach ($StoredProcedure in $StoredProcedures | Where-Object {$_.Name -eq $NOMBRE_OBJ}){
        if ($StoredProcedure.Name -eq $NOMBRE_OBJ){
            #$options.ScriptDrops = $true
            #$scripter.Script($StoredProcedure)
            $options.ScriptDrops = $false
            $options.IncludeIfNotExists = $false
            
            $scripter.Script($StoredProcedure)
        }
        
    } 
    #>
    #$scripter.Script($StoredProcedure)

} catch {
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    Write-Error "`n$FailedItem`n$ErrorMessage"
    "Fallo la conexion"
    
} finally {
    ## Close the connection when we're done
    $sqlConnection.Close()
}

<#

$credential = Get-Credential
$credential2 = Get-Credential

$credential,$credential2 | Export-CliXml -Path 'D:\Users\FLarrea\Documents\ExportOracleMetadata\SH\cred.xml'

$credAux = Import-Clixml -Path 'D:\Users\FLarrea\Documents\ExportOracleMetadata\SH\cred.xml'
$credential = Get-Credential | Where-Object

$credAux, $credential | Export-CliXml -Path 'D:\Users\FLarrea\Documents\ExportOracleMetadata\SH\cred.xml'

$credential = Import-CliXml -Path 'D:\Users\FLarrea\Documents\ExportOracleMetadata\SH\cred.xml' | Where-Object {$_.UserName -eq 'carl'}
$userName = $Credential.UserName
$password = $Credential.GetNetworkCredential().Password

write-host "$userName, $password"

#>