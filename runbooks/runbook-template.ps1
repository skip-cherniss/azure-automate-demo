<#
    .AUTHOR
    Skip Cherniss

    .SYNOPSIS
    something high speed

    .DESCRIPTION
    something low drag

    .PARAMETER resourceGroupName
    Specifies the resourceGroupName the disk is in and where the snapshot will be created
        
    .INPUTS
    None. You cannot pipe objects to this runbook

    .OUTPUTS
    This will output a JSON processResult to include the success of the request, error message, exception, script stack trace and the result object
    The result object will include ...

#>
	Param(
	     [parameter(Mandatory=$true)]
	     [string]$resourceGroupName
	)

    $processResult = New-Object -TypeName PSObject
    $processResult | Add-Member -Name IsSuccessfull -MemberType NoteProperty -Value $true
    $processResult | Add-Member -Name ErrorMessage -MemberType NoteProperty -Value ([String]::Empty)
    $processResult | Add-Member -Name Exception -MemberType NoteProperty -Value $null
    $processResult | Add-Member -Name ScriptStackTrace -MemberType NoteProperty -Value $null
    $processResult | Add-Member -Name Result -MemberType NoteProperty -Value $null

    try
    {

        $clientId = Get-AutomationVariable -Name 'ClientId'

        Connect-AzAccount -Identity -AccountId $clientId
                
        ### ///////////////////////////////////////////////////////////////////////////////////////////////
        ### *******  INITIALIZE VARIABLES
        ### ///////////////////////////////////////////////////////////////////////////////////////////////


        ### ///////////////////////////////////////////////////////////////////////////////////////////////
        ### *******  ACTION 1
        ### ///////////////////////////////////////////////////////////////////////////////////////////////


        ### ///////////////////////////////////////////////////////////////////////////////////////////////
        ### *******  ACTION 2
        ### ///////////////////////////////////////////////////////////////////////////////////////////////

    }
    catch
    {
        $processResult.IsSuccessfull = $false
        $processResult.ErrorMessage = $PSItem.ToString()
        $processResult.Exception = $PSItem.Exception.GetType().Name
        $processResult.ScriptStackTrace = $PSItem.ScriptStackTrace
    }

    $resultObject = New-Object -TypeName PSObject
    $resultObject | Add-Member -Name resourceGroupName -MemberType NoteProperty -Value $resourceGroupName
    
    $processResult.Result = $resultObject

    Write-Output ( $processResult | ConvertTo-Json)
