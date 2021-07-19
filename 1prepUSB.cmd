@echo off
setlocal enabledelayedexpansion

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
Echo Select the USB Disk to be formatted:
echo list disk > lsdisk.tmp
diskpart /s lsdisk.tmp

ECHO Wscript.Echo Inputbox("Enter Disk (number only) to be formatted:")>%TEMP%\~input.vbs
FOR /f "delims=/" %%G IN ('cscript //nologo %TEMP%\~input.vbs') DO set disk=%%G
DEL %TEMP%\~input.vbs

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
echo WARNING: If you see errors above just run it again, sometimes the file system is in use and it fails the first try
Echo Now run 2makeusbpe.cmd
::echo After that put the wim file into O drive letter
pause


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
