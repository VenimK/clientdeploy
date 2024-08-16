$scriptPath = $MyInvocation.MyCommand.Path
Unblock-File -Path $scriptPath
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Initialize the URLs hash table globally
$urls = @{}

# Function to download file and show a message box upon completion
function Download-File {
    param (
        [string]$Url,
        [string]$OutputPath
    )
    
    # Create a WebClient instance to download the file
    $webClient = New-Object System.Net.WebClient
    $uri = New-Object System.Uri($Url)
    
    try {
        # Download the file and validate the outcome
        $webClient.DownloadFile($uri, $OutputPath)
        [System.Windows.Forms.MessageBox]::Show("Download completed successfully.", "Download Complete")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to download the file: $_", "Download Error")
    }
}

# Create main form and other UI components
$form = New-Object System.Windows.Forms.Form
$form.Text = "RustDesk Config Editor"
$form.Size = New-Object System.Drawing.Size(700,900)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E")

# Set the form icon (make sure to specify the correct path to your icon file)
$form.Icon = New-Object System.Drawing.Icon('C:\Temp\Telenet-LogoEDIT4.ico')  # Replace with your icon file path

# Adding a logo using PictureBox
$logoPictureBox = New-Object System.Windows.Forms.PictureBox
$logoPictureBox.Location = New-Object System.Drawing.Point(400, 40)
$logoPictureBox.Size = New-Object System.Drawing.Size(200, 100)  # Adjust size as needed
$logoPictureBox.Image = [System.Drawing.Image]::FromFile('C:\Temp\EDITRustdesk--_-Developer-Guide.png')  # Replace with your logo file path
$logoPictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom  # Adjust how the image is displayed
$form.Controls.Add($logoPictureBox)

# Download section
$downloadLabel = New-Object System.Windows.Forms.Label
$downloadLabel.Location = New-Object System.Drawing.Point(20,500)
$downloadLabel.Size = New-Object System.Drawing.Size(560,20)
$downloadLabel.Text = "Download RustDesk:"
$downloadLabel.Font = New-Object System.Drawing.Font("Segoe UI",14,[System.Drawing.FontStyle]::Bold)
$downloadLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#E0E0E0")
$form.Controls.Add($downloadLabel)

# Function to update URLs based on server input
function Update-Urls {
    param (
        [string]$newBaseUrl
    )

    # Update URLs with the base URL
    $urls["Windows exe"] = "$newBaseUrl/static/configs/rustdesk-licensed-Qfi02bj5ybl5WLlR3btVmcuIXav8iOzBHd0hmI6ISawFmIsISPNBVZy10QtV1SwV3ZY10dtBFOuJVYiZme5VFUtJzTOlHUhhDajlFd5kXZ5JiOikXZrJCLi02bj5ybl5WLlR3btVmcuIXaiojI0N3boJye.exe"
    $urls["Windows installer bat"] = "$newBaseUrl/static/configs/install.bat"
    $urls["Windows Installer powershell"] = "$newBaseUrl/static/configs/install.ps1"
    $urls["Linux Installer"] = "$newBaseUrl/static/configs/install-linux.sh"
    $urls["Mac Installer"] = "$newBaseUrl/static/configs/install-mac.sh"
}

# Create a FlowLayoutPanel to hold the download buttons
$buttonContainer = New-Object System.Windows.Forms.FlowLayoutPanel
$buttonContainer.Location = New-Object System.Drawing.Point(20, 530)
$buttonContainer.Size = New-Object System.Drawing.Size(600, 300)
$buttonContainer.AutoScroll = $true
$form.Controls.Add($buttonContainer)

# Function to create download buttons dynamically
function Create-DownloadButtons {
    # Clear existing buttons
    $buttonContainer.Controls.Clear()

    foreach ($key in $urls.Keys) {
        $button = New-Object System.Windows.Forms.Button
        $button.Size = New-Object System.Drawing.Size(200,30)
        $button.Text = "Download $key"
        $button.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#4CAF50")
        $button.ForeColor = [System.Drawing.Color]::White
        $button.Add_Click({
            $url = $urls[$this.Text.Replace("Download ", "")]
            $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
            $saveFileDialog.FileName = $url.Split("/")[-1]
            $saveFileDialog.Filter = "All files (*.*)|*.*"
            if ($saveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                # Start download synchronously
                Download-File -Url $url -OutputPath $saveFileDialog.FileName
            }
        })
        $buttonContainer.Controls.Add($button)
    }
}

# Server address input
$serverLabel = New-Object System.Windows.Forms.Label
$serverLabel.Text = 'Server Address:'
$serverLabel.Location = New-Object System.Drawing.Point(20, 210)
$serverLabel.Size = New-Object System.Drawing.Size(500,20)
$form.Controls.Add($serverLabel)
$serverLabel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#4CAF50")
$serverLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#E0E0E0")
$serverLabel.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)

