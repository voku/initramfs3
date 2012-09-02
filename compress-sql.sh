#!/bin/sh

#RUN me from root of initramfs

if [ -e res/misc/sql/ics/libsqlite.so ]; then
	rm -f res/misc/sql/ics/libsqlite.so.xz
	chmod 755 res/misc/sql/ics/libsqlite.so
	xz -zekv9 res/misc/sql/ics/libsqlite.so
	rm -f res/misc/sql/ics/libsqlite.so
	echo "ICS sql compressed"
fi;

if [ -e res/misc/sql/jb/libsqlite.so ]; then
	rm -f res/misc/sql/jb/libsqlite.so.xz
	chmod 755 res/misc/sql/ics/libsqlite.so
	xz -zekv9 res/misc/sql/jb/libsqlite.so
	rm -f res/misc/sql/jb/libsqlite.so
	echo "JB sql compressed"
fi;

