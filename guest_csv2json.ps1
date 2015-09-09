#Progress bar variables
[int]$i=1
[int]$p = 1
$elapsed = [System.Diagnostics.Stopwatch]::StartNew()


#Path variables
$source = "E:\Flat File\"
#$source = "C:\Users\Kamil\OneDrive\JetStar\Flat_FIle_Source\Guest\"

$target = "E:\data\outbound\boxever\"
#$target = "C:\Users\Kamil\OneDrive\JetStar\Flat_FIle_Source\Guest\"

$guest = Import-csv ($source + "Guest.csv")
if($guest.Count -eq 0){
    Write-Host "No records found"
    exit 0
    }
$LoadRunID = $guest[1].LoadRunID
#$subscription = Import-csv ($source + "GuestSubscriptions.csv")
$Identifier = Import-csv ($source + "GuestIdentifiers.csv")
$extension = Import-csv ($source + "GuestExtensions.csv")   

foreach ($scvid in $guest){

	#Add phoneNumber fields on Guest 
	$scvid | Add-Member -MemberType NoteProperty -Name phoneNumbers -Value (New-object 	System.Collections.Arraylist)
	if(-Not [string]::IsNullOrEmpty($scvid.PhoneNumber1)){
		$scvid.phoneNumbers.add($scvid.PhoneNumber1)
	}
	if(-Not [string]::IsNullOrEmpty($scvid.PhoneNumber2)){
		$scvid.phoneNumbers.add($scvid.PhoneNumber2)
	}
	if(-Not [string]::IsNullOrEmpty($scvid.PhoneNumber3)){
		$scvid.phoneNumbers.add($scvid.PhoneNumber3)
	}
	if(-Not [string]::IsNullOrEmpty($scvid.PhoneNumber4)){
		$scvid.phoneNumbers.add($scvid.PhoneNumber4)
	}


	#Add Street fields on Guest 

	$scvid | Add-Member -MemberType NoteProperty -Name street -Value (New-object System.Collections.Arraylist)
	if(-Not [string]::IsNullOrEmpty($scvid.AddressLine1)){
		$scvid.street.add(($scvid.AddressLine1 -replace ' ', '*'))
	}
	if(-Not [string]::IsNullOrEmpty($scvid.AddressLine2)){
		$scvid.street.add(($scvid.AddressLine2 -replace ' ', '*'))
	}
	if(-Not [string]::IsNullOrEmpty($scvid.AddressLine3)){
		$scvid.street.add(($scvid.AddressLine3 -replace ' ', '*'))
	}
	
	#remove extra street fields
	$scvid.PSObject.Properties.Remove('AddressLine1')
	$scvid.PSObject.Properties.Remove('AddressLine2')
	$scvid.PSObject.Properties.Remove('AddressLine3')

	#remove extra phone number fields
	$scvid.PSObject.Properties.Remove('PhoneNumber1')
	$scvid.PSObject.Properties.Remove('PhoneNumber2')
	$scvid.PSObject.Properties.Remove('PhoneNumber3')
	$scvid.PSObject.Properties.Remove('PhoneNumber4')

    #remove LoadRunID
    $scvid.PSObject.Properties.Remove('LoadRunID')

	#Adding subscriptions to guest
    <#
	$scvid | Add-Member -MemberType NoteProperty -Name subscriptions -Value (New-object System.Collections.Arraylist)
    
	foreach ($subscription in $subscription){

		if($scvid.GuestUUID -eq $subscription.GuestUUID){
			
			$subscription.PSObject.Properties.Remove('GuestUUID')	
			$scvid.subscriptions.add($GUID)
		}
	}
    #>
	#Adding Identifiers to guest
	$scvid | Add-Member -MemberType NoteProperty -Name identifiers -Value (New-object System.Collections.Arraylist)

	foreach ($GUID in $Identifier){

		if($scvid.GuestUUID -eq $GUID.GuestUUID){

			$GUID.PSObject.Properties.Remove('GuestUUID')			
			$scvid.identifiers.add($GUID)
		}
	}

	#add extensions
	$scvid | Add-Member -MemberType NoteProperty -Name extensions -Value (New-object System.Collections.Arraylist)

	foreach ($GUID in $extension){

		if($scvid.GuestUUID -eq $GUID.GuestUUID){
			
			$GUID.PSObject.Properties.Remove('GuestUUID')
			$scvid.extensions.add($GUID)
		}
	}
    $p = $i/$guest.count*100
	write-progress -activity "1 of 2 Generating Guest records" -status "$p% Complete:" -percentcomplete $p;
    $i++
}

