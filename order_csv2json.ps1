
#declare variables to measure progress
$i=1
[int]$p = 1
$elapsed = [System.Diagnostics.Stopwatch]::StartNew()

#paths
$sourceFolder = "E:\Flat File\"
$destinationFolder = "E:\data\outbound\boxever\"

#check if there is data in Orders
$source = $sourceFolder + "order.csv"
$orders = Import-csv $source

if($orders.Count -eq 0){
    Write-Host "No records found"
    exit 0
}


#Create phoneNumber, address fields on Contact and clean empty fields
$source = $sourceFolder + "OrderContact.csv"
$orderContacts = Import-csv $source


$source = $sourceFolder + "OrderPersonIdentifier.csv"
$identifiers  = Import-csv $source



foreach ($contact in $orderContacts){

	$contact | Add-Member -MemberType NoteProperty -Name phoneNumbers -Value (New-object System.Collections.Arraylist)
    $contact | Add-Member -MemberType NoteProperty -Name street -Value (New-object System.Collections.Arraylist)
    $contact | Add-Member -MemberType NoteProperty -Name identifiers -Value (New-object System.Collections.Arraylist)

	if(-Not [string]::IsNullOrEmpty($contact.HomePhone)){
		$contact.phoneNumbers.add($contact.HomePhone)
	}
	if(-Not [string]::IsNullOrEmpty($contact.WorkPhone)){
		$contact.phoneNumbers.add($contact.WorkPhone)
	}
	if(-Not [string]::IsNullOrEmpty($contact.OtherPhone)){
		$contact.phoneNumbers.add($contact.OtherPhone)
	}
    if(-Not [string]::IsNullOrEmpty($contact.AddressLine1)){
		$contact.street.add(($contact.AddressLine1 -replace ' ', '*'))
	}
	if(-Not [string]::IsNullOrEmpty($contact.AddressLine2)){
		$contact.street.add(($contact.AddressLine2 -replace ' ', '*'))
	}
	if(-Not [string]::IsNullOrEmpty($contact.AddressLine3)){
		$contact.street.add(($contact.AddressLine3 -replace ' ', '*'))
	}
    #adding identifiers
    foreach($identifier in $identifiers){
        if($contact.BookingId -eq $identifier.BookingID){
            $identifier.PSObject.Properties.Remove('BookingId')
            $identifier.PSObject.Properties.Remove('PassengerID')
            $contact.identifiers.add($identifier)
        }
    }
	#remove no longer required fields containing phone numbers and addresses
	$contact.PSObject.Properties.Remove('HomePhone')
	$contact.PSObject.Properties.Remove('WorkPhone')
	$contact.PSObject.Properties.Remove('OtherPhone')
    $contact.PSObject.Properties.Remove('AddressLine1')
    $contact.PSObject.Properties.Remove('AddressLine2')
    $contact.PSObject.Properties.Remove('AddressLine3')
    $contact.PSObject.Properties.Remove('AddressLine3')
    
    
	
	$i ++
	$p = $i/$orderContacts.count*100
	write-progress -activity "1 of 7 Creating phone number and street fields on Contacts and adding Identifiers" -status "$p% Complete:" -percentcomplete $p;
}
$identifiers = $null
[System.GC]::Collect()
$i=1

#Adding contacts to orders


$LoadRunID = $orders[1].LoadRunID
$contacts = New-object System.Collections.ArrayList
$delContacts = New-object System.Collections.ArrayList
foreach ($c in $orderContacts){
	$contacts.Add($c)
}
$orderContacts=$null

foreach ($order in $orders){
	
	#add contact to each order

	 foreach($contact in $contacts){

		if($contact.BookingId -eq $order.BookingID){
			$contact.PSObject.Properties.Remove('BookingId')
			$order | Add-Member -MemberType NoteProperty -Name contact -Value $contact
			$delContacts.add($contact)
			
			}
		}

		foreach($c in $delContacts){
			$contacts.Remove($c)
		}
		
		$delContacts.Clear()
	
	$i ++
	$p = $i/$orders.count*100
	write-progress -activity "2 of 7 Adding contacts to orders" -status "$p% Complete:" -percentcomplete $p;
}
$contact=$null
$delContacts=$null
$contacts=$null
[System.GC]::Collect()


