@echo off
::check load id
set runIdCheck=sqlcmd -S "149.122.30.70,52900" -U JQODSUSER8 -P GAw49wet -W -h -1 -Q "SELECT TOP 1 LoadRunID FROM REZJQWB01.dwh.vwBoxeverOrder"

:: Enable delayed expansion of for-loop variables
setlocal EnableDelayedExpansion

set isFirst=1
	for /f "delims=" %%i in ('%runIdCheck%') do (
	  set val=%%i
	  ::echo Read value !val!, isFirst is !isFirst!
      if "!isFirst!"=="1" (
      	::echo Setting control record value to !val!
      	set LoadRunId=!val!
      )
      set isFirst=0
	)

sqlcmd -S SYDDC1SQL02 -U CRM_ETL -P Aa5vX+HNv -W -h -1 -Q "EXEC CRMData.dbo.spBoxeverDataLoadComplete %LoadRunId%"
