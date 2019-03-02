[cmdletbinding()]
Param(
    [Parameter(Mandatory)]
    [String]
    [ValidateNotNullOrEmpty()]
    $ComputerName
)



# Change the lines below to match your SCCM environment
$SMSSITECODE = "SMS"
$ConfigMgrServer = "ConfigMgrServer"



if (Test-Path -Path "\\$ComputerName\C$\Windows\CCM\CcmExec.exe" -ErrorAction "SilentlyContinue") {
    Write-Output "`n`nUninstalling SCCM client, please wait..."
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Start-Process -FilePath "C:\Windows\ccmsetup\ccmsetup.exe" -ArgumentList "/uninstall" -Wait
    }
    Write-Output "Waiting 60 seconds to ensure CCMSETUP has completely exited..."
    Start-Sleep -Seconds 60
}



Write-Output "`n`nRemoving remote SCCM client folder, please wait..."
Remove-Item -Path "\\$ComputerName\Windows\SMSCFG.INI" -Force -ErrorAction "SilentlyContinue"
Remove-Item -Path "\\$ComputerName\Windows\ccm" -Recurse -Force -ErrorAction "SilentlyContinue"



if (Test-Path -Path "$ENV:SMS_ADMIN_UI_PATH\..\ConfigurationManager.psd1" -ErrorAction "SilentlyContinue") {
    if (-not (Get-PSProvider CMSITE -ErrorAction SilentlyContinue)) {
        Write-Output "`n`nImporting SCCM console PowerShell module, please wait..."
        Import-Module "$ENV:SMS_ADMIN_UI_PATH\..\ConfigurationManager.psd1"
    }
}



if (Get-PSProvider CMSITE -ErrorAction SilentlyContinue) {
    Write-Output "`n`nRemoving device from SCCM, please wait..."

    Set-location -Path "$($SMSSITECODE):"
    
    Remove-CMDevice -DeviceName $ComputerName -Confirm:$false -Force -ErrorAction "SilentlyContinue"
    Set-Location -Path (Split-Path -Path $PSCommandPath)
}



Write-Output "`n`nInstalling SCCM client, please wait...(this could take a while)"
New-Item -Path "\\$ComputerName\c$\Windows\ccmsetup" -ItemType "Directory" -Force | Out-Null
Copy-Item -Path "\\$ConfigMgrServer\SMS_WES\Client\ccmsetup.exe" -Destination "\\$ComputerName\c$\Windows\ccmsetup\" -Force
Invoke-Command -ComputerName $ComputerName -ScriptBlock {
    Start-Process -FilePath "C:\Windows\ccmsetup\ccmsetup.exe" -ArgumentList "/Service SMSSITECODE=$SMSSITECODE SMSCACHESIZE=10240 CCMENABLELOGGING=TRUE" -Wait
}



if (Test-Path -Path "C:\Windows\CCM\cmtrace.exe" -ErrorAction "SilentlyContinue") {
    & "C:\Windows\CCM\cmtrace.exe" "\\$ComputerName\c$\Windows\ccmsetup\Logs\ccmsetup.log"
}
else {
    Invoke-Item "\\$ComputerName\c$\Windows\ccmsetup\Logs\ccmsetup.log"
}