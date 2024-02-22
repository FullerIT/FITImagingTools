:: This is a patched copy of the MakeWinPEMedia.cmd to remove the active command that breaks the completion of the script
:: Microsoft never added any logic in for GPT partition types, so this was the fastest way to work around this problem, some proper logic for this would be nice, but that is a future task.

@echo off
setlocal

rem
rem Set variables for local use
rem
set TEMPL=media
set FWFILES=fwfiles
set DISKPARTSCRIPT=%TMP%\UFDFormatDiskpartScript.txt
set EXITCODE=0

rem
rem Input validation
rem
if /i "%1"=="/?" goto usage
if /i "%1"=="" goto usage
if /i "%~2"=="" goto usage
if /i "%~3"=="" goto usage
if /i not "%~5"=="" goto usage
if /i not "%1"=="/UFD" (
  if /i not "%1"=="/ISO" goto usage
)

rem
rem Based on parameters input, assign local variables
rem
if /i "%~2"=="/f" (
  set FORCED=1
  set WORKINGDIR=%~3
  set DEST=%~4
) else (
  set FORCED=0
  set WORKINGDIR=%~2
  set DEST=%~3
)

rem
rem Make sure the working directory exists
rem
if not exist "%WORKINGDIR%" (
  echo ERROR: Working directory does not exist: "%WORKINGDIR%".
  goto fail
)

rem
rem Make sure the working directory is valid as per our requirements
rem
if not exist "%WORKINGDIR%\%TEMPL%" (
  echo ERROR: Working directory is not valid: "%WORKINGDIR%".
  goto fail
)

if not defined %TMP% (
  set DISKPARTSCRIPT=.\UFDFormatDiskpartScript.txt
)

if /i "%1"=="/UFD" goto UFDWorker

if /i "%1"=="/ISO" goto ISOWorker

rem
rem UFD section of the script, for creating bootable WinPE UFD
rem
:UFDWorker

  rem
  rem Make sure the user has administrator privileges
  rem These will be required to format the drive and set the boot code
  rem
  set ADMINTESTDIR=%WINDIR%\System32\Test_%RANDOM%
  mkdir "%ADMINTESTDIR%" 2>NUL
  if errorlevel 1 (
    echo ERROR: You need to run this command with administrator privileges.
    goto fail
  ) else (
    rd /s /q "%ADMINTESTDIR%"
  )

  rem
  rem Make sure the destination refers to a storage drive,
  rem and is not any other type of path
  rem
  echo %DEST%| findstr /B /E /I "[A-Z]:" >NUL
  if errorlevel 1 (
    echo ERROR: Destination needs to be a disk drive, e.g F:.
    goto fail
  )

  rem
  rem Make sure the destination path exists
  rem
  if not exist "%DEST%" (
    echo ERROR: Destination drive "%DEST%" does not exist.
    goto fail
  )

  if %FORCED% EQU 1 goto UFDWorker_FormatUFD

  rem
  rem Confirm from the user that they want to format the drive
  rem
  echo WARNING, ALL DATA ON DISK DRIVE %DEST% WILL BE LOST!
  choice /M "Proceed with Format "
  if errorlevel 2 goto UFDWorker_NoFormatUFD
  if errorlevel 1 goto UFDWorker_FormatUFD

:UFDWorker_NoFormatUFD
  echo UFD %DEST% will not be formatted; exiting.
  goto cleanup

:UFDWorker_FormatUFD
  rem
  rem Format the volume using diskpart, in FAT32 file system
  rem
  echo select volume=%DEST% > "%DISKPARTSCRIPT%"
  echo format fs=fat32 label="WinPE" quick >> "%DISKPARTSCRIPT%"
  ::echo active >> "%DISKPARTSCRIPT%"
  echo Formatting %DEST%...
  echo.
  diskpart /s "%DISKPARTSCRIPT%" >NUL
  set DISKPARTERR=%ERRORLEVEL%

  del /F /Q "%DISKPARTSCRIPT%"
  if errorlevel 1 (
    echo WARNING: Failed to delete temporary DiskPart script "%DISKPARTSCRIPT%".
  )
   
  if %DISKPARTERR% NEQ 0 (
    echo ERROR: Failed to format "%DEST%"; DiskPart errorlevel %DISKPARTERR%.
    goto fail
  )

  rem
  rem Set the boot code on the volume using bootsect.exe
  rem
  echo Setting the boot code on %DEST%...
  echo.
  bootsect.exe /nt60 %DEST% /force /mbr >NUL
  if errorlevel 1 (
    echo ERROR: Failed to set the boot code on %DEST%.
    goto fail
  )

  rem
  rem We first decompress the source directory that we are copying from.
  rem  This is done to work around an issue with xcopy when working with
  rem  compressed NTFS source directory.
  rem
  rem Note that this command will not cause an error on file systems that
  rem  do not support compression - because we do not use /f.
  rem
  compact /u "%WORKINGDIR%\%TEMPL%" >NUL
  if errorlevel 1 (
    echo ERROR: Failed to decompress "%WORKINGDIR%\%TEMPL%".
    goto fail
  )

  rem
  rem Copy the media files from the user-specified working directory
  rem
  echo Copying files to %DEST%...
  echo.
  xcopy /herky "%WORKINGDIR%\%TEMPL%\*.*" "%DEST%\" >NUL
  if errorlevel 1 (
    echo ERROR: Failed to copy files to "%DEST%\".
    goto fail
  )

  goto success

