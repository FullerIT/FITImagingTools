:: ////////////////////////////////////////////////////////////////////////////
:: buildusbflash
:: v2022071801
:: This file will create a bootable flash drive to capture or deploy a windows 10 or 11 image and helps to build additional copies as well
:: https://github.com/FullerIT/FITImagingTools
:: 
:: ////////////////////////////////////////////////////////////////////////////


@echo off
setlocal enabledelayedexpansion
:: Spaghetti Code Incoming !!!!!
set CmdDir=%~dp0
set CmdDir=%CmdDir:~0,-1%


:: ////////////////////////////////////////////////////////////////////////////
:: Check whether running elevated
:: ////////////////////////////////////////////////////////////////////////////
call :CREATE_ELEVATE_SCRIPTS

:: Check for Mandatory Label\High Mandatory Level
whoami /groups | find "S-1-16-12288" > nul
if "%errorlevel%"=="0" (
    echo Running as elevated user.  Continuing script.
) else (
    echo Not running as elevated user.
    echo Relaunching Elevated: "%~dpnx0" %*

    if exist "%Temp%\elevate.cmd" (
        set ELEVATE_COMMAND="%Temp%\elevate.cmd"
    ) else (
        set ELEVATE_COMMAND=elevate.cmd
    )

    set CARET=^^
    !ELEVATE_COMMAND! cmd /k cd /d "%~dp0" !CARET!^& call "%~dpnx0" %*
    goto :EOF
)

if exist %ELEVATE_CMD% del %ELEVATE_CMD%
if exist %ELEVATE_VBS% del %ELEVATE_VBS%


:: ////////////////////////////////////////////////////////////////////////////
:: Main script code starts here
:: ////////////////////////////////////////////////////////////////////////////
set deployusb=
set deploynet=
set autodrivers=


:choicedeploy
cls
set choice=
set /p choice=Set Flags for (A)utodriver, Deploy(U)SB, Deploy(N)et or (D)one?
if not '%choice%'=='' set choice=%choice:~0,1%
if '%choice%'=='A' goto autodrivers
if '%choice%'=='U' goto deployusb
if '%choice%'=='N' goto deploynet
if '%choice%'=='D' goto 1prepUSB
ECHO "%choice%" is not valid, try again
ECHO.
goto choicedeploy

:autodrivers
set autodrivers=y
ECHO AutoDrivers Set
PING localhost -n 2 >NUL
goto choicedeploy
:deployusb
set deployusb=y
ECHO DeployUSB Set
PING localhost -n 2 >NUL
goto choicedeploy
:deploynet
set deploynet=y
ECHO DeployNet Set
PING localhost -n 2 >NUL
goto choicedeploy


:1prepUSB
cls
Echo Select the USB Disk to be formatted:
echo list disk > lsdisk.tmp
diskpart /s lsdisk.tmp

::ECHO Wscript.Echo Inputbox("Enter Disk (number only) to be formatted:")>%TEMP%\~input.vbs
::FOR /f "delims=/" %%G IN ('cscript //nologo %TEMP%\~input.vbs') DO set disk=%%G
::DEL %TEMP%\~input.vbs
echo .
set /p disk=Disk Number?
:retryprepUSB
echo sel disk %disk% > clean.tmp
echo clean >> clean.tmp
echo create partition primary size=700 >> clean.tmp
::echo create partition primary >> clean.tmp
echo format quick fs=fat32 label="WinPE" >> clean.tmp
echo assign letter=P >> clean.tmp
echo active >> clean.tmp
echo create partition primary >> clean.tmp
echo format fs=ntfs quick label="Images" >> clean.tmp
echo assign letter=I >> clean.tmp
echo list vol >> clean.tmp
diskpart /s clean.tmp
del /q clean.tmp lsdisk.tmp
LABEL P: WinPE
LABEL I: Images
echo . >P:\touch
dir P:>nul
IF %ERRORLEVEL% NEQ 0 GOTO failedStage1
ECHO Format Success
del /q P:\touch
GOTO :2makeusbpe

:failedStage1
ECHO Format Failed, retrying
GOTO retryprepUSB
::
:choicestart
::set choice=
::set /p choice=Retry?
::if not '%choice%'=='' set choice=%choice:~0,1%
::f '%choice%'=='Y' goto retryprepUSB
::if '%choice%'=='N' goto 2makeusbpe
::ECHO "%choice%" is not valid, try again
::ECHO.
::goto choicestart
:2makeusbpe
REM
REM Sets the PROCESSOR_ARCHITECTURE according to native platform for x86 and x64. 
REM
IF /I %PROCESSOR_ARCHITECTURE%==x86 (
    IF NOT "%PROCESSOR_ARCHITEW6432%"=="" (
        SET PROCESSOR_ARCHITECTURE=%PROCESSOR_ARCHITEW6432%
    )
) ELSE IF /I NOT %PROCESSOR_ARCHITECTURE%==amd64 (
    @echo Not implemented for PROCESSOR_ARCHITECTURE of %PROCESSOR_ARCHITECTURE%.
    @echo Using "%ProgramFiles%"
    
    SET NewPath="%ProgramFiles%"

    goto SetPath
)

