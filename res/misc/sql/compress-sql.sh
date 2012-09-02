#!/bin/sh

if [ -e ics/libsqlite.so ]; then
	rm -f ics/libsqlite.so.tar.xz
	tar -cvJ --xz ics/libsqlite.so > ics/libsqlite.so.tar.xz
	rm -f ics/libsqlite.so
	echo "ICS sql compressed"
fi;

if [ -e jb/libsqlite.so ]; then
	rm -f jb/libsqlite.so.tar.xz
	tar -cvJ --xz jb/libsqlite.so > jb/libsqlite.so.tar.xz
	rm -f jb/libsqlite.so
	echo "JB sql compressed"
fi;

