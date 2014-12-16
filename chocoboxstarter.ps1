
Param (
  [Parameter(Mandatory=$True,Position=1)][string]$ConfigURL
  )

"`r`n`r`nGetting Started..." | out-default
set-executionpolicy bypass -force
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')) 
$env:path = "$($env:ALLUSERSPROFILE)\chocolatey\bin;$($env:Path)"

"`r`n`r`nChocolately Installed, Now Installing BoxStarter" | out-default
choco install BoxStarter
."$env:APPDATA\BoxStarter\BoxStarterShell.ps1"
