function New-ProtectedFile {
    Param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]
        $Path,
        [PSCredential]
        $MasterPassword,
        #[bytes[]] #On a different ParameterSet
        #MasterKey,
        [Parameter(Mandatory = $true)]
        [string]
        $content
    )
 
    $ConvertFromSecStrParams = @{
        'SecureString' = (ConvertTo-SecureString -String $content  -AsPlainText -Force)
    }
    if($MasterPassword) { #define the key (creating a SHA256 hash of the text)
        $ConvertFromSecStrParams.Add('Key',(Get-SHA256HashFromCredential -Credential $MasterPassword))
    }
    #if  no key is specified, the Windows Data Protection API (DPAPI) 
    #  is used to encrypt the standard string representation. 
    # help ConvertFrom-SecureString
    $EncryptedString = ConvertFrom-SecureString @ConvertFromSecStrParams


    if ($Path.Exists)
    {
        Write-Verbose -Message "Overwritting file $Path."
    }
  
    New-Item -ItemType File -Path $path.Directory -Name $path.Name -Force -Value $EncryptedString

}

Function Get-SHA256HashFromCredential {
    [cmdletBinding()]
    [outputType([string])]
    Param(
        [PSCredential]
        $Credential
    )
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)
    $clearTextString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    $asciiBytes = [Text.Encoding]::ASCII.GetBytes($Credential.UserName)
    $SHA256 =  [System.Security.Cryptography.HMACSHA256]::new($asciiBytes)
    return $SHA256.ComputeHash([text.encoding]::ASCII.GetBytes($clearTextString));
}

function Get-ProtectedFileContent {
    Param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]
        $Path,
        [Parameter(Mandatory= $false)]
        [PSCredential]
        $MasterPassword
    )
 
    if(-not $path.Exists) {
        Throw [System.IO.FileNotFoundException]::new("The file $($Path.FullName) was not found.")
    }
    else {
        $ToSecureStringParams = @{
            'string' = (Get-Content -Raw $path)
        }
        if($MasterPassword) {
            $null = $ToSecureStringParams.Add('Key',(Get-SHA256HashFromCredential -Credential $MasterPassword))
        }
        $FileAsSecureString =  ConvertTo-SecureString @ToSecureStringParams
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($FileAsSecureString)
        $PlainFileContent = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
  
        Return $PlainFileContent
    }
 
 
}