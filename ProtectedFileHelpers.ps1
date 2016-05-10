function New-ProtectedFile {
 Param(
  [Parameter(Mandatory = $true)]
  [System.IO.FileInfo]
  $Path,
  [SecureString]
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
   $ConvertFromSecStrParams.Add('Key',(Get-SHA256HashFromSecureString -secureString $MasterPassword))
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

Function Get-SHA256HashFromSecureString {
 [cmdletBinding()]
 [outputType([string])]
 Param(
  [secureString]
  $secureString
 )
 $seed = '400d7ecf-c6fe-49a9-ab62-3861bb5fc885' #if you change this,
 # you won't be able to read previously encrypted keys
 $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
 $clearTextString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
 $asciiBytes = [Text.Encoding]::ASCII.GetBytes($seed)
 $SHA256 =  [System.Security.Cryptography.HMACSHA256]::new($asciiBytes)
 return $SHA256.ComputeHash([text.encoding]::ASCII.GetBytes($clearTextString));
}

function Get-ProtectedFileContent {
 Param(
  [Parameter(Mandatory = $true)]
  [System.IO.FileInfo]
  $Path,
  [Parameter(Mandatory= $false)]
  [securestring]
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
   $null = $ToSecureStringParams.Add('Key',(Get-SHA256HashFromSecureString -secureString $MasterPassword))
  }
  $FileAsSecureString =  ConvertTo-SecureString @ToSecureStringParams
  $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($FileAsSecureString)
  $PlainFileContent = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
  
  Return $PlainFileContent
 }
 
 
}