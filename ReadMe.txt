

Requirements For Running This Script

System should have sendmail installed
System should have rsync installed
System should have Dblogs Directory 


How To Run This Script
Changes Are Required in serverConfigurationFile.cfg in order to setup Path for various Directories both for source and Destination
After that change directory to where Script is stored which is followed by ./logShippingScript.sh

What Does This Script Attain
It convert Log Files in Single Gzip File,and then it also Split that part
It is used for Transfering split Versions along wth their MD5
It Checks For Previous Gzips which were not transferred and then transfers them again
It Send Mail For both Successful And Failed Transfers,along with that it send Alert Email if error occur anywhere.