#free up memory
#$subscription = $null
$Identifier = $null
$extension = $null
[System.GC]::Collect()


$outer = Import-csv ($source + "GuestOuter.csv")
$i=1
foreach($outervalue in $outer){
	foreach($scvid in $guest){
		if($scvid.GuestUUID -eq $outervalue.GuestUUID){
			$scvid.PSObject.Properties.Remove('GuestUUID')

			$outervalue | Add-Member -MemberType NoteProperty -Name value -Value $scvid
			}
	}
	$outervalue.PSObject.Properties.Remove('GuestUUID')

    $p = $i/$outer.count*100
	write-progress -activity "2 of 2 Populating outer records" -status "$p% Complete:" -percentcomplete $p;
    $i++ 
}


#write guest to json file
$destinationFile = $source + "guest.json"
$outer | ConvertTo-Json -Depth 10 | Out-file $destinationFile
$outer = $null
[System.GC]::Collect()

$content = [System.IO.File]::ReadAllText($destinationFile);

$expr1 = '\n+|\t+|\s+|\r+';
$expr2 = '\"\w+\":\[?null\]?,?|\"\w+\":"",?|\"\w+\":\[\],?|(,|;)\w+((\.|\_)\w+)?@\w+.\w+((\.|\_)\w+)?';
$expr3 = ',}';
$expr4 = '\*';
$expr5 = '}},{"ref"';
$expr6 = '(?<!.)^.|.$(?!.)'


$firstResult = [System.Text.RegularExpressions.Regex]::Replace($content, $expr1, '');
$secondResult = [System.Text.RegularExpressions.Regex]::Replace($firstResult, $expr2, '');
$thirdResult = [System.Text.RegularExpressions.Regex]::Replace($secondResult, $expr3, '}');
$fourthResult= [System.Text.RegularExpressions.Regex]::Replace($thirdResult, $expr4, ' ');
$fifthResult = [System.Text.RegularExpressions.Regex]::Replace($fourthResult, $expr5, '}}'+"`n"+'{"ref"');
$sixthResult= [System.Text.RegularExpressions.Regex]::Replace($fifthResult, $expr6, '');

#$timestamp = Get-Date -Format "yyyy_M_dd_Hmmss"
$file = $target + "guest_final_" + $LoadRunID + ".json"

[System.IO.File]::WriteAllText($file, $sixthResult );
write-host "Writting to " $file
#$sixthResult | Set-Content -Path $file -Encoding UTF8


#compressing to gzip

$input = New-Object System.IO.FileStream $file, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read);
$output = New-Object System.IO.FileStream ($file+".gz"), ([IO.FileMode]::Create), ([IO.FileAccess]::Write), ([IO.FileShare]::None)
$gzipStream = New-Object System.IO.Compression.GzipStream $output, ([IO.Compression.CompressionMode]::Compress)

try
{
    $buffer = New-Object byte[](1024);

    while($true)
    {
        $read = $input.Read($buffer, 0, 1024)

        if ($read -le 0)
        {
            break;
        }

        $gzipStream.Write($buffer, 0, $read)
     }
}
finally
{
    $gzipStream.Close();
    $output.Close();
    $input.Close();
}
Remove-Item $file
write-host "Ended at $(get-date)"
write-host "Total Elapsed Time: $($elapsed.Elapsed.ToString())"