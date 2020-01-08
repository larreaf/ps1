#Create and save credential to cred.xml

$credential = Get-Credential

$credential | Export-CliXml -Path 'D:\Users\FLarrea\Documents\ExportOracleMetadata\SH\cred.xml'

$credential = Import-CliXml -Path 'D:\Users\FLarrea\Documents\ExportOracleMetadata\SH\cred.xml'
$userName = $Credential.UserName
$password = $Credential.GetNetworkCredential().Password

write-host "$userName, $password"