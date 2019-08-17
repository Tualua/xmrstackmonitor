Function Get-MinerHardwareInfo
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$Hostname,
		[Parameter(Mandatory = $true)]
		[string]$OSUser,
		[Parameter(Mandatory = $true)]
		[string]$OSPassword,
		[Parameter(Mandatory = $true)]
		[string]$OS
	)
	$GPUStatus = @{ }
	$PasswordSecure = ConvertTo-SecureString -AsPlainText -String $OSPassword -Force
	$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $OSUser, $PasswordSecure
	If ($OS -eq 'windows')
	{
		$PSSession = New-PSSession -ComputerName $Hostname -Credential $Cred
		$GPUInfo = Invoke-Command -Session $PSSession -ScriptBlock { Get-WmiObject Win32_VideoController }
		If ($GPUInfo)
		{
			$GPUStatus.GPUPresent = $true
			$GPUStatus.GPUName = $GPUInfo.Name
			$GPUStatus.GPUStatus = $GPUInfo.Status
		}
		Else
		{
			$GPUStatus.GPUPresent = $false
			$GPUStatus.GPUName = 'None'
			$GPUStatus.GPUStatus = 'None'
		}
	}
	ElseIf ($OS -eq 'linux')
	{
		$PasswordSecure = ConvertTo-SecureString -AsPlainText -String $OSPassword -Force
		$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $OSUser, $PasswordSecure
		$o = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
		$Result = Invoke-Command -ComputerName $Hostname -Credential $cred -UseSSL -Authentication Basic -SessionOption $o -ScriptBlock {
			Invoke-Expression -Command 'lshw -class display|grep product'
			
		} -ErrorAction SilentlyContinue -ErrorVariable err
		
		If ($Result)
		{
			$GPUStatus.GPUPresent = $true
			$GPUStatus.GPUName = $($Result.Split(':'))[1].Trim()
			$GPUStatus.GPUStatus = 'N/A'
		}
		Else
		{
			$GPUStatus.GPUPresent = $false
			$GPUStatus.GPUName = 'None'
			$GPUStatus.GPUStatus = 'None'
		}
	}
	Else
	{
		$GPUStatus.GPUPresent = $false
		$GPUStatus.GPUName = 'Unable to detect'
		$GPUStatus.GPUStatus = 'Unsupported OS'
	}
	Return $GPUStatus
}
function Get-DCMIPowerReading
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$BMC,
		[Parameter(Mandatory = $true)]
		[string]$BMCUser,
		[Parameter(Mandatory = $true)]
		[string]$BMCPassword
	)
	$ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
	$ProcessInfo.FileName = "$PSSCriptRoot\lib\ipmitool.exe"
	$ProcessInfo.RedirectStandardError = $true
	$ProcessInfo.RedirectStandardOutput = $true
	$ProcessInfo.UseShellExecute = $false
	$ProcessInfo.Arguments = "-H $BMC -U $BMCUser -P $BMCPassword -I lanplus dcmi power reading"
	$Process = New-Object System.Diagnostics.Process
	$Process.StartInfo = $ProcessInfo
	$Process.Start() | Out-Null
	$Process.WaitForExit()
	$PowerData = @{ }
	$Line = $Process.StandardOutput.ReadLine()
	Do
	{
		$Line = $Process.StandardOutput.ReadLine()
		If (($Line) -and (($Line.IndexOf(':') -ge 1)))
		{
			$PowerData.Add($($Line.Substring(0, $Line.IndexOf(':'))).Trim(), $Line.Substring($Line.IndexOf(':') + 1, $Line.Length - $Line.IndexOf(':') - 1).Trim())
			
		}
		
	}
	While ($Line -ne $null)
	$PowerInfo = @{ }
	$PowerInfo.Add('PowerAvg', [int]$PowerData['Average power reading over sample period'].Substring(0, $PowerData['Average power reading over sample period'].IndexOf(' ')))
	$PowerInfo.Add('PowerCurrent', [int]$PowerData['Instantaneous power reading'].Substring(0, $PowerData['Instantaneous power reading'].IndexOf(' ')))
	Return $PowerInfo
}
