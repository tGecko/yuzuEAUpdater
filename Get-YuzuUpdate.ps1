
$yuzuRoamingFolder = Join-Path $env:APPDATA "yuzu"
$configPath = Join-Path $yuzuRoamingFolder "updateConfig.txt"

$yuzuFolder = Get-Content $configPath -ErrorAction SilentlyContinue

while (($null -eq $yuzuFolder) -or (!(Test-Path (Join-Path $yuzuFolder "yuzu.exe")))) {
    # yuzuFolder not defined or couldn't find yuzu.exe. Let user choose folder
    Write-Host "Please select yuzu program folder (the folder containing yuzu.exe)"
    Add-Type -AssemblyName System.Windows.Forms
    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowser.Description = 'Select folder containing yuzu.exe'
    $result = $FolderBrowser.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))
    if ($result -eq [Windows.Forms.DialogResult]::OK) {
        $yuzuFolder = $FolderBrowser.SelectedPath
    }
    else {
        # user pressed cancel
        exit
    }
    # write folder location to %appdata%\yuzu\updateConfig.txt
    Set-Content $configPath -Value $yuzuFolder
}

# no progress bars makes downloads way faster
$ProgressPreference = 'SilentlyContinue'

Write-Host "Getting latest yuzu version"
$content = Invoke-WebRequest -Uri "https://github.com/pineappleEA/pineapple-src/releases/latest"
$latestVersion = ([regex]::match($content.RawContent, "Release EA-\d\d\d\d").Value)[-4..-1] -join ""

Write-Host "Getting current yuzu version"
$exeContent = Get-Content (Join-Path $yuzuFolder "yuzu.exe")
$currentVersion = ([regex]::match($exeContent, "\x00{3}\d{4}\x00{8}").Value)[3..6] -join ""

write-host "Current version: $currentVersion`nLatest Version: $latestVersion"
if ($latestVersion -gt $currentVersion) {
    Write-Host "Newer version detected, initializing update.."
    Write-Host "Downloading yuzu early access version $latestVersion"
    $downloadlink = "https://github.com/pineappleEA/pineapple-src/releases/download/EA-$latestVersion/Windows-Yuzu-EA-$latestVersion.zip"
    $downloadFilePath = Join-Path $env:TEMP "$latestVersion.zip"
    Invoke-WebRequest -Uri $downloadlink -OutFile $downloadFilePath
    Write-Host "File Downloaded. Backing up current install"
    if (Get-Process "yuzu" -ErrorAction SilentlyContinue) {
        Write-Host "Yuzu is running, qutting it."
        Get-Process "yuzu" | Stop-Process -Force
        Start-Sleep -Milliseconds 200
    }
    Rename-Item -Path $yuzuFolder -NewName "$yuzuFolder-Backup-$currentVersion"
    Write-Host "Extracting version $latestVersion to $yuzuFolder"
    Expand-Archive -Path $downloadFilePath -DestinationPath $yuzuFolder
    Move-Item "$(Join-Path $yuzuFolder "yuzu-windows-msvc-early-access")\*" $yuzuFolder
    Remove-Item (Join-Path $yuzuFolder "yuzu-windows-msvc-early-access")
    Remove-Item $downloadFilePath
}
else {
    Write-Host "Latest version already installed"
}
Write-Host "Starting yuzu."
Start-Sleep -Seconds 1
Start-Process (Join-Path $yuzuFolder "yuzu.exe")

