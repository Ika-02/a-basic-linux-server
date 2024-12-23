#!/bin/bash
sudo freshclam
sudo clamscan --infected --move=/share/quarantine --recursive --log=/home/admin/clamav.log /share
sudo clamscan --infected --move=/share/quarantine --recursive --log=/home/admin/clamav.log /web
sudo clamscan --infected --move=/share/quarantine --recursive --log=/home/admin/clamav.log /home
find /share/quarantine -type f -mtime +6 -delete
exit 0