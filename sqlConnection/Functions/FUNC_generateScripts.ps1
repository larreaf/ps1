Function FUNC_generateScripts{
    <#
    .PARAMETER parametro1
    
    .EXAMPLE
        Colocar ejemplos
    .NOTES
        Author:  Federico Larrea
        Email :  @gmail.com
        Date  :  09-Jan-2020
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [TypeName]
        $ParameterName  
    )
    begin {
        #Create connection to sql server
        $connectionString = 'Data Source={0};database={1};User ID={2};Password={3}' -f $ServerName,$DatabaseName,$userName,$password
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
        $sqlConnection.Open()
    }
    process{
        #generate scripts
    }
    end{
        #close the connection
        $sqlConnection.Close()
    }
}
