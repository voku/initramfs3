#!/bin/bash

xzcat res/misc/hosts.xz > /tmp/hosts;
wget http://winhelp2002.mvps.org/hosts.zip;
unzip hosts.zip HOSTS;
mv HOSTS res/misc/hosts;
rm hosts.zip;

diff /tmp/hosts res/misc/hosts;
echo "<- changes";
rm -f res/misc/hosts.xz;
xz -zekv9 res/misc/hosts;
rm -f res/misc/hosts;
echo "compressed new hosts file";

