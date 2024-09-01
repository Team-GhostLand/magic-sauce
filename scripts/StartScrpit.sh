#!/bin/bash
 
echo "Kernel Version: $(uname -a)" > /etc/kernelinfo.txt
chmod -R 755 /var/run/screen
fish