Set-ExecutionPolicy "Unrestricted"
Write-Host ****************************************************************************************************************************************************************** -ForegroundColor Magenta -BackgroundColor Black
Write-Host "Downloading and Installing Radiant One (v7.3) From Stable Releases Only! Remodel Testing"
Write-Host ****************************************************************************************************************************************************************** -ForegroundColor Magenta -BackgroundColor Black
Write-Host "Remember to run this as an Administrator" -ForegroundColor Magenta -BackgroundColor Black
#Enter the version of Radiant One to be downloaded
$version = Read-Host 'Enter the version of the Radiant one to download?'
$patchorupdate = Read-Host -Prompt 'Update or Freshinstall? Type UPDATE to download the updater / INSTALL to download the complete Installer!'
$downloadlocation = Read-Host 'Enter the Download location?'
$extractlocation = Read-Host 'Enter the path to extract the contents of the zip file (RLI_HOME) [Default location is C:\radiantone\vds]?'

#Function to download the installer or updater
function Download-Fid([string]$a, [string]$b){
    $colorscheme = (Get-Host).PrivateData
    $colorscheme.ProgressBackgroundColor = "black"
    $colorscheme.ProgressForegroundColor = "Magenta"
    Import-Module BitsTransfer
    $start_time = Get-Date
    Start-BitsTransfer $a $b -Description "Just a moment while the download completes XD"
    Write-Output "Download complete -- Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
}

#Function to test whether a location exists
function Test-Location([string]$c){
	$return = Test-Path $c
	return $return
}

#Extracting the downloaded zip file to RLI_HOME
function creatingRliHome([string]$rli_home, [string]$rli_home_final){
	#Create the environment variable
	$env:RLI_HOME=$rli_home
	Write-Host -Message "Env variables created" -ForegroundColor Magenta -BackgroundColor Black
		if(Test-Location -c $rli_home){
			"Path already exists.Removing contents from the path"
			Remove-Item $rli_home\* -Force -Recurse
			#Write-Host $rli_home
			Expand-Archive $downloadlocation_final -DestinationPath $rli_home_final -Force -Verbose
		}else{
			New-Item -Path "$rli_home" -ItemType Directory
			Write-Host 'Directory Created!Extracting!'
			Expand-Archive $downloadlocation_final -DestinationPath $rli_home_final -Force -Verbose
		}
	Write-Host -Message "Files Extracted"  -ForegroundColor Magenta -BackgroundColor Black
}

#Function to create the license file
function createLicenseFile([string]$lic){
	$license_file = $extractlocation+ '\vds_server\license.lic'
	New-Item $license_file
	Set-Content $license_file $lic
	Write-Host -Message "License file Created"  -ForegroundColor Magenta -BackgroundColor Black
}

#Creating the properties file
function createPropertiesFile([string]$clrname, [string]$pass){
	$properties_file_location = $extractlocation+ '\install\install-sample.properties' 
	Write-Host "Generating the properties file"  -ForegroundColor Magenta -BackgroundColor Black
	(Get-Content -Path $properties_file_location).replace('cluster1',$clrname) | Set-Content $properties_file_location
	(Get-Content -Path $properties_file_location).replace('StrongP@ssword1',$pass) | Set-Content -Path $properties_file_location
	Get-Content $properties_file_location 
	}

