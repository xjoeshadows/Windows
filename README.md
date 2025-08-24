# Windows
Windows stuff
- VPN-NetworkAdapterCheck.ps1: Helps improve opsec and accidental IP leaks if your VPN adapter is disconnected.. This script will check to see if a specific network adapter is connected, such as that of one being used by a VPN service before opening an app. If the adapter is disconnected, the script will prompt the user if they would still like to open the app.
- DateCreatedAdjuster.ps1: I designed this to adjust the datecreated attribute for thousands of photos that I had copied to an external drive in the past which resulted in apple photos sorting all of those photos to that day and time they were created. This script parses the filename for a date first and then falls back to the date taken and date modified attributes if it cannot find a date in the filename.