REM
REM Query the 32-bit and 64-bit Registry hive for KitsRoot
REM

SET regKeyPathFound=1
SET wowRegKeyPathFound=1
SET KitsRootRegValueName=KitsRoot10

REG QUERY "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v %KitsRootRegValueName% 1>NUL 2>NUL || SET wowRegKeyPathFound=0
REG QUERY "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v %KitsRootRegValueName% 1>NUL 2>NUL || SET regKeyPathFound=0

if %wowRegKeyPathFound% EQU 0 (
  if %regKeyPathFound% EQU 0 (
    @echo KitsRoot not found, can't set common path for Deployment Tools
    goto :EOF 
  ) else (
    SET regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    SET regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)


  
FOR /F "skip=2 tokens=2*" %%i IN ('REG QUERY "%regKeyPath%" /v %KitsRootRegValueName%') DO (SET KitsRoot=%%j)

REM
REM Build the D&I Root from the queried KitsRoot
REM
SET DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools

REM
REM Construct the path to WinPE directory, architecture-independent
REM
SET WinPERoot=%KitsRoot%Assessment and Deployment Kit\Windows Preinstallation Environment
SET WinPERootNoArch=%KitsRoot%Assessment and Deployment Kit\Windows Preinstallation Environment

REM
REM Construct the path to DISM, Setup and USMT, architecture-independent
REM
SET WindowsSetupRootNoArch=%KitsRoot%Assessment and Deployment Kit\Windows Setup
SET USMTRootNoArch=%KitsRoot%Assessment and Deployment Kit\User State Migration Tool

REM 
REM Constructing tools paths relevant to the current Processor Architecture 
REM
SET DISMRoot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\DISM
SET BCDBootRoot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\BCDBoot
SET ImagingRoot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\Imaging
SET OSCDImgRoot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\Oscdimg
SET WdsmcastRoot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\Wdsmcast

REM
REM Now do the paths that apply to all architectures...
REM
REM Note that the last one in this list should not have a
REM trailing semi-colon to avoid duplicate semi-colons
REM on the last entry when the final path is assembled.
REM
SET HelpIndexerRoot=%DandIRoot%\HelpIndexer

REM
REM Set WSIM path. WSIM is X86 only and ships in architecture-independent path
REM
SET WSIMRoot=%DandIRoot%\WSIM

REM
REM Set ICDRoot. ICD is X86 only
REM
SET ICDRoot=%KitsRoot%Assessment and Deployment Kit\Imaging and Configuration Designer\x86

REM
REM Now build the master path from the various tool root folders...
REM
REM Note that each fragment above should have any required trailing 
REM semi-colon as a delimiter so we do not put any here.
REM
REM Note the last one appended to NewPath should be the last one
REM set above in the arch. neutral section which also should not
REM have a trailing semi-colon.
REM
SET NewPath=%DISMRoot%;%ImagingRoot%;%BCDBootRoot%;%OSCDImgRoot%;%WdsmcastRoot%;%HelpIndexerRoot%;%WSIMRoot%;%WinPERoot%;%ICDRoot%

:SetPath
SET PATH=%NewPath:"=%;%PATH%

REM Set current directory to DandIRoot
ECHO .
ECHO bootsect.exe /nt60 WINPEDRVLETTER /force /mbr >NUL
ECHO .
cd /d "%DandIRoot%"
popd
call "%WinPERoot%\MakeWinPEMedia.cmd" /UFD /F %~dp0 P:

if defined autodrivers (
    echo creating autodrivers
    mkdir P:\autodrivers
)
if defined deployusb (
    echo creating deployusb
    mkdir P:\deployusb
)
if defined deploynet (
    echo creating deploynet
    mkdir P:\deploynet
)

robocopy %~dp0image-partition I:\ /e

:: ////////////////////////////////////////////////////////////////////////////
:: End of main script code here
:: ////////////////////////////////////////////////////////////////////////////
goto :EOF

:: ////////////////////////////////////////////////////////////////////////////
:: Subroutines
:: ////////////////////////////////////////////////////////////////////////////

:CREATE_ELEVATE_SCRIPTS

    set ELEVATE_CMD="%Temp%\elevate.cmd"

    echo @setlocal>%ELEVATE_CMD%
    echo @echo off>>%ELEVATE_CMD%
    echo. >>%ELEVATE_CMD%
    echo :: Pass raw command line agruments and first argument to Elevate.vbs>>%ELEVATE_CMD%
    echo :: through environment variables.>>%ELEVATE_CMD%
    echo set ELEVATE_CMDLINE=%%*>>%ELEVATE_CMD%
    echo set ELEVATE_APP=%%1>>%ELEVATE_CMD%
    echo. >>%ELEVATE_CMD%
    echo start wscript //nologo "%%~dpn0.vbs" %%*>>%ELEVATE_CMD%


    set ELEVATE_VBS="%Temp%\elevate.vbs"

    echo Set objShell ^= CreateObject^("Shell.Application"^)>%ELEVATE_VBS% 
    echo Set objWshShell ^= WScript.CreateObject^("WScript.Shell"^)>>%ELEVATE_VBS%
    echo Set objWshProcessEnv ^= objWshShell.Environment^("PROCESS"^)>>%ELEVATE_VBS%
    echo. >>%ELEVATE_VBS%
    echo ' Get raw command line agruments and first argument from Elevate.cmd passed>>%ELEVATE_VBS%
    echo ' in through environment variables.>>%ELEVATE_VBS%
    echo strCommandLine ^= objWshProcessEnv^("ELEVATE_CMDLINE"^)>>%ELEVATE_VBS%
    echo strApplication ^= objWshProcessEnv^("ELEVATE_APP"^)>>%ELEVATE_VBS%
    echo strArguments ^= Right^(strCommandLine, ^(Len^(strCommandLine^) - Len^(strApplication^)^)^)>>%ELEVATE_VBS%
    echo. >>%ELEVATE_VBS%
    echo If ^(WScript.Arguments.Count ^>^= 1^) Then>>%ELEVATE_VBS%
    echo     strFlag ^= WScript.Arguments^(0^)>>%ELEVATE_VBS%
    echo     If ^(strFlag ^= "") OR (strFlag="help") OR (strFlag="/h") OR (strFlag="\h") OR (strFlag="-h"^) _>>%ELEVATE_VBS%
    echo         OR ^(strFlag ^= "\?") OR (strFlag = "/?") OR (strFlag = "-?") OR (strFlag="h"^) _>>%ELEVATE_VBS%
    echo         OR ^(strFlag ^= "?"^) Then>>%ELEVATE_VBS%
    echo         DisplayUsage>>%ELEVATE_VBS%
    echo         WScript.Quit>>%ELEVATE_VBS%
    echo     Else>>%ELEVATE_VBS%
    echo         objShell.ShellExecute strApplication, strArguments, "", "runas">>%ELEVATE_VBS%
    echo     End If>>%ELEVATE_VBS%
    echo Else>>%ELEVATE_VBS%
    echo     DisplayUsage>>%ELEVATE_VBS%
    echo     WScript.Quit>>%ELEVATE_VBS%
    echo End If>>%ELEVATE_VBS%
    echo. >>%ELEVATE_VBS%
    echo. >>%ELEVATE_VBS%
    echo Sub DisplayUsage>>%ELEVATE_VBS%
    echo. >>%ELEVATE_VBS%
    echo     WScript.Echo "Elevate - Elevation Command Line Tool for Windows Vista" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "Purpose:" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "--------" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "To launch applications that prompt for elevation (i.e. Run as Administrator)" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "from the command line, a script, or the Run box." ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "Usage:   " ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate application <arguments>" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "Sample usage:" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate notepad ""C:\Windows\win.ini""" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate cmd /k cd ""C:\Program Files""" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate powershell -NoExit -Command Set-Location 'C:\Windows'" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "Usage with scripts: When using the elevate command with scripts such as" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "Windows Script Host or Windows PowerShell scripts, you should specify" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "the script host executable (i.e., wscript, cscript, powershell) as the " ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "application." ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "Sample usage with scripts:" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate wscript ""C:\windows\system32\slmgr.vbs"" –dli" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate powershell -NoExit -Command & 'C:\Temp\Test.ps1'" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "The elevate command consists of the following files:" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate.cmd" ^& vbCrLf ^& _>>%ELEVATE_VBS%
    echo                  "    elevate.vbs" ^& vbCrLf>>%ELEVATE_VBS%
    echo. >>%ELEVATE_VBS%
    echo End Sub>>%ELEVATE_VBS%

goto :EOF
