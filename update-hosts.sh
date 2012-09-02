#!/bin/bash

xzcat res/misc/hosts.tar.xz > res/misc/hosts;
mv res/misc/hosts /tmp/;
wget http://winhelp2002.mvps.org/hosts.zip;
unzip hosts.zip HOSTS;
mv HOSTS res/misc/hosts;
rm hosts.zip;

diff /tmp/hosts res/misc/hosts;
echo "<- changes";
rm -f res/misc/hosts.tar.xz;
tar -cvJ --xz res/misc/hosts > res/misc/hosts.tar.xz;
rm -f res/misc/hosts;
echo "compressed new hosts file";

