function ConvertFrom-GzipData {
	[cmdletBinding()]
	param(
		[parameter(Mandatory = $true, ValueFromPipeline = $false)]
		[byte[]]
		$Bytes 
	)
	process {
		$gzipStream = [System.IO.Compression.GZipStream]::new(
			[System.IO.MemoryStream]::new($Bytes)
			,[IO.Compression.CompressionMode]::Decompress
		)
	
			$output = [byte[]]@()
				while($true) {
								$buffer =  New-Object Byte[] 512
								$read = $gzipStream.Read($buffer, 0, 512)
								if ($read -lt 1){
									break
								}
								Else {
									$output += $buffer[0..($read - 1)]								
								}
				}
				Write-Output $output
	}
}


function Convert-GzipToUTF8 {
	[cmdletBinding()]
	param(
		[parameter(Mandatory = $true, ValueFromPipeline = $false)]
		[byte[]]
		$GzipData
	)
	process {
		$Bytes = ConvertFrom-GzipData -Bytes $GzipData
		write-output ([System.Text.Encoding]::UTF8.GetString($Bytes))
	}
}

function ConvertTo-GzipData {
	[cmdletBinding()]
	param(
		[parameter(Mandatory = $true, ValueFromPipeline = $false)]
		[byte[]]
		$Data
	)
	
	Process {
		$output = [System.IO.MemoryStream]::new()
		$gzipStream = New-Object System.IO.Compression.GzipStream $output, ([IO.Compression.CompressionMode]::Compress)
		
			$gzipStream.Write($Data, 0, $Data.Length)
			$gzipStream.Close()
		Write-Output $output.ToArray();
	}
	
}

function Convert-StringToBase64GzipData {
	[cmdletBinding()]
	Param(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[string]
		$String
	)
	Process {
		ConvertTo-GzipData -Data	([System.Convert]::ToBase64String($string.ToCharArray())).ToCharArray()
	}

}


function Convert-Base64GzipDataToString {
	[cmdletBinding()]
	Param(
		[parameter(Mandatory = $true, ValueFromPipeline = $false)]
		[byte[]]
		$Base64GzippedData
	)
	
	process {
		write-output (			
					[System.Text.Encoding]::UTF8.GetString( [System.Convert]::FromBase64String((Convert-GzipToUTF8 -GzipData $Base64GzippedData))))
	}
}


#test : Convert-Base64GzipDataToString -base64GzippedData (Convert-StringToBase64GzipData -string 'Hello World')