rem
rem ISO section of the script, for creating bootable ISO image
rem
:ISOWorker

  rem
  rem Make sure the destination refers to an ISO file, ending in .ISO
  rem
  echo %DEST%| findstr /E /I "\.iso" >NUL
  if errorlevel 1 (
    echo ERROR: Destination needs to be an .ISO file.
    goto fail
  )

  if not exist "%DEST%" goto ISOWorker_OscdImgCommand

  if %FORCED% EQU 1 goto ISOWorker_CleanDestinationFile

  rem
  rem Confirm from the user that they want to overwrite the existing ISO file
  rem
  choice /M "Destination file %DEST% exists, overwrite it "
  if errorlevel 2 goto ISOWorker_DestinationFileExists
  if errorlevel 1 goto ISOWorker_CleanDestinationFile

:ISOWorker_DestinationFileExists
  echo Destination file %DEST% will not be overwritten; exiting.
  goto cleanup

:ISOWorker_CleanDestinationFile
  rem
  rem Delete the existing ISO file
  rem
  del /F /Q "%DEST%"
  if errorlevel 1 (
    echo ERROR: Failed to delete "%DEST%".
    goto fail
  )

:ISOWorker_OscdImgCommand

  rem
  rem Set the correct boot argument based on availability of boot apps
  rem
  set BOOTDATA=1#pEF,e,b"%WORKINGDIR%\%FWFILES%\efisys.bin"
  if exist "%WORKINGDIR%\%FWFILES%\etfsboot.com" (
    set BOOTDATA=2#p0,e,b"%WORKINGDIR%\%FWFILES%\etfsboot.com"#pEF,e,b"%WORKINGDIR%\%FWFILES%\efisys.bin"
  )

  rem
  rem Create the ISO file using the appropriate OSCDImg command
  rem
  echo Creating %DEST%...
  echo.
  oscdimg -bootdata:%BOOTDATA% -u1 -udfver102 "%WORKINGDIR%\%TEMPL%" "%DEST%" >NUL
  if errorlevel 1 (
    echo ERROR: Failed to create "%DEST%" file.
    goto fail
  )

  goto success

:success
set EXITCODE=0
echo.
echo Success
echo.
goto cleanup

:usage
set EXITCODE=1
echo Creates bootable WinPE USB flash drive or ISO file.
echo.
echo MakeWinPEMedia {/ufd ^| /iso} [/f] ^<workingDirectory^> ^<destination^>
echo.
echo  /ufd              Specifies a USB Flash Drive as the media type.
echo                    NOTE: THE USB FLASH DRIVE WILL BE FORMATTED.
echo  /iso              Specifies an ISO file (for CD or DVD) as the media type.
echo  /f                Suppresses prompting to confirm formatting the UFD
echo                    or overwriting existing ISO file.
echo  workingDirectory  Specifies the working directory created using copype.cmd
echo                    The contents of the ^<workingDirectory^>\media folder
echo                    will be copied to the UFD or ISO.
echo  destination       Specifies the UFD volume or .ISO path and file name.
echo.
echo  Examples:
echo    MakeWinPEMedia /UFD C:\WinPE_amd64 G:
echo    MakeWinPEMedia /UFD /F C:\WinPE_amd64 H:
echo    MakeWinPEMedia /ISO C:\WinPE_x86 C:\WinPE_x86\WinPE_x86.iso
goto cleanup

:fail
set EXITCODE=1
goto cleanup

:cleanup
endlocal & exit /b %EXITCODE%