$i=1

#Create phoneNumber fields on Consumers, and Identifiers and clean empty fields
$source = $sourceFolder + "OrderConsumer.csv"
$orderConsumers = Import-csv $source
$source = $sourceFolder + "OrderPersonIdentifier.csv"
$identifiersSource = Import-csv $source

$identifiers = New-object System.Collections.Arraylist
foreach($identifier in $identifiersSource){
	$identifiers.Add($identifier)
}

$identifiersSource = $null
[System.GC]::Collect()
$source = $sourceFolder + "orderItem.csv"
$orderItems = Import-csv $source
foreach ($consumer in $orderConsumers){

	$consumer | Add-Member -MemberType NoteProperty -Name phoneNumbers -Value (New-object System.Collections.Arraylist)
	if(-Not [string]::IsNullOrEmpty($consumer.HomePhone)){
		$consumer.phoneNumbers.add($consumer.HomePhone)
	}
	if(-Not [string]::IsNullOrEmpty($consumer.WorkPhone)){
		$consumer.phoneNumbers.add($consumer.WorkPhone)
	}
	if(-Not [string]::IsNullOrEmpty($consumer.OtherPhone)){
		$consumer.phoneNumbers.add($consumer.OtherPhone)
	}

	#remove no longer required fields containing phone numbers
	$consumer.PSObject.Properties.Remove('HomePhone')
	$consumer.PSObject.Properties.Remove('WorkPhone')
	$consumer.PSObject.Properties.Remove('OtherPhone')

	#create empty array to hold orderItems
    $consumer | Add-Member -MemberType NoteProperty -Name orderItems -Value (New-object System.Collections.Arraylist)

    #add orderitems
	foreach($orderItem in $orderItems){
        
       
        
		if ($orderItem.PassengerId -eq $consumer.PassengerId){
			
			#create new object for trimmed version of order item held in consumer
			$tempOrderItem = New-Object PSObject
			$tempOrderItem | Add-Member -MemberType NoteProperty -Name referenceId -Value $orderItem.referenceId
			$consumer.orderItems.add($tempOrderItem)
			$tempOrderItem=$null
			
		}
	}
	
  
	#add identiefiers to consumer
	$delIdentifiers = New-object System.Collections.Arraylist
    $consumer | Add-Member -MemberType NoteProperty -Name identifiers -Value (New-object System.Collections.Arraylist)
	foreach($identifier in $identifiers){
     
		if($identifier.PassengerId -eq $consumer.PassengerId){
			
			$identifier.PSObject.Properties.Remove('PassengerId')
			$consumer.Identifiers.add($identifier)
            
			$delIdentifiers.add($identifier)
		}
		
	}
	foreach($id in $delIdentifiers){
		$identifiers.remove($id)
	}
	$delIdentifiers.Clear()
	
	#remove 
	$consumer.PSObject.Properties.Remove('PassengerId')
    
	$i ++
	$p = $i/$orderConsumers.count*100
	write-progress -activity "3 of 7 Creating phoneNumber fields on Consumers, adding identifiers, order items and cleaning empty fields" -status "$p% Complete:" -percentcomplete $p;
}
$delIdentifiers = $null
$identifiers = $null
[System.GC]::Collect()

$i=1
#Adding consumers to orders
foreach ($order in $orders){
	#remove LoadRunID
    $order.PSObject.Properties.Remove('LoadRunID')
    #add order consumers
	$order | Add-Member -MemberType NoteProperty -Name consumers -Value (New-object System.Collections.Arraylist)

	foreach ($consumer in $orderConsumers){
	
		if($order.BookingId -eq $consumer.BookingId){
			
			$consumer.PSObject.Properties.Remove('BookingId')
			$order.Consumers.add($consumer)
			
		}
	}
	$i ++
	$p = $i/$orders.count*100
	write-progress -activity "4 of 7 Adding consumers to orders" -status "$p% Complete:" -percentcomplete $p;
}

$orderConsumers = $null
[System.GC]::Collect()

$i=1

#add flight segments to order items
$source = $sourceFolder + "FlightSegment.csv"
$flightSegments = Import-csv $source