$serverTextBox = New-Object System.Windows.Forms.TextBox
$serverTextBox.Location = New-Object System.Drawing.Point(20, 240)
$serverTextBox.Size = New-Object System.Drawing.Size(340, 20)
$form.Controls.Add($serverTextBox)

# Event to update URLs when the server address changes
$serverTextBox.Add_TextChanged({
    # Get the new base URL from the server address textbox
    $domain = $serverTextBox.Text.Trim()

    # Prepend "https://" if the user entered a domain
    if (![string]::IsNullOrWhiteSpace($domain)) {
        $newBaseUrl = "https://$domain"

        # Update URLs with the new base URL
        Update-Urls -newBaseUrl $newBaseUrl

        # Re-create download buttons
        Create-DownloadButtons
    } else {
        # Clear buttons if the field is empty
        $urls.Clear()
        $buttonContainer.Controls.Clear()
    }
})

# Group box for Theme selection replaced with ComboBox
$themeGroup = New-Object System.Windows.Forms.GroupBox
$themeGroup.Text = 'Select Theme'
$themeGroup.Location = New-Object System.Drawing.Point(20, 20)
$themeGroup.Size = New-Object System.Drawing.Size(360, 90)
$themeGroup.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#CCCCCC") # Light grey
$form.Controls.Add($themeGroup)

# ComboBox for theme selection
$themeComboBox = New-Object System.Windows.Forms.ComboBox
$themeComboBox.Location = New-Object System.Drawing.Point(20, 30)
$themeComboBox.Size = New-Object System.Drawing.Size(300, 30)
$themeComboBox.Items.AddRange(@("Light", "Dark"))  # Corrected line
$themeComboBox.SelectedIndex = 0 # Set default selection to "Light"
$themeComboBox.ForeColor = [System.Drawing.Color]::DarkBlue
$themeGroup.Controls.Add($themeComboBox)

# Group box for Language selection replaced with ComboBox
$languageGroup = New-Object System.Windows.Forms.GroupBox
$languageGroup.Text = 'Select Language'
$languageGroup.Location = New-Object System.Drawing.Point(20, 120)
$languageGroup.Size = New-Object System.Drawing.Size(360, 90)
$languageGroup.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#CCCCCC") # Light grey
$form.Controls.Add($languageGroup)

# ComboBox for language selection
$languageComboBox = New-Object System.Windows.Forms.ComboBox
$languageComboBox.Location = New-Object System.Drawing.Point(20, 30)
$languageComboBox.Size = New-Object System.Drawing.Size(300, 30)
$languageComboBox.Items.AddRange(@("en", "nl", "it", "fr", "es"))  # Set available languages
$languageComboBox.SelectedIndex = 0 # Set default selection to "en"
$languageComboBox.ForeColor = [System.Drawing.Color]::DarkBlue
$languageGroup.Controls.Add($languageComboBox)

# Instantiate ToolTip
$toolTip = New-Object System.Windows.Forms.ToolTip

# Set up the tooltip
$toolTip.SetToolTip($languageComboBox, 'Select your preferred language from the list.')

# Key input
$keyLabel = New-Object System.Windows.Forms.Label
$keyLabel.Text = 'Key:'
$keyLabel.Location = New-Object System.Drawing.Point(20, 270)
$keyLabel.Size = New-Object System.Drawing.Size(500,20)
$form.Controls.Add($keyLabel)
$keyLabel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#4CAF50")
$keyLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#E0E0E0")
$keyLabel.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)

$keyTextBox = New-Object System.Windows.Forms.TextBox
$keyTextBox.Location = New-Object System.Drawing.Point(20, 300)
$keyTextBox.Size = New-Object System.Drawing.Size(340, 20)
$form.Controls.Add($keyTextBox)

# Password input
$passwordLabel = New-Object System.Windows.Forms.Label
$passwordLabel.Text = 'Password:'
$passwordLabel.Location = New-Object System.Drawing.Point(20, 330)
$passwordLabel.Size = New-Object System.Drawing.Size(500,20)
$form.Controls.Add($passwordLabel)
$passwordLabel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#4CAF50")
$passwordLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#E0E0E0")
$passwordLabel.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)

$passwordTextBox = New-Object System.Windows.Forms.TextBox
$passwordTextBox.Location = New-Object System.Drawing.Point(20, 360)
$passwordTextBox.Size = New-Object System.Drawing.Size(340, 20)
$passwordTextBox.UseSystemPasswordChar = $true
$form.Controls.Add($passwordTextBox)

