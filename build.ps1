[CmdletBinding()]
param (

    [Parameter(Mandatory = $false)]
    [String]$SourceFolder = $PSScriptRoot,

    [Parameter(Mandatory = $false)]
    [String]$scriptAnalyzerRulesPath

)

Write-Verbose 'Build script start'

Write-Verbose 'Setting Strict Mode'
Set-StrictMode -Version Latest

Write-Verbose 'Importing Modules'
Remove-Module -Name Pester -Force -Verbose:$false -ErrorAction 'SilentlyContinue'
Import-Module -Name Pester -Verbose:$false

Write-Verbose 'Generating outputFolder'
$outputFolder = Join-Path -Path $SourceFolder -ChildPath 'artifacts'
$null = New-Item -Path $outputFolder -ItemType 'Directory' -ErrorAction 'SilentlyContinue'
# $scriptAnalyzerRulesPath = @('C:\Users\Andrew\OneDrive\Documents\PowerShell\Modules\Indented.ScriptAnalyzerRules')
Write-Debug "OutputFolder = $outputFolder"

Write-Verbose 'Generating module variables'
$moduleName = (Get-Item -Path $PSScriptRoot).Name
$moduleManifest = ('{0}.psd1' -f $moduleName )
Write-Debug "ModuleName = $moduleName"
Write-Debug "ModuleManifest = $moduleManifest"

Write-Verbose 'Generating Pester configuration object'
$PesterConfiguration = [PesterConfiguration]::Default
$PesterConfiguration.Run.Exit = $false
$PesterConfiguration.CodeCoverage.Enabled = $false
$PesterConfiguration.Output.Verbosity = 'Detailed'
$PesterConfiguration.Run.PassThru = $true
$PesterConfiguration.Should.ErrorAction = 'Continue'

# Testing manifest exists and is valid
try {

    if (-not (Test-Path -Path $moduleManifest)) {
        Write-Error -Exception ([System.IO.FileNotFoundException]::new('No module manifest found')) -ErrorAction Stop
    }
    if ( -not (Test-ModuleManifest -Path $moduleManifest -ErrorAction SilentlyContinue)) {
        Write-Error -Exception ([System.IO.FileLoadException]::new('Invalid module manifest')) -ErrorAction Stop
    }

}
catch {

    Write-Error $_
    break

}

# Get all public scripts
$publicFunctions = Get-ChildItem -Path (Join-Path -Path $sourceFolder -ChildPath 'public') -Filter '*.ps1' -File

foreach ($public in $publicFunctions) {

    # Write-Host "Found $public script"
    $functionProperties = Get-ItemProperty -Path $public
    $parentFolder = Split-Path $functionProperties.DirectoryName -Parent

    # make sure that code passes it's test
    # find it's relevant test
    $testFileName = '{0}\tests\public\{1}.{2}' -f $parentFolder, $functionProperties.BaseName, 'tests.ps1'
    if (Test-Path -Path $testFileName) {
        Write-Host 'test found' -ForegroundColor Green
        $container = New-PesterContainer -Path $testFileName
        $PesterConfiguration.Run.Container = $container
        $publicResults = Invoke-Pester -Configuration $PesterConfiguration

    }
    else {
        # Write-Error 'Test not found' -ErrorAction Stop
    }

}

# get all private scripts
$privateFunctions = Get-ChildItem -Path (Join-Path -Path $sourceFolder -ChildPath 'private') -Filter '*.ps1' -File

foreach ($private in $privateFunctions) {

    # Write-Host "Found $public script"
    $functionProperties = Get-ItemProperty -Path $private
    $parentFolder = Split-Path $functionProperties.DirectoryName -Parent

    # make sure that code passes it's test
    # find it's relevant test
    $testFileName = '{0}\tests\private\{1}.{2}' -f $parentFolder, $functionProperties.BaseName, 'tests.ps1'
    if (Test-Path -Path $testFileName) {
        Write-Host 'test found' -ForegroundColor Green
        $container = New-PesterContainer -Path $testFileName
        $PesterConfiguration.Run.Container = $container
        $privateResults = Invoke-Pester -Configuration $PesterConfiguration
    }
    else {
        # Write-Error 'Test not found' -ErrorAction Stop
    }

}

# try {

#     if ($publicResults.Failed -eq 0 -and $privateResults.Failed -eq 0) {
#         # build the module
Build-Module -SourcePath $sourceFolder -OutputDirectory $outputFolder
#     }
#     else {
#         Write-Error 'Tests failed, building module not possible'
#     }

# }
# catch {
#     Write-Error 'Tests results not available, building module not possible'
# }