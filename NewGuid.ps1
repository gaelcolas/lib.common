
#region NEw-Guid for old version of PS
if(-not (Get-Command -Name New-GUID -ErrorAction SilentlyContinue)) {
	function New-Guid {
		[guid]::NewGuid()
	}
}
#endregion

