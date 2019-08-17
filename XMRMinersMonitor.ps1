Function Get-MinerDataAll
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$Hostname,
		[Parameter(Mandatory = $true)]
		[string]$OS,
		[Parameter(Mandatory = $true)]
		[string]$OSUsername,
		[Parameter(Mandatory = $true)]
		[string]$OSPassword,
		[Parameter(Mandatory = $true)]
		[string]$APIUser,
		[Parameter(Mandatory = $true)]
		[string]$APIPassword,
		[Parameter(Mandatory = $true)]
		[string]$APIPort,
		[Parameter(Mandatory = $true)]
		[string]$Worker,
		[Parameter(Mandatory = $true)]
		[string]$BMC,
		[Parameter(Mandatory = $true)]
		[string]$BMCUser,
		[Parameter(Mandatory = $true)]
		[string]$BMCPassword,
		[Parameter(Mandatory = $true)]
		[string]$Wallet
	)
	$MinerInfo = @{ }
	
	$LocalHashrate = Get-XMRStakStats -Hostname $Hostname -APIUser $APIUser -APIPassword $APIPassword -APIPort $APIPort
	$MinerInfo += $LocalHashrate
	
	$MinerInfo.PoolHashrate = Get-MinerPoolStats -Worker $Worker -Wallet $Wallet
	If ($MinerInfo.PoolHashrate -eq 0)
	{
		$MinerInfo.PoolStatus = 'Missing'
	}
	Else
	{
		$MinerInfo.PoolStatus = 'OK'
	}
	
	$MinerHWInfo = Get-MinerHardwareInfo -Hostname $Hostname -OSUser $OSUsername -OSPassword $OSPassword -OS $OS
	$MinerInfo += $MinerHWInfo
	
	$MinerPowerInfo = Get-PowerReadingDCMI -BMC $BMC -BMCUser $BMCUser -BMCPassword $BMCPassword
	$MinerInfo += $MinerPowerInfo
	Return $MinerInfo
}
