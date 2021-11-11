@ECHO OFF
::Created by pellis@fullerinfotech.com
::V2021-11-11 added autodrivers folder to install drivers automatically.
::V2021-08-10 Encountered a system that booted PE with C assigned to the wrong partition (BIOS partition scheme, I think) Added a drive letter prompt to the capture commands
::V2021-07-16 Added deploynet and deployusb folder detection to direct the software to just deploy without prompts
::V2021-01-08 Added parameters to install all inf from drivers folder. Added Network capture. Fixed path for findstr. added variables
::V2019-08-02 Added more menu options for network deploy and other options

:: Drive letters used:
:: X, the bootable PE image (mounted boot.wim)
:: K, the usb default PE image WinPE (media folder on deploy server)
:: I, the location for the images to be placed Images (install.wim should be the only file here)
:: N, the optional mapped network drive to map in PE (optional mapped drive in PE)

::Not sure if vbs works in PE
::ECHO Wscript.Echo Inputbox("No spaces allowed. Example: PremiumWidgetCo", "Enter Company name: ")>%TEMP%\~input.vbs
::FOR /f "delims=/" %%G IN ('cscript //nologo %TEMP%\~input.vbs') DO set company=%%G
::DEL %TEMP%\~input.vbs

set netpath=\\FITRESTORETEST\CustomImages
set user=fitrestoretest\capture
set pwd=FITCap@93614

if exist %~dp0autodrivers\ (
  echo autodrivers folder detected
  echo starting driver install
  for /f "delims=" %%n in ('dir /s /b K:\autodrivers\*.inf') do drvload "%%n"
) else (
  echo No deployusb folder found
)

if exist %~dp0deployusb\ (
  echo deployusb folder detected
  echo starting image deploy
  goto:menu_3
) else (
  echo No deployusb folder found
)

if exist %~dp0deploynet\ (
  echo deploynet folder detected
  echo starting image deploy
  goto:menu_4
) else (
  echo No deploynet folder found
)


:menuLOOP
cls
for /f "tokens=1,2,* delims=_ " %%A in ('"K:\findstr /b /c:":menu_" "%~f0""') do echo.  %%B  %%C
set choice=
echo.&set /p choice=Selection(X to quit): ||GOTO:EOF
echo.&call:menu_%choice%
GOTO:menuLOOP


:menu_1   Capture Image (Local)
ECHO Capture Image (Local)
echo list vol > lsdisk.tmp
diskpart /s lsdisk.tmp
ECHO Wscript.Echo Inputbox("Enter Drive Letter to be imaged (ex: c:\) ")>%TEMP%\~input.vbs
FOR /f "delims=/" %%G IN ('cscript //nologo %TEMP%\~input.vbs') DO set disk=%%G
DEL %TEMP%\~input.vbs

dism /capture-image /capturedir:%disk% /imagefile:I:\install.wim /Name:"Windows 10" /compress:fast
ECHO Capture Image Task Complete
pause
GOTO:menuLOOP


:menu_2   Capture Image (Network)
Echo Capture Image (Network)
ECHO Connect to network
::net use I: \\10.115.76.9\images /user:host1\deploy deploy
::net use N: \\FITRESTORETEST\CustomImages /user:fitrestoretest\capture FITCap@93614
net use N: %netpath% /user:!user! !pwd!
ping 127.0.0.1 -n 5 >NUL
Echo Capturing ...
dism /capture-image /capturedir:c:\ /imagefile:N:\install.wim /Name:"Windows 10" /compress:fast
::W:\Windows\System32\bcdboot W:\Windows /s S:
ECHO Capture Image Task Complete
pause
GOTO:menuLOOP


:menu_3   Deploy USB Image
ECHO UEFI/BIOS Detection
wpeutil UpdateBootInfo
for /f "tokens=2* delims=	 " %%A in ('reg query HKLM\System\CurrentControlSet\Control /v PEFirmwareType') DO SET Firmware=%%B
if %Firmware%==0x1 echo Detected firmware mode: BIOS.
if %Firmware%==0x2 echo Detected firmware mode: UEFI.
if %Firmware%==0x1 diskpart /s %~dp0CreatePartitions-BIOS.txt
if %Firmware%==0x2 diskpart /s %~dp0CreatePartitions-UEFI.txt
ping 127.0.0.1 -n 5 >NUL

ECHO Applying Image
dism /Apply-Image /ImageFile:I:\install.wim /Index:1 /ApplyDir:W:\
W:\Windows\System32\bcdboot W:\Windows /s S:

ECHO Deploy Image Task Complete
pause
exit
GOTO:menuLOOP


:menu_4   Deploy Network Image
ECHO UEFI/BIOS Detection
wpeutil UpdateBootInfo
for /f "tokens=2* delims=	 " %%A in ('reg query HKLM\System\CurrentControlSet\Control /v PEFirmwareType') DO SET Firmware=%%B
if %Firmware%==0x1 echo Detected firmware mode: BIOS.
if %Firmware%==0x2 echo Detected firmware mode: UEFI.
if %Firmware%==0x1 diskpart /s %~dp0CreatePartitions-BIOS.txt
if %Firmware%==0x2 diskpart /s %~dp0CreatePartitions-UEFI.txt
ping 127.0.0.1 -n 5 >NUL

ECHO Connect to network
::net use I: \\10.115.76.9\images /user:host1\deploy deploy
net use N: \\FITRESTORETEST\CustomImages /user:fitrestoretest\capture FITCap@93614
ping 127.0.0.1 -n 5 >NUL

ECHO Applying Image
dism /Apply-Image /ImageFile:I:\install.wim /Index:1 /ApplyDir:W:\
W:\Windows\System32\bcdboot W:\Windows /s S:

ECHO Phase 4: Deploy Image Completed
pause
exit
GOTO:menuLOOP


:menu_5   Install inf files in Drivers folder
ECHO Install Network Drivers
for /f "delims=" %%n in ('dir /s /b K:\drivers\*.inf') do drvload "%%n"
pause
GOTO:menuLOOP


:menu_6   Open Command Line
start cmd
GOTO:menuLOOP


:menu_7   Query Network PCI VEN DEV Code and ipconfig
reg query HKLM\SYSTEM\CurrentControlSet\Enum\PCI /s /f "Network"
reg query HKLM\SYSTEM\CurrentControlSet\Enum\PCI /s /f "Ethernet"
ipconfig
pause
GOTO:menuLOOP


:menu_X   Exit
EXIT
GOTO:EOF