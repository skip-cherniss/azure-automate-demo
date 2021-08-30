<#
    .AUTHOR
    Skip Cherniss

    .SYNOPSIS
    download file from github and save to desktop

    .DESCRIPTION
    something low drag

    .PARAMETER resourceGroupName
    Specifies the resourceGroupName for the virtual machine
        
    .PARAMETER vmName
    Specifies the virtual machine name to download the file on
        
    .PARAMETER newfilename
    Specifies the file name to use when saving the download to the desktop
        
    .INPUTS
    None. You cannot pipe objects to this runbook

    .OUTPUTS
    This will output a JSON processResult to include the success of the request, error message, exception, script stack trace and the result object
    The result object will include ...

#>
	Param(
	     [parameter(Mandatory=$true)]
	     [string]$resourceGroupName,
         [parameter(Mandatory=$true)]
	     [string]$vmName,
         [parameter(Mandatory=$true)]
	     [string]$newfilename
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
        ### *******  SETUP DOWNLOAD FILE SCRIPT
        ### ///////////////////////////////////////////////////////////////////////////////////////////////

        function download-file {
    
        Param(
            [parameter(Mandatory=$true)]
            [string]$saveFileName
	    )
    

            try
            {
                Write-Output "Starting the thing..."
                
                $file = "https://raw.githubusercontent.com/skip-cherniss/azure-automate-demo/main/runbooks/runbook-template.ps1"
                #$saveFileName = "test.txt"
                #$fileDestination = Join-Path -Path $([Environment]::GetFolderPath("Desktop")) -ChildPath $saveFileName
                $fileDestination = Join-Path -Path "c:\users\demouser\desktop" -ChildPath $saveFileName
                Invoke-WebRequest -Uri $file -OutFile $fileDestination -ErrorAction Stop -Verbose

                Write-Output "File downloaded to vm desktop"
            }
            catch
            {
                Write-Output "ErrorMessage: " + $PSItem.ToString() + " at " + $PSItem.ScriptStackTrace
            }

        }

        $script = Get-Content Function:\download-file

        Out-File -FilePath test.ps1 -InputObject $script

        ### ///////////////////////////////////////////////////////////////////////////////////////////////
        ### *******  RUN THE SCRIPT ON THE VM
        ### ///////////////////////////////////////////////////////////////////////////////////////////////
        $parms = @{saveFileName=$newfilename}

        $output = Invoke-AzVMRunCommand `
            -Name $vmName `
            -ResourceGroupName $resourceGroupName `
            -CommandId 'RunPowerShellScript' `
            -ScriptPath test.ps1 `
            -Parameter $parms

        Remove-Item -Path test.ps1
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
    $resultObject | Add-Member -Name vmName -MemberType NoteProperty -Value $vmName     
    $resultObject | Add-Member -Name newFileName -MemberType NoteProperty -Value $newfilename 
    $resultObject | Add-Member -Name output -MemberType NoteProperty -Value $output.Value[0].message

    $processResult.Result = $resultObject
    Write-Output $output.Value.Count
    foreach($testobj in $output.Value)
    {
        Write-Output $testobj.message
    }
    
    Write-Output ( $processResult | ConvertTo-Json)
