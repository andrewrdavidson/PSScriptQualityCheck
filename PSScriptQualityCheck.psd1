@{
    # The module version should be SemVer.org compatible
    ModuleVersion        = '1.0.1'

    # PrivateData is where all third-party metadata goes
    PrivateData          = @{
        # PrivateData.PSData is the PowerShell Gallery data
        PSData = @{
            # Prerelease string should be here, so we can set it
            Prerelease   = 'source'

            # Release Notes have to be here, so we can update them
            ReleaseNotes = '
            Release Notes
            -
            '

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = 'Main', 'PSScriptQualityCheck', 'Script Quality'

            # A URL to the license for this module.
            LicenseUri   = ''

            # A URL to the main website for this project.
            ProjectUri   = ''

            # A URL to an icon representing this module.
            IconUri      = ''
        } # End of PSData
    } # End of PrivateData

    # The main script module that is automatically loaded as part of this module
    RootModule           = 'PSScriptQualityCheck.psm1'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules      = @()

    # Always define FunctionsToExport as an empty @() which will be replaced on build
    FunctionsToExport    = @('Invoke-PSScriptQualityCheck')
    AliasesToExport      = @()

    # ID used to uniquely identify this module
    GUID                 = '6a5bccf1-d860-42ed-9d3b-df4b5b48fd71'
    Description          = 'A module for checkin code quality of script files.'

    # Common stuff for all our modules:
    CompanyName          = ''
    Author               = 'Andrew Davidson'
    Copyright            = 'Copyright 2022 Andrew Davidson'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion    = '7.2'
    CompatiblePSEditions = @('Core', 'Desktop')
}
