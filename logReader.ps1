#This script reads and interprets Boxever log files

    [int]$errorThreshold = 3;

    $logsFolder = "E:\data\outbound\boxever\Log"
    $sourcePath = $logsFolder + "\*"
    $raiseException = $false
     

    Get-ChildItem -Path $sourcePath -Include "*.log" | `

    Foreach-Object{
            $errors = 0
             $skipFile = $false
            <#decompress gzipped log file
            $input = New-Object System.IO.FileStream $_.FullName, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read);
            $output = New-Object System.IO.FileStream $_.FullName.Replace(".gz",""), ([IO.FileMode]::Create), ([IO.FileAccess]::Write), ([IO.FileShare]::None)
            $gzipStream = New-Object System.IO.Compression.GzipStream $input, ([IO.Compression.CompressionMode]::Decompress)
            try {
                $buffer = New-Object byte[](1024);
                while ($true) {
                    $read = $gzipStream.Read($buffer, 0, 1024)
                    if ($read -le 0) {
                        break;
                    }
                    $output.Write($buffer, 0, $read)
                }
            }
            finally {
                Write-Verbose "Closing streams and newly decompressed file"
                $gzipStream.Close();
                $output.Close();
                $input.Close();
            }
        
        $unzippedFile = $_.FullName.Replace(".gz","")
        #>
        $content = Get-Content $_.FullName
        Write-Host "" 
        Write-Host "Processing " $_.Name
        $content | `

        ForEach-Object {
            if($_.contains('"code":"') -and !$_.contains('"code":"2')){
                $errors ++
            } elseif($_.contains('No logs available')){
                Write-Host "No logs available, load successfull!"
                $errors = 0
            } elseif($_.contains('Upload completed')){
                $errors = 0
                $skipFile=$false
            }elseif($_.contains('Boxever File Upload')){
                
                    #extract date and time when the file was uploaded
                    $_ -match '[a-z,A-Z]{3}\s\d\d\s\d\d:\d\d:\d\d\sEST\s\d{4}'
                    $rawUploadTime = $matches[0].Replace('EST ','')
                    $uploadTime = [dateTime]::ParseExact($rawUploadTime, "MMM dd HH:mm:ss yyyy",$null)
                    $timeDifference = New-TimeSpan -Start $uploadTime
                    if($timeDifference.TotalMinutes -gt 5){
                        $errors = $content.Count
                        Write-Host "Failed to upload file within 5 minutes"
                    } else{
                     $skipFile = $true
                    }
            }
           

        }
        
        [int]$ratio = ($errors * 100) /  $content.Count
        
         
        #Uncomment line below if unzipping file is required
        #Remove-Item $unzippedFile
        
        #if number of errors equalt to or exceeds threshold, throw an error
        if(!$skipFile){
            if($ratio -ge $errorThreshold) {
                $destination = $logsFolder + "\Error\" + $_.Name
                Write-Host "Error: threshold exceeded in " $_.FullName
                $raiseException = $true
            }

            #otherwise move file to success folder
            else {
                $destination = $logsFolder + "\Success\" + $_.Name
                Write-Host "Success: number of errors within acceptable limit for " $_.FullName                         
            }
            Write-Host "Number of errors: " $errors
            Write-Host "Number of records: " $content.Count
            Write-Host "Error ratio: " $ratio
            Write-Host "Moving file to " $destination
            Move-Item $_.FullName $destination
        }else {
            Write-Host "Upload in progres. Skipping " $_.Name
        }
    
    }
    if($raiseException){
        Write-Host "" 
        Write-Host "Errors were found. Please check Error folder for details."
        exit 1
    }
    Write-Host "" 
    Write-Host "Success! No errors found."
    exit 0
