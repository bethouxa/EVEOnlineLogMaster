$EveLogDirectory = Join-Path -Path $HOME -ChildPath "\Documents\EVE\logs\Gamelogs"


#region Discover existing logs

#Get log files, sort by date, filter out "no character" files
$LogFiles = Get-ChildItem $EveLogDirectory | ?{get-content $_.FullName | Select-String -Pattern "^\s*Listener:"} | sort LastWriteTime

#group all files by character
$characters = @()
$LogsByCharacter = @{}
foreach($log in $LogFiles) {
    $listener = (Select-String -Path $log -Pattern "^\s*Listener:\s*(.*)\s*$").Matches.Groups[1].Value
    if (-not $LogsByCharacter[$listener]) { $LogsByCharacter.Add($listener, @()) } # We want an array else $LogsByCharacter[$listener] will be made a string on next line
    $LogsByCharacter[$listener] += $log
    $characters += $listener
}


#Get latest log for each char
$CurrentLogByCharacter = @{}
foreach($character in $LogsByCharacter.Keys) {
    $CurrentLogByCharacter.Add($character, ($LogsByCharacter[$character] | sort | select -Last 1)) # filename timestamped in sortable format, thx ccp
}

#endregion

#region register watcher for new logs (for newly connected chars or client restarts)

$Watcher = New-Object IO.FileSystemWatcher $EveLogDirectory, "*.txt" -Property @{ 
    IncludeSubdirectories = $false
    NotifyFilter = [IO.NotifyFilters]'FileName'
}

$onCreated = Register-ObjectEvent $Watcher -EventName Created -SourceIdentifier FileCreated -Action {
    $listener = (Select-String -Path $Event.SourceEventArgs.FullPath -Pattern "^\s*Listener:\s*(.*)\s*$").Matches.Groups[1].Value
    $CurrentLogByCharacter[$listener] = $Event.SourceEventArgs.FullPath
}

#endregion

#region actually do the thing
$watchers = @()
foreach ($character in $characters) {
    $watchers += Start-Job -Name $character -ArgumentList $CurrentLogByCharacter[$character] -ScriptBlock {get-content -wait $args}
    # At this point we have one job per character that outputs new lines
}

#Purge jobs of previous lines (or else we'll get the whole current gamelog)
$trash = Get-Job | Receive-Job

while($true) {
    Start-Sleep -Seconds 1
    foreach($character in $characters) {
        foreach($line in Receive-Job -Name $character) {
            $Body = @{
                Character = $character
                LogLine = $line
            }
        }
    }
}