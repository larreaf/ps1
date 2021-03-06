class InsertSQLBuilder {
    
    [System.Text.StringBuilder] $stringBuilderValues
    [System.Text.StringBuilder] $stringBuilderColumnNames
    [String] $valueSeparator
    [String] $columnSeparator
    [String] $serverAddress
    [String] $database
    [String] $schema
    [String] $table

    InsertSQLBuilder() {
        #Builder itself
        $this.stringBuilderColumnNames = [System.Text.StringBuilder]::new()
        $this.stringBuilderValues = [System.Text.StringBuilder]::new()
        $this.valueSeparator = ''
        $this.columnSeparator = ''
        
        #SQL database
        $this.serverAddress = ''
        $this.database = ''
        $this.schema = ''
        $this.table = ''
    }

    
    [void] addColumn([String] $columnName) {
        $this.stringBuilderColumnNames.Append($this.columnSeparator)
        $columnName = Remove-WhiteSpace $columnName
        $this.stringBuilderColumnNames.Append($columnName)
        $this.columnSeparator = ','
    }

    #If the $value does not have the single quotes, will be added to the $value
    [void] addValue([String] $value) {
        $this.stringBuilderValues.Append($this.valueSeparator)
        if($value -notmatch "'\w'"){
            $this.stringBuilderValues.Append("'"+$value+"'")
        }else{
            $this.stringBuilderValues.Append($value)
        }
        $this.valueSeparator = ','
    }

    [String]ToString(){
        $columnsName = $this.stringBuilderColumnNames.ToString()
        $columnsValues = $this.stringBuilderValues.ToString()
        $fourPartName = $this.fourPartName()
        $insert = 'INSERT INTO ' + $fourPartName + ' (' + $columnsName + ') ' + ' VALUES ' + ' (' + $columnsValues + ')'
        return $insert
    }
    #Clear the columnNames and values
    [void]ClearAll(){
        $this.ClearColumns()
        $this.ClearValues()
    }
    [void]ClearColumns(){
        [void]$this.stringBuilderColumnNames.Clear()
        $this.columnSeparator = ''
    }
    [void]ClearValues(){
        [void]$this.stringBuilderValues.Clear()
        $this.valueSeparator = ''
    }

    hidden [String] fourPartName(){
        return ($this.serverAddress + '.' + $this.database + '.' + $this.schema + '.' + $this.table).Trim('.') -replace '\.[\.]+', '.'
    }
    
}   

function Remove-WhiteSpace{
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $string
    )
    return $string.Trim() -replace '\s', '_'
}

class TableSQLBuilder{
    [System.Collections.Generic.List[Object]] $columnsList
    [String] $serverAddress
    [String] $database
    [String] $schema
    [String] $table

    TableSQLBuilder(){
        $this.columnsList = [System.Collections.Generic.List[Object]]::new()
        #SQL database
        $this.serverAddress = ''
        $this.database = ''
        $this.schema = ''
        $this.table = ''
    }


    [Void]addColumn([String]$columnName, [String]$type) {
        $column = [PSCustomObject]@{
            columnName = Remove-WhiteSpace $columnName
            columnType = $type
        }
        [void]$this.columnsList.Add($column)
        #.Add($column)
    }
    [void]addColumn([String] $columnName) {
        $this.addColumn($columnName, 'VARCHAR(255)')
    }

    [Void]addColumns($columns){
        $columns | ForEach-Object {
            $this.addColumn($_)
        }
    }

    [String]ToString(){
        $stringBuilder = [System.Text.StringBuilder]::new()
        [void]$stringBuilder.Append('CREATE TABLE ').Append($this.fourPartName()).Append(' (')
        $separator = ''

        $this.columnsList | ForEach-Object{
            [void]$stringBuilder.Append($separator)
            [void]$stringBuilder.Append($_.columnName)
            [void]$stringBuilder.Append(' ')
            [void]$stringBuilder.Append($_.columnType)
            $separator = ','
        }

        [void]$stringBuilder.Append(') ')

        return $stringBuilder.ToString()
    }

