[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $filePath #= '.\queryFinal.sql_1.sql'
)


#$ServerName = 'nbsf000sqlt7'
$ServerName = '172.16.1.92'
$DatabaseName = 'ENGAGENBSF'

#$secpasswd = ConvertTo-SecureString "engagenbsf_2015_prod" -AsPlainText -Force
$secpasswd = ConvertTo-SecureString "@SAENG@2008" -AsPlainText -Force
#$Credential = New-Object System.Management.Automation.PSCredential ("engagenbsf_prod", $secpasswd)
$Credential = New-Object System.Management.Automation.PSCredential ("ENGAGENBSF", $secpasswd)
$userName = $Credential.UserName
$password = $Credential.GetNetworkCredential().Password

#$outputPath = 'D:\Users\FLarrea\Documents\PowerShell\result.csv'

Write-Verbose 'Starting... '
Get-Date -Format "MM/dd/yyyy HH:mm:ss" | Write-Verbose
Write-Verbose "Start reading file: $filePath"

$file = Get-Content -path $filePath

Write-Verbose 'File read'

 #region connect to sql server
 Write-Verbose 'Start connection...'
 $connectionString = 'Data Source={0};database={1};User ID={2};Password={3}' -f $ServerName,$DatabaseName,$userName,$password
 $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
 $sqlConnection.Open()
 #endregion


 #Usar stringBuilder es más performante que concatenar un solo string o usar un array[string] para luego reducirlo a un string
 $stringBuilder = [System.Text.StringBuilder]::new()



try{
    
    Write-Verbose 'Start the loop of each line'
    $counter = 0

    foreach ($line in $file) {
        $counter+= 1
        if($counter % 400 -ne 0 ){
            [void]$stringBuilder.AppendLine($line)
        }else{ 
              
            $lastLine = $line.TrimEnd("UNION ALL")
            [void]$stringBuilder.AppendLine($lastLine)
            $query = $stringBuilder.ToString()
            #Write-Verbose $query
            $command = New-Object System.Data.SqlClient.SqlCommand #$sqlConnection.CreateCommand()
            $command.CommandText = $query
            $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
            $SqlAdapter.SelectCommand = $command
            $command.Connection = $sqlConnection
            $DataSet = New-Object System.Data.DataSet
            [void]$SqlAdapter.Fill($DataSet)
            #Write-Verbose 'Creo el comando'
            #$queryResult = $command.ExecuteReader()
            #run the query (400 lines) and output to a file
            #[void] $DataSet  | Export-csv  –append  -path .\result.csv
            $DataSet.Tables |  Write-host 
        
            
            $query = ''
            $stringBuilder = [System.Text.StringBuilder]::new()
            $queryResult.close()
            
        }              
    }
}
catch{
    $ErrorMessage = $_.Exception.Message
    #$FailedItem = $_.Exception.ItemName
    Write-Error "$ErrorMessage"
}
finally{
    $sqlConnection.Close()
}
