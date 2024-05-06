# Static variable for directory
$StaticDirectory = "changeme"

# Text prompt for directory
$PromptDirectory = Read-Host "Enter the directory path"

# Boolean variable to switch between static and prompt directory
$UseStaticDirectory = $false

# Banner
Write-Host @"
**********************************************************************
*                         _____                                  __   *
*                        |  _  |                                /  |  *
* _ __  ___   ___  _   _ | | | |__      __ _ __      _ __   ___  | |  *
*| '__|/ _ \ / __|| | | || | | |\ \ /\ / /| '_ \    | '_ \ / __| | |  *
*| |  |  __/| (__ | |_| |\ \_/ / \ V  V / | | | | _ | |_) |\__ \_| |_ *
*|_|   \___| \___| \__,_| \___/   \_/\_/  |_| |_|(_)| .__/ |___/\___/ *
*                                                   | |               *
*                                                   |_|               *
***********************************************************************
"@ -ForegroundColor Green

# Function to recursively change ownership of files
function Set-FileOwner {
    param(
        [string]$Path,
        [string]$User
    )

    $Files = Get-ChildItem -Path $Path -Recurse -File -Include *.ps1, *.vbs, *.cmd
    foreach ($File in $Files) {
        try {
            $acl = Get-Acl $File.FullName
            $acl.SetOwner([System.Security.Principal.NTAccount]$User)
            Set-Acl $File.FullName $acl
            Write-Host "Changed ownership of $($File.FullName) to $User" -ForegroundColor Cyan
        } catch {
            Write-Host "Failed to change ownership of $($File.FullName)" -ForegroundColor Red
        }
    }
}

# Function to recursively unblock files
function Unblock-Files {
    param(
        [string]$Path
    )

    $Files = Get-ChildItem -Path $Path -Recurse -File -Include *.ps1, *.vbs, *.cmd
    foreach ($File in $Files) {
        try {
            Unblock-File -Path $File.FullName -Confirm:$false
            Write-Host "Unblocked $($File.FullName)" -ForegroundColor Cyan
        } catch {
            Write-Host "Failed to unblock $($File.FullName)" -ForegroundColor Red
        }
    }
}

# Function to recursively approve files
function Approve-Files {
    param(
        [string]$Path
    )

    $Files = Get-ChildItem -Path $Path -Recurse -File -Include *.ps1, *.vbs, *.cmd
    foreach ($File in $Files) {
        try {
            # Verify if a code signing certificate exists for the current user
            $cert = Get-ChildItem -Path Cert:\LocalMachine\My -CodeSigningCert | Where-Object {$_.Subject -eq "CN=$Username-CodeSigningCert"}
            if ($cert) {
                # Sign the script with the current user's certificate
                Set-AuthenticodeSignature -FilePath $File.FullName -Certificate $cert -IncludeChain 'All' -TimestampServer 'http://timestamp.digicert.com'
                Write-Host "Signed $($File.FullName)" -ForegroundColor Cyan
            } else {
                Write-Host "No code signing certificate found for the current user." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Failed to sign $($File.FullName)" -ForegroundColor Red
        }
    }
}

# Decide which directory to use
if ($UseStaticDirectory) {
    $Directory = $StaticDirectory
} else {
    $Directory = $PromptDirectory
}

# Get the current logged-in user
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
# Extract only the username without the domain prefix
$Username = $CurrentUser.Split("\")[1]

# Call the functions to set ownership, unblock, and sign scripts
Set-FileOwner -Path "$Directory" -User $Username
Unblock-Files -Path "$Directory"
Sign-Files -Path "$Directory"
