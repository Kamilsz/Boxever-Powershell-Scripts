$content = [System.IO.File]::ReadAllText("C:\Users\Kamil\OneDrive\JetStar\Flat_FIle_Source\orders.json");

$expr1 = '\n+|\t+|\s+|\r+|\"\w+\"\s+:\s+null,?';
$expr2 = '\n';
$expr3 = '}},{"ref"';
$expr4 = ',"phoneNumbers":\[\]|,"OrderItems":\[\]|,"FlightSegments":\[\]|,"Identifiers":\[\]|"PassengerID":"0",|(?<!.)^.|.$(?!.)';


$firstResult = [System.Text.RegularExpressions.Regex]::Replace($content, $expr1, '');
$secondResult = [System.Text.RegularExpressions.Regex]::Replace($firstResult, $expr2, '');
$thirdResult = [System.Text.RegularExpressions.Regex]::Replace($secondResult, $expr3, '}}'+"`n"+'{"ref"');
$fourthResult = [System.Text.RegularExpressions.Regex]::Replace($thirdResult, $expr4, '');

$timestamp = Get-Date -Format "yyyy_M_dd_Hmmss"
$file = "C:\Users\Kamil\OneDrive\JetStar\Flat_FIle_Source\order_final_" + $timestamp + ".json"

[System.IO.File]::WriteAllText($file, $fourthResult );