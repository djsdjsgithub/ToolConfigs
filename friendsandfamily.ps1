"Getting Started..." | out-default
set-executionpolicy bypass -force
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')) 
$env:path = "$($env:ALLUSERSPROFILE)\chocolatey\bin;$($env:Path)"

"Chocolately Installed, Now Installing BoxStarter" | out-default
choco install BoxStarter
."$env:APPDATA\BoxStarter\BoxStarterShell.ps1"

"Installing Diag Tools Demo Configuration" | out-default
Install-BoxstarterPackage -PackageName https://raw.githubusercontent.com/CSI-Windows/ToolConfigs/master/friendsandfamily.boxstarter
