
#region bad
$array = @()
foreach ($item in 1..100000) {
    $array += $item
}
#endRegion bad

#region good
$array = foreach ($item in 1..100000) {
    $item
}


$array = [System.Collections.Generic.List[int32]]::new()
foreach ($item in 1..100000) {
    $array.Add($item)
}
#endRegion good

function Prompt {
    $executionTime = ((Get-History)[-1].EndExecutionTime - (Get-History)[-1].StartExecutionTime).Totalmilliseconds
    $time = [math]::Round($executionTime,3)
    Write-Host "$time ms | " -ForegroundColor Cyan  -NoNewline;
    Write-Host "$(Get-Location)" -ForegroundColor Yellow -NoNewline;
    Write-Host " >" -ForegroundColor Gray -NoNewline  ;
    return " "
}                                


