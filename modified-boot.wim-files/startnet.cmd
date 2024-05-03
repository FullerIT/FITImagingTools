wpeinit
echo list volume > X:\ListCD.txt
::Define the USB Boot Partition
FOR /F "tokens=2,4" %%i IN ('diskpart /s X:\ListCD.txt') DO @IF /I %%j == WINPE SET CDROMVOL=%%i
IF DEFINED CDROMVOL echo select volume %CDROMVOL% > X:\ChangeCD.txt
IF DEFINED CDROMVOL echo assign letter=K: >> X:\ChangeCD.txt
IF DEFINED CDROMVOL diskpart /s X:\ChangeCD.txt
::Define the USB Image Partition
FOR /F "tokens=2,4" %%i IN ('diskpart /s X:\ListCD.txt') DO @IF /I %%j == IMAGES SET CDROMVOL=%%i
IF DEFINED CDROMVOL echo select volume %CDROMVOL% > X:\ChangeCD.txt
IF DEFINED CDROMVOL echo assign letter=I: >> X:\ChangeCD.txt
IF DEFINED CDROMVOL diskpart /s X:\ChangeCD.txt
call K:\bootmenu64.cmd
