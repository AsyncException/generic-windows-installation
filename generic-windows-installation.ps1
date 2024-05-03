Function Create-TempFolder {
    $parent = [System.IO.Path]::GetTempPath()
    [string]$name = [System.Guid]::NewGuid()
    $script:temp_folder = Join-Path $parent $name
    $null = New-Item -ItemType Directory -Path $temp_folder
}

Function Remove-TempFolder {
    Remove-Item -Path $temp_folder -Recurse
}

Function Install-Powershell7 {
    Write-Host "Installing powershell 7"
    # Get the latest release
    $release_url = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
    $latest_release_url = Invoke-RestMethod $release_url | Select-Object -ExpandProperty assets | Where-Object "browser_download_url" -Match 'x64.msi' | Select-Object -ExpandProperty "browser_download_url"

    #Download installation
    $destination_path = Join-Path $script:temp_folder "Powershell-x64.msi"
    Invoke-RestMethod -Uri $latest_release_url -OutFile $destination_path

    # install
    Start-Process msiexec.exe -Wait -ArgumentList "/i `"$($destination_path)`""

    # delete file
    Remove-Item $destination_path
}

Function Install-WinGet {
    Write-Host "Installing WinGet"
    # Get the latest release
    $release_url = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    $latest_release_url = Invoke-RestMethod $release_url | Select-Object -ExpandProperty assets | Where-Object "browser_download_url" -Match '.msixbundle' | Select-Object -ExpandProperty "browser_download_url"

    #Download installation
    $destination_path = Join-Path $temp_folder "Setup.msix"
    Invoke-RestMethod -Uri $latest_release_url -OutFile $destination_path

    # install
    Add-AppxPackage -Path $destination_path

    # delete file
    Remove-Item $destination_path
}

Function Install-GithubDesktop {
    $download_url = "https://central.github.com/deployments/desktop/desktop/latest/win32"
    $destination_path = Join-Path $script:temp_folder "Github.exe"
    Invoke-RestMethod -Uri $download_url -OutFile $destination_path

    Start-Process $destination_path -Wait -ArgumentList "/silent"

    Remove-Item $destination_path
}

Function Test-Script {
Write-Host $script:temp_folder
}

Create-TempFolder

if($PSVersionTable.PSVersion.Major -eq 5) {
    Install-Powershell7
    Remove-TempFolder

    pwsh $PSScriptRoot

}

Install-WinGet

$null = Winget install github --silent --accept-source-agreements --accept-package-agreements