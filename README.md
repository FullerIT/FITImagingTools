# FITImagingTools
## Warnings
This script will maintain BIOS or UEFI partition types, but destination cloned systems will only get the OS written to them, any Dell partitions, acronis, etc will be wiped from destination devices.

## Tools for creating Windows 10 images
Pre-requisites:

https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install

https://go.microsoft.com/fwlink/?linkid=2120253

https://go.microsoft.com/fwlink/?linkid=2120254


Install both adksetup.exe and adkwinpesetup.exe only selecting the default options.


From the "**Deployment and Imaging Tools Environment**", run the copype command:
> copype amd64 C:\WinPE_amd64


In the generated media folder, take all those contents and drop them into the empty media folder in our project.


## Prep the boot.wim to call bootmenu64.cmd
Run mnt.cmd, in the mount folder, Windows\system32 locate startnet.cmd
Replace it with the startnet.cmd from modified-boot.wim-files
This sets the drive letters and calls bootmenu64.cmd
When done modifying to the boot.wim, run commitmnt.cmd

## Burned in PE Image Drivers (not recommended)

Adding drivers at boot time is sometimes necessary (usually only if you crash before startnet.cmd runs).
You can add them here if you plan to use them on all future images or you can add them dynamically when the image boots.


To burn the drivers into the boot.wim run
> mnt.cmd


Place the drivers into the InjectPEDrivers folder then run
> adddriver.cmd


Once the process completes you can dismount the image
> mntcommit.cmd


If you made a mistake with the mounted image, you can discard the changes run
> discardmnt.cmd

## Drivers during PE start up
Place drivers in "drivers" or "autodrivers" in the media folder in the build environment to copy to each flash drive when they are built.
Use 'autodrivers' for automatic loading on PE start up via bootmenu64.cmd or 'drivers' for manually loading via the drivers menu option.

## Sysprep script
Place the !FITImage folder at the same level as "Windows" folder on your Golden Image that you intend to capture.
You can use that powershell script to generate a quick OOBE unattend file, clean AppX packages and to start the sysprep with unattend.
The folder is a good place to put files that you realize you need to run manually after the image is deployed, such as software to run after the install that doesn't cooperate well when imaged.

## Creating the USB
Get a clean USB and insert it into your technician PC.
Run 
> 1prepUSB.cmd


This should create the partition table, if you get errors just run it a second time, sometimes another process grabs the file system before it can be formatted and it freaks out.
You should see two partitions showing up named WINPE and Images now.


Then run 
> 2makeusbpe.cmd


This will place the pe files onto the flash drive's WinPE partition.


Some mount scripts are included in case you need to modify the default PE image.


Once the USB is created, place it in the Golden Image system and press F12 or F10 or whatever to confirm the boot menu button, make a note of it.
You may also want to confirm that diskpart can see the local disk, you can just run diskpart and then 'list disk' to confirm you see more than just the USB disk. See troubleshooting below if you just see one disk.

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


The options are pretty clear. Capture your image and then move the flash to a test system and deploy it.

## Making extra flash drives
buildusbflash.cmd combines 1prep and 2makeusbpe into a single script and also let's you set automation parameters for the bootmenu64 script.
This is often used to make clones of additional flash drives. Once you have your image, let's say it's in the images partition, you can copy the wim file to our build environment folder "image-partition"
The buildusbflash.cmd will copy that image to the new flash drives it makes.

The menu on this script if ignored, creates the same bootable flash drive as running 1prep and 2makeusb scripts, but the menu allows you to drop files into the usb that signal bootmenu64 to ignore the menu and start a specific process.
One option enables autodriver deployment, another starts deployment of a usb based image and the last option starts a network image deployment (advanced), that option requires modifying the scripts a bit to include an SMB path containing the image.


## Troubleshooting:

If you can't see the local disk when you boot the usb, you may want to boot the gold image back up and check the driver for the storage controller, you'll need to download that inf and sys driver from the vendor and place it in autodrivers on the flash drive or put it in drivers on the flash drive, then you can load that driver from the boot menu, autodrivers, will load all drivers in the folder.
It's best to only load what is necessary rather than drop a bunch of drivers in that will only consume system memory.

### Sysprep problems
Sysprep may fail and point you to the log file at %windir%\system32\sysprep\Panther\setupact.log
If error appears such as 'Sysprep_Clean_Validate_Opk' "Audit mode cannot be turned on if reserved storage is in use. An update or servicing operation may be using reserved storage.
You may have a pending update to complete installing, then re-run the script.




