# Use the Google cache version of the site, as Invoke-WebRequest does not support JavaScript
$sourceUrl = 'https://webcache.googleusercontent.com/search?q=cache:https://www.java.com/en/download/manual.jsp&strip=1'
$sourceTempfile = $env:TEMP + "\tempjava.exe"


function Test-IsElevated {
    if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        return $true
    } else {
        return $false
    }
}


Clear-Host
Write-Host "Updating Oracle Java SE to the most recent version"
Write-Host "------------------------------------------------------------"
Write-Host

Write-Host "Checking for elevated permissions"
if (Test-IsElevated) {
    Write-Host "  Script running elevated."
} else {
    Write-Host "  Script not running elevated, exiting."
    Start-Sleep -s 10
    exit 1
}
Write-Host

Write-Host "Downloading file"
ForEach ($link in ((Invoke-WebRequest $sourceUrl -UseBasicParsing).links)) {
    if ($link.title -ieq "Download Java software for Windows (64-bit)") {
        $sourceUrl = $link.href
        break
    }
}

(New-Object System.Net.WebClient).DownloadFile($sourceUrl, $sourceTempfile)

if (!(Test-Path $sourceTempfile)) {
    Write-Host "  Problem downloading file, exiting."
    Start-Sleep -s 10
    exit 1
} else {
    Write-Host "  Successful."
}

Write-Host
Write-Host "Comparing versions"
if (!(Test-Path $sourceTempfile)) {
    $downloadVersion = [System.Version]::Parse("0.0.0.0")
} else {
    $downloadVersion = [System.Version]::Parse(([System.Diagnostics.FileVersionInfo]::GetVersionInfo($sourceTempfile)).ProductVersion)
}


if (!(Get-Command java -ErrorAction SilentlyContinue)) {
    $installedVersion = [System.Version]::Parse("0.0.0.0")
} else {
    $installedVersion = [System.Version]::Parse((Get-Command java | Select-Object -ExpandProperty Version).toString())
}


if ($downloadVersion -gt $installedVersion) {
    Write-Host "  Downloaded version $downloadVersion is newer than installed version $installedVersion."
    Write-Host
    Write-Host "Installing"
    $p = Start-Process -FilePath $sourceTempfile -ArgumentList '/s', 'AUTO_UPDATE=Enable', 'INSTALL_Silent=Enable', 'REMOVEOUTOFDATEJRES=1' -Wait -NoNewWindow -PassThru
    Write-Host ("  Exit code: " + $p.ExitCode)
} else {
    Write-Host "  Downloaded version $downloadVersion is not newer than installed version $installedVersion."
}


if ((Test-Path $sourceTempfile)) {
    Remove-Item $sourceTempfile -Force
}

Start-Sleep -s 10