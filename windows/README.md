# Windows Configuration

These PowerShell scripts will install [Chocolatey](https://chocolatey.org/install) and then use it to install some default programs.

To install, simply run the following command from an **elevated PowerShell prompt**. It will clone this repository into `C:\Users\<USER>\.dotfiles`, and run the `bootstrap.ps1` script automatically.

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force; IEX(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/gtjamesa/.dotfiles/main/windows/bootstrap.ps1')
```
