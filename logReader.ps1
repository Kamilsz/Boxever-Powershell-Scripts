#This script reads and interprets Boxever log files

    [int]$errorThreshold = 10;

    $logsFolder = "E:\data\outbound\boxever\Log"
     

    Get-ChildItem $logsFolder -Filter "*.log" | `

    Foreach-Object{
            $errors = 0
            
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
        $content | `

        ForEach-Object {
            if($_.contains('"code":"4')){
                $errors ++
            }
           

        }
        
        [int]$ratio = ($errors * 100) /  $content.Count
        
         
        Remove-Item $unzippedFile
        
        #if number of errors equalt to or exceeds threshold, throw an error
        if($ratio -ge $errorThreshold) {
            Write-Host "Error: threshold exceeded in " $_.FullName
            Write-Host "Number of errors: " $errors
            Write-Host "Number of records: " $content.Count
            Write-Host "Ratio: " $ratio
            exit 1
        }

        #otherwise move file to success folder
        else {
            $destination = $logsFolder + "\Success\" + $_
            Move-Item $_.FullName $destination
        }
        
    
    }
    Write-Host "Success! No errors found."
    exit 0
