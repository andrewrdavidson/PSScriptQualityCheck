function Invoke-PSScriptQualityCheck {
    <#
        .SYNOPSIS
        Invoke the Script powershell tests

        .DESCRIPTION
        Invoke a series of Pester tests to validate the quality of the script file

        .PARAMETER File
        The script file to be tested

        .PARAMETER CheckTestsFile
        [OPTIONAL] Path to an alternate Script Check File

        .PARAMETER ScriptAnalyzerRulesPath
        [OPTIONAL] Path to an extra Script Analyzer rules set

        .PARAMETER HelpRulesFile
        [OPTIONAL] Path to an alternate Help Rules File

        .EXAMPLE
        $testResults = Invoke-PSScriptQualityCheck -File File.ps1

        .EXAMPLE
        $testResults = Invoke-PSScriptQualityCheck -File File.ps1 -CheckTestsFile C:\AlternateTests.ps1

        .EXAMPLE
        $testResults = Invoke-PSScriptQualityCheck -File File.ps1 -HelpRulesFile C:\AlternateHelpRules.psd1
    #>
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateScript({
                if ( -Not ($_ | Test-Path) ) {
                    throw 'File does not exist'
                }
                return $true
            })]
        [System.String]$File,
        [parameter(Mandatory = $false)]
        [System.String]$CheckTestsFile,
        [parameter(Mandatory = $false)]
        [System.String[]]$ScriptAnalyzerRulesPath,
        [parameter(Mandatory = $false)]
        [System.String]$HelpRulesFile
    )

    # Default Pester Parameters
    $scriptTestPesterConfiguration = [PesterConfiguration]::Default
    $scriptTestPesterConfiguration.Run.Exit = $false
    $scriptTestPesterConfiguration.CodeCoverage.Enabled = $false
    $scriptTestPesterConfiguration.Output.Verbosity = 'Detailed'
    $scriptTestPesterConfiguration.Run.PassThru = $true
    $scriptTestPesterConfiguration.Should.ErrorAction = 'Stop'

    $fileProperties = (Get-Item -Path $File)
    $modulePath = (Get-Module -Name 'PSScriptQualityCheck').ModuleBase

    # what happens if multiple versions of the module are installed?
    # you get two module paths and everything dies

    if (-not ($PSBoundParameters.ContainsKey('CheckTestsFile'))) {
        $checkTestsFile = (Join-Path -Path $modulePath -ChildPath 'Data\Script.Checks.ps1')
    }

    if (-not ($PSBoundParameters.ContainsKey('HelpRulesFile'))) {
        $HelpRulesFile = (Join-Path -Path $modulePath -ChildPath 'Data\HelpRules.psd1')
    }

    # if ( $ScriptAnalyzerRulesPath -isnot [Array]) {
    #     $ScriptAnalyzerRulesPath = @($ScriptAnalyzerRulesPath)
    # }

    # $rulesPath = @()

    # $ScriptAnalyzerRulesPath | ForEach-Object {

    #     $rulesPath += @{
    #         'Path' = $_
    #     }

    # }

    Write-Verbose "FILE = $File"
    Write-Verbose "CTF = $checkTestsFile"
    Write-Verbose "HRF = $helpRulesFile"
    Write-Verbose "SRP = $scriptAnalyzerRulesPath"

    $container3 = New-PesterContainer -Path $CheckTestsFile -Data @{ File = $fileProperties; ScriptAnalyzerRulesPath = $ScriptAnalyzerRulesPath; HelpRulesFile = $HelpRulesFile }
    $scriptTestPesterConfiguration.Run.Container = $container3
    Invoke-Pester -Configuration $scriptTestPesterConfiguration

}
