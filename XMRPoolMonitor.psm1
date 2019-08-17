function Get-MinerPoolStats
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$Worker,
		[Parameter(Mandatory = $true)]
		[string]$Wallet
	)
	$ResponseData = ''
	$PoolAPIUrl = "https://www.supportxmr.com/api/miner/$Wallet/stats/$Worker"
	Try
	{
		$ResponseData = Invoke-RESTMethod -Uri $PoolAPIUrl -TimeoutSec 10
	}
	Catch [Net.WebException]
	{
		Write-Verbose "An exception was caught connecting to pool : $($_.Exception.Message)"
	}
	
	return $ResponseData.hash
	
}
