#!/sbin/busybox sh
# universal configurator interface
# by Gokhan Moral

# You probably won't need to modify this file
# You'll need to modify the files in /res/customconfig directory

. /res/customconfig/actions/${1} ${1} ${2} ${3} ${4} ${5} ${6};
