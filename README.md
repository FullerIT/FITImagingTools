# FITImagingTools
 Tools for creating Windows 10 images
Pre-Requisites:
https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install
https://go.microsoft.com/fwlink/?linkid=2120253
https://go.microsoft.com/fwlink/?linkid=2120254

Using Deployment and Imaging Tools Environment, run the copype command:
> copype amd64 C:\WinPE_amd64
In the media folder, take all those contents and drop them into media folder in this folder.


You can use the "adddrivers" script to inject drivers into the PE image(you have to run mount before the command and commit after), but you can also do this inside PE itself,
by adding the drivers to the drivers folder in PE and running the menu commands to add a driver.


Place the !FITImage folder at the same level as "Windows" folder on your Golden Image.
You can use that powershell script to generate a quick OOBE unattend file, clean AppX packages and to start the sysprep with unattend.
The folder is a good place to put after image files that you may need as well.


Get a clean USB and insert it into your technician PC.
Run 
> 1prepUSB.cmd


This should create the partition table, if you get errors just run it a second time, sometimes another process grabs the file system before it can be formatted and it freaks out.


Then run 
> 2makeusbpe.cmd


This will place the pe files onto the flash drive's WinPE partition.


Some mount scripts are included in case you need to modify the default PE image.
Adding drivers is sometimes necessary. You can add them here if you plan to use them on all future images or you can add them dynamically when the image boots.
To burn the drivers into the boot.wim run
> mnt.cmd
Place the drivers into the InjectPEDrivers folder then run
> adddriver.cmd


Once the process completes you can dismount the image
> mntcommit.cmd


If you made a mistake with the mounted image, you can discard the changes run
> discardmnt.cmd


Once the USB is created, place it in the Golden Image system and press F12 or F10 or whatever to confirm the boot menu button, make a note of it.

Boot the Golden Image normally and do the typical cleanup items:
* Run disk cleanup as Administrator and select all the options
* Empty browser cache on each browser
* Clear the Quick Access folders and file lists
* Empty the temp folder, but you have to reboot after doing so

Now you can run the syspreptool.ps1 file, you may need to run it with bypass flag included
> PowerShell.exe -ExecutionPolicy Bypass -File .C:\!FITImage\syspreptool.ps1


It will prompt for the name to insert into the unattend file. On the menu you can select each option and the sysprep option will perform a shutdown if it succeeds.

Once the system is shutdown, make sure the usb is inserted and you know the key to access the boot menu and power it on and select the boot menu.
You want UEFI boot on the flash drive, it will start up and preset a menu of options.
You can add drivers here for a one-off driver PE driver setup, useful for disk drivers or network drivers if you are doing a network image.


The options are pretty clear. Capture your image and then move the flash to a test system and deploy it.
