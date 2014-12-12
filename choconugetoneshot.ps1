
"***** > Getting Started..." | out-default
set-executionpolicy bypass -force
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')) 
$env:path = "$($env:ALLUSERSPROFILE)\chocolatey\bin;$($env:Path)"

"***** > Chocolately Installed, Now Installing BoxStarter" | out-default
choco install BoxStarter
."$env:APPDATA\BoxStarter\BoxStarterShell.ps1"

$IsDesktop = ((gwmi win32_operatingsystem).ProductType -eq 1)

"***** > Chocolatey Server Install" | Out-Default
cinst chocolatey.server

"***** > Enable Web Services" | Out-Default

If ($IsDesktop) {cinst webpi;$env:path += 'C:\Program Files\Microsoft\Web Platform Installer\';"`r`n`r`n***** Close the Web Platform Installer (WebPi) if it displays`r`n`r`n" | out-default} else {import-module servermanager}

If ($IsDesktop) {cinst IIS-WebServerRole -source WindowsFeatures} Else {add-windowsfeature Web-Server}
If ($IsDesktop) {cinst ASPNET -source webpi} Else {add-windowsfeature Web-Asp-Net}
If ($IsDesktop) {cinst DefaultDocument -source webpi} Else {add-windowsfeature Web-Default-Doc}
If ($IsDesktop) {cinst DynamicContentCompression -source webpi} Else {add-windowsfeature Web-Dyn-Compression}
If ($IsDesktop) {cinst HTTPRedirection -source webpi} Else {add-windowsfeature Web-Http-Redirect}
If ($IsDesktop) {cinst IIS7_ExtensionLessURLs -source webpi} Else {}
If ($IsDesktop) {cinst IISManagementConsole -source webpi} Else {add-windowsfeature Web-Mgmt-Console}
If ($IsDesktop) {cinst ISAPIExtensions -source webpi} Else {add-windowsfeature Web-ISAPI-Ext}
If ($IsDesktop) {cinst ISAPIFilters -source webpi} Else {add-windowsfeature Web-ISAPI-Filter}
If ($IsDesktop) {cinst NETExtensibility -source webpi} Else {}
If ($IsDesktop) {cinst RequestFiltering -source webpi} Else {add-windowsfeature Web-Filtering}
If ($IsDesktop) {cinst StaticContent -source webpi} Else {add-windowsfeature Web-Static-Content}
If ($IsDesktop) {cinst StaticContentCompression -source webpi} Else {add-windowsfeature Web-Stat-Compression}
If ($IsDesktop) {cinst UrlRewrite2 -source webpi} Else {}

#add-windowsfeature Web-Basic-Auth
$IsOS62OrGreater = ([Environment]::OSVersion.Version -ge [Version]'6.2')

If ($IsOS62OrGreater) {

If ($IsDesktop) {cinst IIS-NetFxExtensibility45 -source WindowsFeatures} Else {Add-WindowsFeature NET-Framework-45-ASPNET}
cinst NetFx4Extended-ASPNET45 -source WindowsFeatures
If ($IsDesktop) {cinst IIS-ASPNet45 -source WindowsFeatures} Else {Add-WindowsFeature Web-Asp-Net45}

} Else {
cinst ASPNET_REGIIS -source webpi
."$env:windir\microsoft.net\framework\v4.0.30319\aspnet_regiis.exe" -i
}

"***** > Chocolatey Server Config" | Out-Default
$packageName = 'chocolatey.server'
$projectname = "ChocolatelyServer"
$toolsDir = "C:\programdata\chocolatey\lib\chocolatey.server.0.1.1\tools"
$webToolsDir = Join-Path $toolsDir $packageName
$installDir = "C:\TOOLS"
$webInstallDir = Join-Path $installDir $packageName


If ($IsDesktop) {cinst ASPNET_REGIIS -source webpi} Else {}

"***** > Web Server Config" | Out-Default
Import-Module WebAdministration
Remove-WebSite -Name "Default Web Site" -ErrorAction SilentlyContinue
Remove-WebSite -Name "$projectname" -ErrorAction SilentlyContinue
New-WebSite -ID 1 -Name "$projectname" -Port 80 -PhysicalPath "$webInstallDir" -Force
 
If ($IsDesktop) {$networkSvc = 'NT AUTHORITY\NETWORK SERVICE'} Else {$networkSvc = "IIS APPPOOL\DefaultAppPool"}

"Setting folder permissions on `'$webInstallDir`' to 'Read' for user $networkSvc" | Out-default
$acl = Get-Acl $webInstallDir
$acl.SetAccessRuleProtection($False, $True)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("$networkSvc","Read", "ContainerInherit, ObjectInherit", "None", "Allow");
$acl.AddAccessRule($rule);
Set-Acl $webInstallDir $acl  
   
$webInstallAppDataDir = Join-Path $webInstallDir 'App_Data'
"Setting folder permissions on `'$webInstallAppDataDir`' to 'Modify' for user $networkSvc" | Out-Default
$acl = Get-Acl $webInstallAppDataDir
$acl.SetAccessRuleProtection($False, $True)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("$networkSvc","Modify", "ContainerInherit, ObjectInherit", "None", "Allow");
$acl.AddAccessRule($rule);
Set-Acl $webInstallAppDataDir $acl

If (!$Desktop) {
$webInstallAppDataDir = Join-Path $webInstallDir 'App_Data'
"Setting folder permissions on `'$webInstallAppDataDir`' to 'Modify' for user $networkSvc" | Out-Default
$acl = Get-Acl $webInstallAppDataDir
$acl.SetAccessRuleProtection($False, $True)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("IUSR","Modify", "ContainerInherit, ObjectInherit", "None", "Allow");
$acl.AddAccessRule($rule);
Set-Acl $webInstallAppDataDir $acl
}

# Import-Module WebAdministration
$appPoolPath = "IIS:\AppPools\$projectName"
#$pool = new-object
"You can safely ignore the next error if it occurs related to getting an app pool that doesn't exist" | out-default
$pool = Get-Item $appPoolPath
if ($pool -eq $null) {
  Write-Host "Creating the app pool `'$appPoolPath`'"
   $pool = New-Item $appPoolPath 
 }

$pool.processModel.identityType = "NetworkService" 
$pool | Set-Item
Set-itemproperty $appPoolPath -Name "managedRuntimeVersion" -Value "v4.0"
#Set-itemproperty $appPoolPath -Name "managedPipelineMode" -Value "Integrated"
Start-WebAppPool "$projectName"
"Creating the site `'$projectName`' with appPool `'$projectName`'" | out-default
New-WebApplication "$projectName" -Site "$projectname" -PhysicalPath $webInstallDir -ApplicationPool "$projectName" -Force
 
"Open proper firewall rules" | Out-Default
netsh advfirewall firewall add rule name="Open Port 80" dir=in action=allow protocol=TCP localport=80

"`r`n`r`n DOING A TEST`r`n`r`n" | Out-Default
If (Test-Path alias:wget) {remove-item alias:wget}
cinst wget

"Getting procmon source package from Chocolatey..." | out-default
cd "$env:chocolateyinstall\chocolateyinstall"
wget http://chocolatey.org/api/v2/package/procmon/ --no-check-certificate

"Pushing to new repository..." | out-default
#.\nuget.exe setapikey testing -source "http://localhost/chocolatey/"
#.\nuget.exe delete procmon 3.01 -apikey testing -noprompt -source "http://localhost/chocolatey"
#.\nuget.exe push .\procmon.3.01.nupkg -apikey testing -source "http://localhost/chocolatey"

copy-item *.nupkg $webInstallDir\app_data\packages -force
remove-item *.nupkg -force

"Listing packages in new repository..." | out-default
choco list -source "http://localhost/chocolatey"

"Installing Procmon from new repository..." | out-default
choco install procmon -source "http://localhost/chocolatey"

"If the procmon package transactions were successful your repository is ready to go." | out-default

"To install from this repo on the local machine use:`r`n`r`n choco install procmon -source `"http://$env:computername/chocolatey`"" | out-default

"if this was built on Azure, on a different machine use:`r`n`r`n choco install procmon -source `"http://<azureserviceurl>/chocolatey`"" | out-default


#start http://localhost/chocolaty
