[CmdletBinding()]
param (

    [Parameter(Mandatory = $false, ParameterSetName = 'InstallDependencies')]
    [String]$DependencyFile = (Join-Path -Path $PSScriptRoot -ChildPath 'install.depend.psd1')

)

# Bootstrap build process
if (-not (Get-PackageProvider -Name 'NuGet')) {
    Write-Debug 'Bootstrapping NuGet'
    Get-PackageProvider -Name 'NuGet' -ForceBootstrap
}
if (-not (Get-Module PSDepend -ListAvailable)) {
    Write-Verbose 'Installing dependencies'
    Write-Debug 'Installing PSDepend'
    Install-Module PSDepend -Scope CurrentUser -Verbose:$VerbosePreference -Debug:$DebugPreference
}
# Test Dependency file exists
# Does DependencyFile exist? (yes I know I can do this in the param block I prefer it this way)
Write-Verbose 'Checking DependencyFile exists'
try {
    Write-Debug "Checking $VersionFile"
    $null = Test-Path -Path $DependencyFile -PathType Leaf
    $installDependencyConfigPath = Join-Path -Path $PSScriptRoot -ChildPath 'install.depend.psd1'
    $invokePSDependParams = @{
        Path    = $installDependencyConfigPath
        Import  = $true
        Confirm = $false
        Install = $true
        Verbose = $VerbosePreference
        Debug   = $DebugPreference
    }
    Invoke-PSDepend @invokePSDependParams
}
catch {
    Write-Debug "Error checking $DependencyFile"
    Write-Error -Message 'Error finding dependency file'
    break
}
