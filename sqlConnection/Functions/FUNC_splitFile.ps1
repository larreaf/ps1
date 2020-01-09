function FUNC_splitFile{
    <#
    .Synopsis
        Splits a file into smaller files.
    .DESCRIPTION
        Splits a file into smaller files of n lines each. The amount of lines per file must be specified.
    .PARAMETER Path
        It is the file that will be splitted.
    .PARAMETER LinesPerFile
        The amount of lines of the smaller files.
    .OUTPUTS
        [Int] The amount of created files
    .EXAMPLE
        Colocar ejemplos
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline = $true)]
        [String]
        $Path,
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^[+]?[1-9]')] #Numeros naturales
        [Int]
        $LinesPerFile
    )

    $FullPath = [System.IO.Path]::GetFullPath($Path)
    $rootName = [System.IO.Path]::GetFileNameWithoutExtension($FullPath) + "_"
    $ext = [System.IO.Path]::GetExtension($FullPath)

    $reader = new-object System.IO.StreamReader($Path)
    $linesWrote = 0
    $count = 1
    $fileName = "{0}{1}{2}" -f ($rootName, $count, $ext)
    while($null -ne ($line = $reader.ReadLine()) )
    {
        Add-Content -path $fileName -value $line
        
        ++$linesWrote
        if($linesWrote -ge $LinesPerFile)
        {
            ++$count
            $fileName = "{0}{1}.{2}" -f ($rootName, $count, $ext)
            $linesWrote = 0
        }
    }

    $reader.Close()
    if($linesWrote -eq 0){
        --$count
    }
    return $count
}