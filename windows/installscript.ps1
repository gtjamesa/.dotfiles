 #Requires -RunAsAdministrator
 
 Function Install-Packages {
  choco install -y `
  7zip 7zip-std `
  obsidian `
  P4Merge `
  powertoys `
  ueli `
  vlc

  # Firefox Developer Edition
  choco install -y firefox-dev --pre
}

Install-Packages