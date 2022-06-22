param(
    [parameter(Mandatory = $true)]
    [System.IO.FileInfo]$File,

    [parameter(Mandatory = $false)]
    [string[]]$ScriptAnalyzerRulesPath,

    [parameter(Mandatory = $false)]
    [string]$HelpRulesFile

)

# BeforeDiscovery {
BeforeAll {

    if ( $ScriptAnalyzerRulesPath -isnot [Array]) {
        $ScriptAnalyzerRulesPath = @($ScriptAnalyzerRulesPath)
    }

    $rulesPath = @()

    $ScriptAnalyzerRulesPath | ForEach-Object {

        $rulesPath += @{
            'Path' = $_
        }

    }

    $fileName = $File.Name
    $directoryName = $File.Directory

    # These are just to stop the script analyzer marking an "Unused Variable"
    # $filePath = $file.FullName

    $fileAST = [System.Management.Automation.Language.Parser]::ParseFile($File.FullName, [ref]$null, [ref]$Null)

    # Returns function name
    $functionName = @()
    $fileAST.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) | ForEach-Object { $functionName += $_.name }
    $fileFunctionName = (Get-ItemProperty -Path $file.FullName).BaseName

    $helpTestResult = TestHelp -File $File

}

Describe 'Script Tests' -Tag 'Script' {

    Context "Script: $fileName at $directoryName" {

        # should be only one function in the script file
        It 'file should contain only one function' {
            $functionName.Count | Should -BeExactly 1
        }

        # Check function name matches name of script (if applicable)
        It 'funtion should match file name' {
            if ($functionName.Count -gt 1) {
                Set-ItResult -Skipped -Because "$($functionName.Count) functions found in script file"
            }
            else {
                $functionName | Should -BeExactly $fileFunctionName
            }
        }

        # test help matches parameter

        It 'help parameters should match param block parameters' -TestCases $helpTestResult {

            $_.Message | Should -BeNullOrEmpty

        }


        # It 'check script has valid PowerShell syntax' -Tag 'ValidSyntax' {

        #     $ErrorCount | Should -Be 0

        # }

        # It 'check help must contain required elements' -Tag 'HelpMustContainRequiredElements' {

        #     {

        #         TestRequiredToken -HelpTokens $helpTokens -HelpRulesPath $HelpRulesPath

        #     } |
        #         Should -Not -Throw

        # }

        # It 'check help must not contain unspecified elements' -Tag 'HelpMustContainUnspecifiedElements' {

        #     {

        #         TestUnspecifiedToken -HelpTokens $helpTokens -HelpRulesPath $HelpRulesPath

        #     } |
        #         Should -Not -Throw

        # }

        # It 'check help elements text is not empty' -Tag 'HelpElementsNotEmpty' {

        #     {

        #         TestHelpTokensTextIsValid -HelpTokens $helpTokens

        #     } | Should -Not -Throw

        # }

        # It 'check help elements Min/Max counts are valid' -Tag 'HelpElementsMinMaxCount' {

        #     {

        #         TestHelpTokensCountIsValid -HelpTokens $helpTokens -HelpRulesPath $HelpRulesPath

        #     } | Should -Not -Throw

        # }

        # It 'check script contains [CmdletBinding] attribute' -Tag 'ContainsCmdletBinding' {

        #     $cmdletBindingCount = (@(GetTokenMarker -ParsedContent $ParsedFile -Type 'Attribute' -Content 'CmdletBinding')).Count

        #     $cmdletBindingCount | Should -Be 1

        # }

        # It 'check script contains [OutputType] attribute' -Tag 'ContainsOutputType' {

        #     $outputTypeCount = (@(GetTokenMarker -ParsedContent $ParsedFile -Type 'Attribute' -Content 'OutputType')).Count

        #     $outputTypeCount | Should -Be 1

        # }

        # It 'check script [OutputType] attribute is not empty' -Tag 'OutputTypeNotEmpty' {

        #     $outputTypeToken = (GetToken -ParsedContent $ParsedFile -Type 'Attribute' -Content 'OutputType')

        #     $outputTypeValue = @($outputTypeToken | Where-Object { $_.Type -eq 'Type' })

        #     $outputTypeValue | Should -Not -BeNullOrEmpty

        # }

        # # Note: Disabled because I'm questioning the validity of the rule. So many function haven't got a need for params
        # # It "check script contains param attribute"  -Tag "ContainsParam" {

        # #     $paramCount = (@(GetTokenMarker -ParsedContent $ParsedFile -Type "Keyword" -Content "param")).Count

        # #     $paramCount | Should -Be 1

        # # }

        # It 'check script param block variables have type' -Tag 'ParamVariablesHaveType' {

        #     $parameterVariables = GetScriptParameter -Content $fileContent

        #     if ($parameterVariables.Count -eq 0) {

        #         Set-ItResult -Inconclusive -Because 'No parameters found'

        #     }

        #     {

        #         TestParameterVariablesHaveType -ParameterVariables $parameterVariables

        #     } | Should -Not -Throw

        # }

        # It 'check script contains no PSScriptAnalyzer suppressions' -Tag 'NoScriptAnalyzerSuppressions' {

        #     $suppressCount = (@(GetTokenMarker -ParsedContent $ParsedFile -Type 'Attribute' -Content 'Diagnostics.CodeAnalysis.SuppressMessageAttribute')).Count
        #     $suppressCount | Should -Be 0

        #     $suppressCount = (@(GetTokenMarker -ParsedContent $ParsedFile -Type 'Attribute' -Content 'Diagnostics.CodeAnalysis.SuppressMessage')).Count
        #     $suppressCount | Should -Be 0

        # }

        It 'check script contains no PSScriptAnalyzer failures' -Tag 'NoScriptAnalyzerFailures' {

            $AnalyserFailures = @(Invoke-ScriptAnalyzer -Path $File)

            ($AnalyserFailures | ForEach-Object { $_.Message }) | Should -BeNullOrEmpty

        }

        It "check script contains no PSScriptAnalyser rule failures '<_.Path>" -Tag 'NoScriptAnalyzerExtraRulesFailures' -TestCases $rulesPath {

            param($Path)

            if ( [string]::IsNullOrEmpty($Path)) {

                Set-ItResult -Inconclusive -Because "Empty ScriptAnalyzerRulesPath '$Path'"

            }

            if ( -not (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {

                Set-ItResult -Inconclusive -Because "ScriptAnalyzerRulesPath path '$Path' not found"

            }

            $AnalyserFailures = @(Invoke-ScriptAnalyzer -Path $File -CustomRulePath $Path)

            $AnalyserFailures | ForEach-Object { $_.Message } | Should -BeNullOrEmpty

        }

        # It 'check Import-Module statements have valid format' -Tag 'ValidImportModuleStatements' {

        #     $importModuleTokens = @($ParsedFile | Where-Object { $_.Type -eq 'Command' -and $_.Content -eq 'Import-Module' })

        #     if ($importModuleTokens.Count -eq 0) {

        #         Set-ItResult -Inconclusive -Because 'No Import-Module statements found'

        #     }

        #     {

        #         TestImportModuleIsValid -ParsedContent $ParsedFile -ImportModuleTokens $importModuleTokens

        #     } | Should -Not -Throw

        # }

    }

}
