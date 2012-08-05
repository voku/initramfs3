#!/sbin/busybox

echo "";
echo "*********************************************";
echo "Optimizing and defragging your database files (*.db)";
echo "Ignore the 'database disk image is malformed' error";
echo "Ignore the 'no such collation sequence' error";
echo "*********************************************";
echo "";

for i in \
`busybox find /data -iname "*.db"`; 
do \
	/system/xbin/sqlite3 $i 'VACUUM;';
	/system/xbin/sqlite3 $i 'REINDEX;';
done;

for i in \
`busybox find /sdcard -iname "*.db"`; 
do \
	/system/xbin/sqlite3 $i 'VACUUM;';
	/system/xbin/sqlite3 $i 'REINDEX;';
done;

