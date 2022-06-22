# NOTE: follow nuget syntax for versions: https://docs.microsoft.com/en-us/nuget/reference/package-versioning#version-ranges-and-wildcards
@{
    'PSDependOptions'              = @{
        Target = 'CurrentUser'
    }
    'Pester'                       = @{
        Name       = 'Pester'
        Version    = '5.3.3'
        Parameters = @{
            SkipPublisherCheck = $true
        }
    }
    'ModuleBuilder'                = 'Latest'
    'PowerShellGet'                = 'Latest'
    'PSScriptAnalyzer'             = 'Latest'
    'Indented.ScriptAnalyzerRules' = 'Latest'
}