    hidden [String] fourPartName() {
        return ($this.serverAddress + '.' + $this.database + '.' + $this.schema + '.' + $this.table).Trim('.') -replace '\.[\.]+', '.'
    }

}

function Build-Table{
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $tableName,
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $columnNames
    )

    $tableBuilder = [TableSQLBuilder]::new()
    $tableBuilder.table = $tableName
    $array = [System.Collections.Generic.List[String]]::new()
    $columnNames.psobject.properties | ForEach-Object {$array.Add($_.Name)}
    $tableBuilder.addColumns($array)

    return $tableBuilder.ToString()

}
function Build-Inserts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Source,

        [Parameter(Mandatory = $false)]
        [String]
        $OutputFile,

        [Parameter(Mandatory = $false)]
        [String]
        $Separator = ','
    )
    
    Begin {
        $StartDate = (GET-DATE)

        $ib = [InsertSQLBuilder]::new()

        #$ib.serverAddress = ''
        $ib.database = 'DataBase'
        #$ib.schema = 'Schema'
        $ib.table = '##tempTableRPT' 

        $path = $source
       
        $lineCounter = 0

        if (!(Test-Path $OutputFile )) {
            New-Item -path $OutputFile
        }

        $clearContent = $true
        if ($clearContent) {
            Clear-Content -Path $outputFile
        }

        $totalRows = 0
        Get-Content -Path $source -ReadCount 100 | ForEach-Object { $totalRows += $_.Count }
        [int]$interval = $totalRows * 0.01


        Write-Progress -Activity 'Generando archivo... ' -Status "0% Complete" -PercentComplete 0
        
    }

    Process{
        $csvData = Import-Csv -path $path -delimiter $separator
        
        #Build-Table $ib.fourPartName() $csvData[0] | Add-Content -Path $outputFile
        $outputFileStream = [System.IO.File]::Open($OutputFile, 'Open', 'Write')
        $writer = [System.IO.StreamWriter] $outputFileStream

        $writer.WriteLine((Build-Table $ib.fourPartName() $csvData[0]))
        $csvData | Foreach-Object { 
            # Recorre el csv línea por línea
            foreach ($property in $_.PSObject.Properties) {
                # Guarda las columnas una sola vez en $ib
                if($lineCounter -eq 0){
                    $ib.addColumn($property.Name)
                }                
                $ib.addValue($property.Value)
            } 
            $insert = $ib.ToString()            
            $writer.WriteLine($insert)
            
            #Cada un cierto porcentaje $interval de líneas escritas, se actualiza la barra de progreso y se hace un flush al archivo de salida 
            ++$lineCounter
            $progress = [math]::Round(($lineCounter * 100) / $totalRows, 2)
            if ($lineCounter % $interval -eq 0) {
                $writer.Flush()
                $EndDate = (GET-DATE)
                $timeSpan = NEW-TIMESPAN -Start $StartDate -End $EndDate
                Write-Progress -Activity 'Generando archivo... ' -Status "$progress% Completado: $timeSpan" -PercentComplete $progress
                #[System.GC]::Collect()
            }

            # Limpia los valores
            $ib.ClearValues()
        }
        $EndDate = (GET-DATE)
        $timeSpan = NEW-TIMESPAN -Start $StartDate -End $EndDate
        Write-Verbose "Elapsed time: $timeSpan"
        $writer.WriteLine("/**** Elapsed time: $timeSpan ****/")
        $writer.Flush()
    }
    
    End{
        $ib.ClearAll()
        $writer.Close()
        $writer.Dispose()
        $outputFileStream.Close()
        $outputFileStream.Dispose()
        Write-Verbose "Lineas exportadas: $lineCounter" 
    }
}

#archivo .csv de entrada
$source = ''
#archivo .sql de salida
$outputFile = '' 

Build-Inserts -Source $source -OutputFile $outputFile -Separator ';' -Verbose