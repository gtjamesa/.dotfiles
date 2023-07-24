#Requires -RunAsAdministrator

$INSTALL_EXTRAS = $false

Function Prompt-For-Confirmation {
    param(
        [string]$title = 'Confirm',
        [string]$message = 'Are you sure you want to proceed?'
    )

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes', 'Proceed with the installation'
    $no = New-Object System.Management.Automation.Host.ChoiceDescription '&No', 'Cancel the installation'

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    $decision = $Host.UI.PromptForChoice($title, $message, $options, 1)

    if ($decision -eq 0) {
        return $true
    } else {
        return $false
    }
}

Function Install-Packages {
    choco install -y `
        7zip 7zip-zstd `
        adobereader obsidian typora `
        powertoys cpu-z ueli rufus sharex whatsapp 1password wireguard openvpn wiztree f.lux.install `
        jetbrainstoolbox anydesk.install P4Merge `
        spotify discord grammarly-for-windows googledrive googlechrome `
        vlc

    # Firefox Developer Edition
    choco install -y firefox-dev --pre
}

Function Install-Extra-Packages {
    choco install -y `
        figma steam `
        burp-suite-free-edition mullvad-app processhacker.install tightvnc wireshark
}

echo ""
echo ""
echo ""
echo "All general usage programs will be installed by default"
echo "Additional programs such as Steam, Figma, etc. will be installed if you choose to install extras"

if (Prompt-For-Confirmation('Extras', 'Do you want to install extra packages?')) {
    $INSTALL_EXTRAS = $true
}

Install-Packages

if ($INSTALL_EXTRAS) {
    Install-Extra-Packages
}
