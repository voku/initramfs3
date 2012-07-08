#!/bin/bash

mv ./res/misc/hosts /tmp/;
wget http://winhelp2002.mvps.org/hosts.zip;
unzip hosts.zip HOSTS;
mv HOSTS ./res/misc/hosts;
rm hosts.zip;

diff /tmp/hosts ./res/misc/hosts;
echo "<- changes";
