#region Receive Module Parameter
function Receive-ModuleParameter
{
	param(
		$ModuleParams = $script:ModuleParams
	)
	if ($ModuleParams.count -eq 0 )
	{
		#No Params, look for File Config based on $PSRoot and fileName
		$callStack = Get-PSCallstack
		$callerFile = $callStack[$callstack.count -1].ScriptName
  if($callerFile -and 
   (
    ($CallerFileName = resolve-path "$callerFile.config" -ea SilentlyContinue) -or
    ($CallerFileName = resolve-path "$callerFile.xml" -ea SilentlyContinue) -or
    ($CallerFileName = resolve-path "$callerFile.config.xml" -ea SilentlyContinue) -or
    ($CallerFileName = resolve-path "$callerFile.config.json" -ea SilentlyContinue) -or
    ($CallerFileName = resolve-path "$callerFile.json" -ea SilentlyContinue)
   )
  ) {
   $script:configFile =  $CallerFileName.Path
  }
  else {
   Write-Verbose 'No configuration file found, and No arguments sent. Loading hardcoded defaults'
   $script:configFile = $null
  }
		
	}
	elseif($ModuleParams.count -eq 1) {
		#Only One argument, check if it's an HashTable
		if($ModuleParams[0] -as [hashtable]) {
			#It's an hashtable, extract valid params for splatting to the Set-<moduleName>ModuleConfig function
			$ModuleName = $MyInvocation.MyCommand.ModuleName
			$ConfigCommand = Get-Command 'Set-ModuleConfig'
			
			$script:ParamsForSetModuleConfig = @{}
			foreach($ModuleParamKey in $ModuleParams.keys) { #extract allowed parameters from Module Arguments
				if($ModuleParamKey -in $ConfigCommand.Parameters.Keys) {
					$script:ParamsForSetModuleConfig.add($ModuleParamKey,$ModuleParams.($ModuleParamKey))
				}
				else {
					Write-Warning -Message "Parameter $param was found but not allowed for Set-$($moduleName)ModuleConfig"
				}
			}
			#call to config need to happen at the end of the psm1 file so that all functions are defined
		}
		else { #Only one argument but not a Hashtable, maybe it's a configuration file.
			if($ModuleParams[0]-ne $null -and
				$ModuleParams[0] -ne [string]::Empty -and
				($configFileName = Resolve-Path $ModuleParams[0])
			){
				$script:configFile = $configFileName.Path
			}
		}
	}
}

#endregion