# Configure button
$configureButton = New-Object System.Windows.Forms.Button
$configureButton.Location = New-Object System.Drawing.Point(20, 400)
$configureButton.Size = New-Object System.Drawing.Size(100,30)
$configureButton.Text = "Configure"
$configureButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#3D5AFE")
$configureButton.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($configureButton)

# Event handler for Configure button
$configureButton.Add_Click({
    # Fetch selected values
    $theme = $themeComboBox.SelectedItem.ToLower()
    $language = $languageComboBox.SelectedItem.ToLower() # Ensure this is defined
    $serverAddress = $serverTextBox.Text
    $key = $keyTextBox.Text
    $password = $passwordTextBox.Text

    # Your existing logic for configuration can go here
    # For example:
    Set-Theme -theme $theme
    Set-Language -language $language
    Set-ServerAddress -serverAddress $serverAddress
    Set-Key -key $key
    Set-Password -password $password
    Restart-RustDesk

    [System.Windows.Forms.MessageBox]::Show("Configuration completed successfully!")
})

# Define the functions for setting the options (functions would remain the same as in your previous code)
function Set-Theme {
    param (
        [string]$theme
    )

    $configLocalPath = "C:\Users\$env:USERNAME\AppData\Roaming\RustDesk\config\RustDesk_local.toml"

    if (-Not (Test-Path $configLocalPath)) {
        New-Item -Path $configLocalPath -ItemType File -Force
    }

    $configContent = Get-Content -Path $configLocalPath -Raw

    $themeSetting = "theme = '$theme'"
    
    if ($configContent -match "theme = '.*'") {
        $configContent = $configContent -replace "theme = '.*'", $themeSetting
    } else {
        if ($configContent -match '\[options\]') {
            $configContent = $configContent -replace '\[options\]', "[options]`n$themeSetting"
        } else {
            $configContent += "`n[options]`n$themeSetting"
        }
    }

    Set-Content -Path $configLocalPath -Value $configContent
}

function Set-Language {
    param (
        [string]$language
    )
    
    $configLocalPath = "C:\Users\$env:USERNAME\AppData\Roaming\RustDesk\config\RustDesk_local.toml"

    if (-Not (Test-Path $configLocalPath)) {
        New-Item -Path $configLocalPath -ItemType File -Force
    }

    $configContent = Get-Content -Path $configLocalPath -Raw
    $languageSetting = "lang = '$language'"

    if ($configContent -match "lang = '.*'") {
        $configContent = $configContent -replace "lang = '.*'", $languageSetting
    } else {
        if ($configContent -match '\[options\]') {
            $configContent = $configContent -replace '\[options\]', "[options]`n$languageSetting"
        } else {
            $configContent += "`n[options]`n$languageSetting"
        }
    }

    Set-Content -Path $configLocalPath -Value $configContent
}

function Set-ServerAddress {
    param (
        [string]$serverAddress
    )

    # Define the locations of the RustDesk configuration files
    $configServerPath = "C:\Users\$env:USERNAME\AppData\Roaming\RustDesk\config\RustDesk2.toml"

    # Check if the server configuration file exists, create it if it doesn't
    if (-Not (Test-Path $configServerPath)) {
        New-Item -Path $configServerPath -ItemType File -Force
    }

    # Read the content of the server configuration file
    $configContent = Get-Content -Path $configServerPath -Raw

    # Define the custom-rendezvous-server setting to be added or updated
    $serverAddressSetting = "custom-rendezvous-server = '$serverAddress'"

    # Check if the custom rendezvous server setting already exists in the file
    if ($configContent -match "custom-rendezvous-server = '.*'") {
        # Replace the existing custom rendezvous server setting
        $configContent = $configContent -replace "custom-rendezvous-server = '.*'", $serverAddressSetting
    } else {
        # Add the custom rendezvous server setting under the [options] section
        if ($configContent -match '\[options\]') {
            $configContent = $configContent -replace '\[options\]', "[options]`n$serverAddressSetting"
        } else {
            # Create [options] section if it does not exist
            $configContent += "`n[options]`n$serverAddressSetting"
        }
    }

    # Save the updated content back to the server configuration file
    Set-Content -Path $configServerPath -Value $configContent
}

