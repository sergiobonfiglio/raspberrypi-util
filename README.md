#Raspberrypi Utilities

 Utilities scripts for the Raspberry Pi

##rsnap-rotate
 Script to backup folders with rsnapshot only if the last backup is old enough. You can use this script if the backup target is not always available (e.g
 . I use this script to backup my laptop to an HD connected to my Raspberry)
 This script can be executed by cron with any frequency but a backup is only performed if the last one occurred at least 'x' hours ago.
 The 'x' parameter has to be specified as a comment in the same configuration file of rsnapshot:
 
```bash
 #<scheduling>   24
```
 In my current configuration my Raspberry tries to backup my remote computer every 15 minutes using the following cron job:
 
```bash
  */15   * * * *  root    /usr/local/bin/rsnap-rotate /etc/rsnapshot.conf > /dev/null
```
 My rsnapshot configuration to execute a backup a day, retain 7 daily, 4 weekly and 3 monthly backups:

```bash
 #<scheduling>   24
 retain  daily   7
 retain  weekly  4
 retain  monthly 3
```

***Requisites:***
* rsnapshot (of course).
* rsnapreport.pl for writing a nice output report.
 
##sharedTorrentDownloader.sh
 
 A simple script to crawl a Dropbox directory searching for .torrent files and copying them in Transmission's whatch folder.
 
***Requisites:***
* The Dropbox uploader script has to be installed (https://github.com/andreafabrizi/Dropbox-Uploader.git)
