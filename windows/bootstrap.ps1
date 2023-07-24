 ##Requires -RunAsAdministrator

 $DOTFILES_PATH = "$env:USERPROFILE\.dotfiles"

Function Install-Deps {
    # Install Chocolatey
    Set-ExecutionPolicy AllSigned -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    # Install git
    choco install -y git
}

Function Clone-Repo {
    if (-not (Test-Path -Path "$DOTFILES_PATH")) {
      echo "git clone https://github.com/gtjamesa/.dotfiles.git $DOTFILES_PATH"
    } else {
       cd $DOTFILES_PATH
       git fetch origin
       git pull
    }
}

Install-Deps
Clone-Repo
. "$DOTFILES_PATH\windows\installscript.ps1"
