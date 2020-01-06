$ipaddr = (Invoke-WebRequest ipecho.net/plain) -split "\n" | select -last 1
write-host "internet ip is $ipaddr"

$ipaddr = Get-NetIPAddress | ?{$_.IPAddress -like "10.*" -or $_.IPAddress -like "192.168.*"} | select -ExpandProperty IPAddress
write-host "local ip is $ipaddr"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://*:53000/")
$listener.Start()

while($true) {
    $context = $listener.GetContext()
    Start-Job -ScriptBlock {Handle($args)} -ArgumentList $res
}

function Handle($HTTPContext)
{

}