"Getting Started..." | out-default
set-executionpolicy bypass -force
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')) 
$env:path = "$($env:ALLUSERSPROFILE)\chocolatey\bin;$($env:Path)"

"Chocolately Installed, Now Installing BoxStarter" | out-default
choco install BoxStarter
."$env:APPDATA\BoxStarter\BoxStarterShell.ps1"

"Installing QP Demo Configuration" | out-default
Install-BoxstarterPackage -PackageName https://raw.githubusercontent.com/djsdjsgithub/test/master/QPDemo.txt