#clean empty fields
			foreach($property in $flightSegment.psobject.properties){
				if($property.Value -eq '' -Or $property.IsNullOrEmpty -Or $property.Name -eq 'BookingId'){
				
					$flightSegment.PSObject.Properties.Remove($property.Name)
				}
			}

foreach ($orderItem in $orderItems){
		
		#create empty array to hold fight segments
		if($orderItem.FlightSegmentId -ne ''){
			$orderItem | Add-Member -MemberType NoteProperty -Name flightSegments -Value (New-object System.Collections.Arraylist)
			foreach ($flightSegment in $flightSegments){
				
				if($flightSegment.FlightSegmentId -eq $orderItem.FlightSegmentId){
				
					$flightSegment.PSObject.Properties.Remove('FlightSegmentId')
					$orderItem.FlightSegments.add($flightSegment)
					
				}

			}
		}

		

		
		$i ++
		$p = $i/$orderItems.count*100
	write-progress -activity "5 of 7 Adding flight segments to order items" -status "$p% Complete:" -percentcomplete $p;
}
$flightSegments = $null
[System.GC]::Collect()


$i=1
#add order items to orders
foreach ($order in $orders){
	#add order items
	$order | Add-Member -MemberType NoteProperty -Name orderItems -Value (New-object System.Collections.Arraylist)

	foreach ($orderItem in $orderItems){

		if($order.BookingId -eq $orderItem.BookingId){
			$orderItem.PSObject.Properties.Remove('BookingId')
			$orderItem.PSObject.Properties.Remove('PassengerId')
			$orderItem.PSObject.Properties.Remove('FlightSegmentId')
			$order.OrderItems.add($orderItem)

		}

	}

	$i ++
	$p = $i/$orders.count*100
	write-progress -activity "6 of 7 Populating orders with order items" -status "$p% Complete:" -percentcomplete $p;
}

	$orderItems=$null
	[System.GC]::Collect()
$orderItems = $null
[System.GC]::Collect()

$i=1

#Adding orders to outer container
$source = $sourceFolder + "OuterOrder.csv"
$outerObjects = Import-csv $source
foreach($outerOrder in $outerObjects){

	foreach($order in $orders){
		if($order.BookingId -eq $outerOrder.BookingId){
			$order.PSObject.Properties.Remove('BookingId')

			$outerOrder | Add-Member -MemberType NoteProperty -Name value -Value $order
			}
	}
    $outerOrder.PSObject.Properties.Remove('BookingId')
    $i++
	$p = $i/$outerObjects.count*100
	write-progress -activity "7 of 7 Adding orders to outer containers" -status "$p% Complete:" -percentcomplete $p;
}

#write orders to json file
$target = $sourceFolder + "orders.json"
$outerObjects | ConvertTo-Json -Depth 10 | Out-file $target

$content = [System.IO.File]::ReadAllText($target);

$expr1 = '\n+|\t+|\s+|\r+';
$expr2 = '\"\w+\":\[?null\]?,?|\"\w+\":"",?|\"\w+\":\[\],?|"PassengerID":"0",|{},?|(,|;).*@.*(?=",)';
$expr3 = ',}';
$expr4 = '\*';
$expr5 = '}},{"ref"';
$expr6 = '(?<!.)^.|.$(?!.)';


$firstResult = [System.Text.RegularExpressions.Regex]::Replace($content, $expr1, '');
$secondResult = [System.Text.RegularExpressions.Regex]::Replace($firstResult, $expr2, '');
$thirdResult = [System.Text.RegularExpressions.Regex]::Replace($secondResult, $expr3, '}');
$fourthResult= [System.Text.RegularExpressions.Regex]::Replace($thirdResult, $expr4, ' ');
$fifthResult = [System.Text.RegularExpressions.Regex]::Replace($fourthResult, $expr5, '}}'+"`n"+'{"ref"');
$sixthResult= [System.Text.RegularExpressions.Regex]::Replace($fifthResult, $expr6, '');


#$timestamp = Get-Date -Format "yyyy_M_dd_Hmmss"

$file = $destinationFolder+"order_final_" + $LoadRunID + ".json"

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