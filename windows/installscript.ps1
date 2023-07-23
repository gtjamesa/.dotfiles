 #Requires -RunAsAdministrator
 
 Function Install-Packages {
  choco install -y `
  7zip 7zip-zstd `
  adobereader obsidian typora `
  powertoys cpu-z ueli rufus sharex 1password `
  jetbrainstoolbox anydesk.install P4Merge `
  spotify discord grammarly-for-windows googledrive `
  vlc

  # Firefox Developer Edition
  choco install -y firefox-dev --pre
}

Install-Packages