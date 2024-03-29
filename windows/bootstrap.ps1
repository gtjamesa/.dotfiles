 ##Requires -RunAsAdministrator

 $DOTFILES_PATH = "$env:USERPROFILE\.dotfiles"

Function Install-Deps {
    # Install Chocolatey
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    # Install git
    choco install -y git

    Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1
    refreshenv
}

Function Clone-Repo {
    $GIT = 'C:\Program Files\Git\bin\git.exe'

    if (-not (Test-Path -Path "$DOTFILES_PATH")) {
        & $GIT clone https://github.com/gtjamesa/.dotfiles.git $DOTFILES_PATH
    } else {
        cd $DOTFILES_PATH
        & $GIT fetch origin
        & $GIT pull
    }
}

Install-Deps
Clone-Repo
. "$DOTFILES_PATH\windows\installscript.ps1"
