#!/sbin/busybox sh
# universal configurator interface for user/dev/ testing.
# by Gokhan Moral and Voku and Dorimanx and Alucard24

# stop uci.sh from running all the PUSH Buttons in stweaks on boot
mount -o remount,rw rootfs;
chown -R root:system /res/customconfig/actions/;
chmod -R 6755 /res/customconfig/actions/;
mv /res/customconfig/actions/push-actions/* /res/no-push-on-boot/;
chmod 6755 /res/no-push-on-boot/*;

UCI_PID=`pgrep "user_uci_test_run.sh"`;
renice -n -15 -p $UCI_PID;

ACTION_SCRIPTS=/res/customconfig/actions;
source /res/customconfig/customconfig-helper;

# first, read defaults
read_defaults;

# read the config from the active profile
read_config;
apply_config;
write_config;

# restore all the PUSH Button Actions back to there location
mount -o remount,rw rootfs;
mv /res/no-push-on-boot/* /res/customconfig/actions/push-actions/;
pkill -f "com.gokhanmoral.stweaks.app";
am start -a android.intent.action.MAIN -n com.gokhanmoral.stweaks.app/.MainActivity;
