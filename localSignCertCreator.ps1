# Get the current logged-in user
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# Extract only the username without the domain prefix
$Username = $CurrentUser.Split("\")[1]

# Parameters
$CertSubject = "$Username-CodeSigningCert"
$CertFriendlyName = "$Username-CodeSigningCert"
$CertificatesDir = "$env:USERPROFILE\Certificates"
$ExportPath = "$CertificatesDir\$Username-CodeSigningCert.pfx"

# Check if the directory exists, and create it if it doesn't
if (-not (Test-Path $CertificatesDir)) {
    $null = New-Item -Path $CertificatesDir -ItemType Directory
    if (-not (Test-Path $CertificatesDir)) {
        Write-Host "Error: Failed to create directory $CertificatesDir"
        exit
    }
}

# Prompt for password
$Password = Read-Host -Prompt "Enter password for the exported certificate" -AsSecureString

# Create self-signed certificate
$Cert = New-SelfSignedCertificate -Subject $CertSubject -FriendlyName $CertFriendlyName -Type CodeSigningCert -CertStoreLocation Cert:\CurrentUser\My -KeyUsage DigitalSignature

# Export the certificate to a .pfx file
Export-PfxCertificate -Cert $Cert -FilePath $ExportPath -Password $Password

Write-Host "Self-signed certificate created and exported to $ExportPath"

# Add the self-signed Authenticode certificate to the computer's root certificate store.
$rootStore = [System.Security.Cryptography.X509Certificates.X509Store]::new("Root","LocalMachine")
$rootStore.Open("ReadWrite")
$rootStore.Add($Cert)
$rootStore.Close()

Write-Host "Certificate added to computer's root certificate store."

# Add the self-signed Authenticode certificate to the computer's TrustedPublisher certificate store.
$publisherStore = [System.Security.Cryptography.X509Certificates.X509Store]::new("TrustedPublisher","LocalMachine")
$publisherStore.Open("ReadWrite")
$publisherStore.Add($Cert)
$publisherStore.Close()

Write-Host "Certificate added to computer's TrustedPublisher certificate store."

# Add the self-signed Authenticode certificate to the computer's Personal certificate store.
$myStore = [System.Security.Cryptography.X509Certificates.X509Store]::new("My","LocalMachine")
$myStore.Open("ReadWrite")
$myStore.Add($Cert)
$myStore.Close()

Write-Host "Certificate added to computer's Personal certificate store."
