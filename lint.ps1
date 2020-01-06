$settings = @{
    Rules = @{
        PSUseCompatibleSyntax = @{
            # This turns the rule on (setting it to false will turn it off)
            Enable = $true
 
            # List the targeted versions of PowerShell here
            TargetVersions = @(
                '3.0',
                '5.1',
                '6.2'
            )
        }; PSUseCompatibleCommands = @{
            # Turns the rule on
            Enable = $true
 
            # Lists the PowerShell platforms we want to check compatibility with
            TargetProfiles = @(
                'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework',
                'win-48_x64_10.0.17763.0_6.1.3_x64_4.0.30319.42000_core'
            )
        }
    }
}

Invoke-ScriptAnalyzer -Path .\client.ps1 -Settings $settings | sort Severity
Invoke-ScriptAnalyzer -Path .\server.ps1 -Settings $settings | sort Severity