#Build the URL depending on update/fresh install
if($patchorupdate -eq 'INSTALL'){
	$downloadurl = "http://10.11.12.113/share/artifacts/stable_releases/${version}/installers/ces/radiantone_${version}_full_windows_64.zip"
    $downloadlocation_final = $downloadlocation + "\radiantone_${version}_windows_64.zip"
	#check if the Download location already exists
	if(Test-Location -c $downloadlocation){
		"Location Exists!...Downloading.....!"
		Download-Fid -a $downloadurl -b $downloadlocation_final
		#can be made global variable
		$propfile = $extractlocation+ '\install\install-sample.properties'
		$extractlocation_final = $extractlocation -replace "vds$",""
		creatingRliHome -rli_home $extractlocation -rli_home_final $extractlocation_final
		$license = Read-Host 'Enter the license:'
		createLicenseFile -lic $license
		$cluster_name = Read-Host 'Enter the cluster name:'
		$password = Read-Host 'Enter the password:'
		createPropertiesFile -clrname $cluster_name -pass $password
		Write-Host $propfile
		#Installing using silent install
		$installcommand = $extractlocation+ '\bin\InstanceManager.exe --setup-install '+$propfile
		Write-Host "Installing RadiantOne '${version}'"  -ForegroundColor Magenta -BackgroundColor Black
		Invoke-Expression -Command $installcommand
		Write-Host "Installation completed! Do you want to restart the machine?"  -ForegroundColor Magenta -BackgroundColor Black
			$yesno=Read-Host "Enter yes or no"
			if($yesno -eq 'yes'){
			Restart-Computer }else{
			exit}
	}else{
			New-Item -Path "$downloadlocation" -ItemType Directory
			Write-Host 'Directory Created! Downloading to the directory!'
			Download-Fid -a $downloadurl -b $downloadlocation_final
			creatingRliHome -rli_home $extractlocation
			$license = Read-Host 'Enter the license:'
			createLicenseFile -lic $license
			$cluster_name = Read-Host 'Enter the cluster name:'
			$password = Read-Host 'Enter the password:'
			createLicenseFile -lic $license
			createPropertiesFile -clrname $cluster_name -pass $password
			#Installing using silent install
			echo $properties_file_location
			$installcommand = $extractlocation+ '\bin\InstanceManager.exe --setup-install '+$properties_file_location
			Write-Host -Message "Installing RadiantOne '${version}'"  -ForegroundColor Magenta -BackgroundColor Black
			Invoke-Expression -Command $installcommand
			Write-Host -Message "Installation completed! Do you want to restart the machine?"  -ForegroundColor Magenta -BackgroundColor Black
			$yesno=Read-Host "Enter yes or no"
			if($yesno -eq 'yes'){
			Restart-Computer }else{
			exit}
		}
}
eLseif($patchorupdate -eq 'UPDATE'){
    $downloadurl = "http://10.11.12.113/share/artifacts/stable_releases/${version}/update_installers/ces/radiantone_ua_${version}_windows_64.exe"
	$downloadlocation_final = $downloadlocation + "\radiantone_ua_${version}_windows_64.exe"
	if(Test-Location -c $downloadlocation){
    "Location Exists - Downloading!"
	Download-Fid -a $downloadurl -b $downloadlocation_final
	Write-Host 'File downloaded - Stopping servers' 
			#invoke expression to run the stop_servers bat
			$stopserversbatlocation = "${extractlocation}\bin\advanced\stop_servers.bat"
			#Write-Host $stopserversbatlocation
			Start-Process -Wait -FilePath "$stopserversbatlocation" -NoNewWindow
			#start process to run the updater.exe file
			Start-Process -Wait -FilePath "$downloadlocation_final" -ArgumentList "/S" -PassThru
			#restart the machine
	}else{
			New-Item -Path "$downloadlocation" -ItemType Directory
			Write-Host 'Directory Created! Downloading to the directory!'
			Download-Fid -a $downloadurl -b $downloadlocation_final
			Write-Host 'File downloaded - Stopping servers' 
			#invoke expression to run the stop_servers bat
			$stopserversbatlocation = "${extractlocation}\bin\advanced\stop_servers.bat"
			#Write-Host $stopserversbatlocation
			Start-Process -Wait -FilePath "$stopserversbatlocation" -NoNewWindow
			#start process to run the updater.exe file
			Start-Process -Wait -FilePath "$downloadlocation_final" -ArgumentList "/S" -PassThru
			#restart the machine
		}
}
 
else{
 Write-Warning -Message 'Please enter a valid option!'   
}


