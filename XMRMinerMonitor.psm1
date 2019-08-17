Function Get-Miners
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$File
	)
	If (Test-Path -Path $File)
	{
		$Config = Get-Content -Path $File | ConvertFrom-Json
		#$Miners = New-Object System.Collections.ArrayList
		$Miners = @{ }
		ForEach ($RecordCustomer in $Config.customers)
		{
			ForEach ($RecordMiner in $RecordCustomer.miners)
			{
				$Miner = @{ }
				$Miner.Customer = $RecordCustomer.name
				$Miner.OS = $RecordMiner.os
				$Miner.OSUser = $RecordMiner.osuser
				$Miner.OSPassword = $RecordMiner.ospassword
				$Miner.BMC = $RecordMiner.bmc
				$Miner.BMCUser = $RecordMiner.bmcuser
				$Miner.BMCPassword = $RecordMiner.bmcpassword
				$Miner.Hostname = $RecordMiner.hostname
				$Miner.APIUser = $RecordMiner.apiuser
				$Miner.APIPassword = $RecordMiner.apipassword
				$Miner.APIPort = $RecordMiner.APIPort
				$Miner.Wallet = $RecordCustomer.wallet
				$Miners.Add($($RecordMiner.macaddr -replace ':'), $Miner)
			}
		}
	}
	
	return $Miners
}
Function Restart-OS
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$Hostname,
		[Parameter(Mandatory = $true)]
		[string]$Username,
		[Parameter(Mandatory = $true)]
		[string]$Password,
		[Parameter(Mandatory = $true)]
		[string]$OS
	)
	
	$PasswordSecure = ConvertTo-SecureString -AsPlainText -String $Password -Force
	$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $PasswordSecure
	$Result = ''
	If ($OS -eq 'linux')
	{
		$o = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
		Invoke-Command -ComputerName $Hostname -Credential $cred -UseSSL -Authentication Basic -SessionOption $o -ScriptBlock {
			Invoke-Expression -Command '/sbin/shutdown -t +1 -r'
		} -ErrorAction SilentlyContinue -ErrorVariable err
		
		switch ($err[0].Exception.GetType().FullName)
		{
			'System.Management.Automation.Remoting.PSRemotingTransportException' { return 'Failed' }
			'System.Management.Automation.RemoteException' {
				If ($err[0].Exception.ErrorRecord -like 'Shutdown scheduled*')
				{
					$result = 'Scheduled'
				}
				Else
				{
					$result = $err[0].Exception.ErrorRecord
				}
			}
			default { $result = 'Unknown' }
		}
	}
	ElseIf ($OS -eq 'windows')
	{
		Try
		{
			$Session = New-PSSession -ComputerName $Hostname -Credential $Cred -ErrorAction Stop
		}
		Catch
		{
			Write-Error "Unable to connect to $Hostname"
			$result = 'Failed'
		}
		Finally
		{
			If ($Session)
			{
				$result = Invoke-Command -Session $Session -ScriptBlock {
					Restart-Computer -Force
				}
			}
		}
	}
	Else
	{
		$Result = 'Unknown OS Type'
	}
	
	return $Result
}
