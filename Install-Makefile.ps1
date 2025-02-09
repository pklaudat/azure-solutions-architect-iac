# Check if Chocolatey is installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey is not installed. Installing Chocolatey..." -ForegroundColor Yellow

    # Install Chocolatey
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    # Verify installation
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Failed to install Chocolatey. Exiting script." -ForegroundColor Red
        exit 1
    }

    Write-Host "Chocolatey installed successfully!" -ForegroundColor Green
}

# Install GNU Make using Chocolatey
Write-Host "Installing GNU Make..." -ForegroundColor Yellow
choco install make --yes

# Verify Make installation
if (Get-Command make -ErrorAction SilentlyContinue) {
    Write-Host "GNU Make installed successfully!" -ForegroundColor Green
    make --version
} else {
    Write-Host "Failed to install GNU Make. Please check for errors above." -ForegroundColor Red
}
