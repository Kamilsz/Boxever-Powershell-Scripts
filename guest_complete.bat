@echo off
::check load id
set runIdCheck=sqlcmd -S SYDDC1SQL02 -U CRM_ETL -P Aa5vX+HNv -W -h -1 -Q "SELECT TOP 1 LoadRunID FROM [CRMData].[dbo].[vwBoxeverGuest]"

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

sqlcmd -S SYDDC1SQL02 -U CRM_ETL -P Aa5vX+HNv -W -h -1 -Q "EXEC [CRMData].[dbo].[spBoxeverGuestLoadComplete] %LoadRunId%"