function Set-Key {
    param (
        [string]$key
    )

    # Define the locations of the RustDesk configuration files
    $configServerPath = "C:\Users\$env:USERNAME\AppData\Roaming\RustDesk\config\RustDesk2.toml"

    # Check if the server configuration file exists, create it if it doesn't
    if (-Not (Test-Path $configServerPath)) {
        New-Item -Path $configServerPath -ItemType File -Force
    }

    # Read the content of the server configuration file
    $configContent = Get-Content -Path $configServerPath -Raw

    # Define the key setting to be added or updated
    $keySetting = "key = '$key'"

    # Check if the key setting already exists in the file
    if ($configContent -match "key = '.*'") {
        # Replace the existing key setting
        $configContent = $configContent -replace "key = '.*'", $keySetting
    } else {
        # Add the key setting under the [options] section
        if ($configContent -match '\[options\]') {
            $configContent = $configContent -replace '\[options\]', "[key]`n$keySetting"
        } else {
            # Create [options] section if it does not exist
            $configContent += "`n[key]`n$keySetting"
        }
    }

    # Save the updated content back to the server configuration file
    Set-Content -Path $configServerPath -Value $configContent
}

function Set-Password {
    param (
        [string]$password
    )

    # Define the locations of the RustDesk configuration files
    $configPassPath = "C:\Users\$env:USERNAME\AppData\Roaming\RustDesk\config\RustDesk.toml"

    # Check if the main configuration file exists, create it if it doesn't
    if (-Not (Test-Path $configPassPath)) {
        New-Item -Path $configPassPath -ItemType File -Force
    }

    # Read the content of the RustDesk.toml configuration file
    $configContent = Get-Content -Path $configPassPath -Raw

    # Define the verification method setting
    $verificationMethodSetting = "verification-method = 'password'"
    $passwordSetting = "password = '$password'"

    # Update verification-method and password in the configuration
    if ($configContent -match "verification-method = '.*'") {
        # Replace the existing verification-method setting
        $configContent = $configContent -replace "verification-method = '.*'", $verificationMethodSetting
    } else {
        # Add verification-method under the [options] section
        if ($configContent -match '\[options\]') {
            $configContent = $configContent -replace '\[options\]', "[options]`n$verificationMethodSetting"
        } else {
            # Create [options] section if it does not exist
            $configContent += "`n[options]`n$verificationMethodSetting"
        }
    }

    if ($configContent -match "password = '.*'") {
        # Replace the existing password
        $configContent = $configContent -replace "password = '.*'", $passwordSetting
    } else {
        # Add password setting under the [options] section
        if ($configContent -match '\[options\]') {
            $configContent = $configContent -replace '\[options\]', "[options]`n$passwordSetting"
        } else {
            # Create [options] section if it does not exist
            $configContent += "`n[options]`n$passwordSetting"
        }
    }

    # Save the updated content back to the configuration file
    Set-Content -Path $configPassPath -Value $configContent
}

function Restart-RustDesk {
    # Stop the RustDesk process if it is running
    Stop-Process -Name "rustdesk" -Force -ErrorAction SilentlyContinue

    # Start the RustDesk process
    Start-Process -FilePath "C:\Program Files\RustDesk\rustdesk.exe"
}


# Theme ComboBox
$toolTip.SetToolTip($themeComboBox, "Select the visual theme for RustDesk (Light or Dark)")

# Language ComboBox
$toolTip.SetToolTip($languageComboBox, "Choose the language for the RustDesk interface")

# Server Address TextBox
$toolTip.SetToolTip($serverTextBox, "Enter the address of your RustDesk server")

# Key TextBox
$toolTip.SetToolTip($keyTextBox, "Enter your RustDesk authentication key")

# Password TextBox
$toolTip.SetToolTip($passwordTextBox, "Set a password for accessing this RustDesk client")

# Configure Button
$toolTip.SetToolTip($configureButton, "Apply the selected configuration settings")

# Download Buttons (add this inside the Create-DownloadButtons function)
function Create-DownloadButtons {
    # ... (existing code)
     # Clear existing buttons
     $buttonContainer.Controls.Clear()
    foreach ($key in $urls.Keys) {
        $button = New-Object System.Windows.Forms.Button
        # ... (existing button setup code)
        $button.Size = New-Object System.Drawing.Size(200,30)
        $button.Text = "Download $key"
        $button.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#4CAF50")
        $button.ForeColor = [System.Drawing.Color]::White
        $button.Add_Click({
            $url = $urls[$this.Text.Replace("Download ", "")]
            $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
            $saveFileDialog.FileName = $url.Split("/")[-1]
            $saveFileDialog.Filter = "All files (*.*)|*.*"
            if ($saveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                # Start download synchronously
                Download-File -Url $url -OutputPath $saveFileDialog.FileName
            }
        })
        
        # Add tooltip to each download button
        $toolTip.SetToolTip($button, "Download the $key file for RustDesk")
        
        $buttonContainer.Controls.Add($button)
    }
}

# Logo PictureBox
$toolTip.SetToolTip($logoPictureBox, "RustDesk Configuration Tool")

# Show the form
$form.ShowDialog()
