Install-Module -Name WriteAscii -Force
Import-Module -Name WriteAscii 
Write-Ascii  "Installeren van MusicLoverRemote" -fore rainbow
$ErrorActionPreference = 'Stop'

# Assign the value random password to the password variable
$rustdesk_pw = (-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | % {[char]$_}))

# Get your config string from your Web portal and Fill Below
#$rustdesk_cfg = "0nI1VmL2gzch5mLrNXZk9yL6MHc0RHaiojIpBXYiwiI9EVcUpleBFnYFVlTGdjQKdlUQVFWLhDN080dsRWNxEGTa5kTBFlSml1R1plI6ISeltmIsISdl5iN4MXYu5yazVGZiojI0N3boJye"

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
    $rdver = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\MusicLoverRemote\").Version
    if ($rdver -eq "1.2.7-2") {
        Write-Output "MusicLoverRemote $rdver de nieuwste versie"
        exit
    }
} catch {
    Write-Output "MusicLoverRemote niet gevonden of versie is niet juist."
}

# Create Temp directory if it doesn't exist
if (-Not (Test-Path C:\Temp)) {
    New-Item -ItemType Directory -Force -Path C:\Temp | Out-Null
}

cd C:\Temp

# Download MusicLoverRemote
Write-Output "Downloaden van MusicLoverRemote..."
try {
powershell Invoke-WebRequest "https://desk.nas86.eu/static/configs/MusicLoverRemote.exe" -OutFile "MusicLoverRemote.exe"
} catch {
    Write-Output "Error: Gefaald om MusicLoverRemote te downloaden."
    Pause
    exit
}

# Install RustDesk silently with timeout
Write-Output "Installeren van MusicLoverRemote..."
try {
    $installProcess = Start-Process .\MusicLoverRemote.exe -ArgumentList "--silent-install" -PassThru -NoNewWindow
    $installProcess.WaitForExit(60000)  # Wait for 60 seconds
    if (-Not $installProcess.HasExited) {
        Write-Output "Error: MusicLoverRemote installatie timed out."
        $installProcess.Kill()
        Pause
        exit
    }
} catch {
    Write-Output "Error: MusicLoverRemote installatie gefaald. Contacteer techmusiclover@outlook.be"
    Pause
    exit
}

# Check if MusicLoverRemote service is installed
$ServiceName = 'MusicLoverRemote'
$arrService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($arrService -eq $null) {
    Write-Output "Installeren van MusicLoverRemote service..."
    cd $env:ProgramFiles\MusicLoverRemote 
    try {
        Start-Process .\MusicLoverRemote.exe --install-service -Wait -NoNewWindow -PassThru
        Start-Sleep -Seconds 10
    } catch {
        Write-Output "Error: Gefaald om de MusicLoverRemote service te installeren."
        Pause
        exit
    }
}

# Ensure the MusicLoverRemote  service is running
$arrService = Get-Service -Name $ServiceName
while ($arrService.Status -ne 'Running') {
    Start-Service $ServiceName
    Start-Sleep -Seconds 5
    $arrService.Refresh()
}

# Get RustDesk ID
cd $env:ProgramFiles\MusicLoverRemote 
try {
    $rustdesk_id = & .\MusicLoverRemote.exe --get-id | Out-String
    $rustdesk_id = $rustdesk_id.Trim()
} catch {
    Write-Output "Error: Gefaald om de MusicLoverRemote ID te lokaliseren."
    Pause
    exit
}

# Apply MusicLoverRemote  configuration
Write-Output "Instellen van MusicLoverRemote ..."
try {
    & .\MusicLoverRemote.exe --config $rustdesk_cfg
} catch {
    Write-Output "Error: Gefaald om MusicLoverRemote in te stellen."
    Pause
    exit
}

# Set MusicLoverRemote password
Write-Output "Instellen van MusicLoverRemote wachtwoord..."
try {
    & .\MusicLoverRemote.exe --password $rustdesk_pw
} catch {
    Write-Output "Error: Gefaald om het MusicLoverRemote wachtwoord in te stellen."
    Pause
    exit
}

# Display MusicLoverRemote ID and Password
Write-Output "..............................................."
Write-Output "MusicLoverRemote ID: $rustdesk_id"
Write-Output "MusicLoverRemote Wachtwoord: $rustdesk_pw"
Write-Output "..............................................."

# Copy ID and password to clipboard
try {
    $clipboardContent = "MusicLoverRemote ID: $rustdesk_id`nPassword: $rustdesk_pw"
    $clipboardContent | Set-Clipboard
    Write-Output "Het MusicLoverRemote ID en wachtwoord zijn gekopieerd naar het clipboard."
} catch {
    Write-Output "Error: Failed to copy MusicLoverRemote ID and Wachtwoord to the clipboard."
}

# Inform the user and wait for key press to close
Write-Output "Druk op een knop om dit venster te sluiten."
write-output "Bij enig probleem contacteer via mail indien Techmusiclover@outlook.be."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
