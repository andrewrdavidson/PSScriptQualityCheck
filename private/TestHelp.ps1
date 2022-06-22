function TestHelp {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]$File
    )

    begin {

        [System.Management.Automation.Language.ScriptBlockAst]$ScriptBlockAst = [System.Management.Automation.Language.Parser]::ParseFile($File, [ref]$null, [ref]$Null)

    }

    process {
        $results = @()
        try {
            # Finds param block
            [ScriptBlock]$ParamBlockPredicate = {
                param
                (
                    [System.Management.Automation.Language.Ast]$Ast
                )
                [bool]$ReturnValue = $false

                if ($Ast -is [System.Management.Automation.Language.ParamBlockAst]) {

                    $ReturnValue = $true;

                }
                return $ReturnValue
            }

            # Finds dynamicparam block
            [ScriptBlock]$DynamicParamBlockPredicate = {
                param
                (
                    [System.Management.Automation.Language.Ast]$Ast
                )
                [bool]$ReturnValue = $false

                if ($Ast -is [System.Management.Automation.Language.NamedBlockAst]) {
                    [System.Management.Automation.Language.NamedBlockAst]$NamedBlockAst = $Ast

                    if ($NamedBlockAst.BlockKind -eq [System.Management.Automation.Language.TokenKind]::Dynamicparam) {
                        $ReturnValue = $true;
                    }

                }
                return $ReturnValue
            }

            # Finds command element block
            # [ScriptBlock]$PipelineAstPredicate = {
            #     param
            #     (
            #         [System.Management.Automation.Language.Ast]$Ast
            #     )
            #     [bool]$ReturnValue = $false

            #     if ($Ast -is [System.Management.Automation.Language.PipelineAst]) {
            #         $ReturnValue = $true;
            #     }
            #     return $ReturnValue
            # }

            # Finds function block
            [ScriptBlock]$FunctionPredicate = {
                param
                (
                    [System.Management.Automation.Language.Ast]$Ast
                )
                [bool]$ReturnValue = $false

                if ($Ast -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
                    $ReturnValue = $true;
                }
                return $ReturnValue
            }


            [System.Management.Automation.Language.Ast[]]$FunctionBlockAsts = $ScriptBlockAst.FindAll($FunctionPredicate, $true)

            foreach ($Ast in $FunctionBlockAsts) {
                [System.Management.Automation.Language.FunctionDefinitionAst]$FunctionAst = $Ast;

                # get parameters in help already
                [System.Management.Automation.Language.CommentHelpInfo]$Help = $FunctionAst.GetHelpContent()
                $ParametersInHelp = $Help.Parameters.Keys


                $ParametersInFunction = @()

                # get static params
                [System.Management.Automation.Language.Ast[]]$ParamBlockAsts = $FunctionAst.FindAll($ParamBlockPredicate, $true)

                foreach ($Ast2 in $ParamBlockAsts) {
                    [System.Management.Automation.Language.ParamBlockAst]$ParamBlockAst = $Ast2

                    foreach ($ParamAst in $ParamBlockAst.Parameters) {
                        $ParametersInFunction += $ParamAst.Name.VariablePath.UserPath
                    }
                }

                # get dynamic params
                [System.Management.Automation.Language.Ast[]]$DynamicParamBlockAsts = $FunctionAst.FindAll($DynamicParamBlockPredicate, $true)

                foreach ($Ast3 in $DynamicParamBlockAsts) {
                    $Script = $Ast3.statements -join "`n"
                    $DynamicParamBlockScriptBlock = [ScriptBlock]::Create($script)
                    $RuntimeDictionary = Invoke-Command -ScriptBlock $DynamicParamBlockScriptBlock
                    foreach ($Param in $RuntimeDictionary.Keys) {
                        $ParametersInFunction += $Param
                    }

                }

                # check params against help params
                foreach ($FunctionParam in $ParametersInFunction) {
                    if ($null -eq $ParametersInHelp -or $ParametersInHelp -inotcontains $FunctionParam) {
                        $Result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{'Message' = "Function is missing .PARAMETER help documentation for parameter '$FunctionParam'";
                            'Extent'                                                                                = $Ast.Extent;
                            'Severity'                                                                              = 'Warning'
                        }
                        $Results += $Result
                    }
                }
                foreach ($HelpParam in $ParametersInHelp) {
                    if ($null -eq $ParametersInFunction -or $ParametersInFunction -inotcontains $HelpParam) {
                        $Result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{'Message' = "Function missing param block parameter for help documentation .PARAMETER '$HelpParam'";
                            'Extent'                                                                                = $Ast.Extent;
                            'Severity'                                                                              = 'Warning'
                        }
                        $Results += $Result
                    }
                }
            }

            if ($results.Count -eq 0) {
                $Result = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{'Message' = '';
                    'Severity'                                                                              = 'Information'
                }
                $Results += $Result
            }

            return $results
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}