#!/sbin/busybox sh

#
# Sample touch gesture actions by Tungstwenty - forum.xda-developers.com
# Modded by GM and dorimanx.

(
echo "
# Gesture 1 - swipe 1 finger near the top and one near the bottom from left to right
1:1:(0|150,0|150)
1:1:(330|480,0|150)
1:2:(0|150,650|800)
1:2:(330|480,650|800)

# Gesture 2 - swipe 3 fingers from near the top to near the bottom
2:1:(0|480,0|200)2:1:(0|480,600|800)
2:2:(0|480,0|200)2:2:(0|480,600|800)
2:3:(0|480,0|200)2:3:(0|480,600|800)

# Gesture 3 - draw a Z with one finger while another is pressed on the middle left
3:1:(0|150,0|150)
3:1:(330|480,0|150)
3:1:(0|150,650|800)
3:1:(330|480,650|800)

3:2:(0|150,300|500)

# Gesture 4 draw a heart starting at middle lower part of the screen
4:1:(200|280,699|799)
4:1:(0|150,300|500)
4:1:(200|280,300|500)
4:1:(330|480,300|500)
4:1:(200|280,699|799)

# Gesture 5 swipe 3 fingers from near the bottom to the top
5:1:(0|480,600|800)5:1:(0|480,0|200)
5:2:(0|480,600|800)5:2:(0|480,0|200)
5:3:(0|480,600|800)5:3:(0|480,0|200)

" > /sys/devices/virtual/misc/touch_gestures/gesture_patterns
)&

(while [ 1 ];
do

	GESTURE=`cat /sys/devices/virtual/misc/touch_gestures/wait_for_gesture`
	
	if [ "$GESTURE" -eq "1" ]; then
	
	mdnie_status=`cat /sys/class/mdnie/mdnie/negative`
	if [ "$mdnie_status" -eq "0" ]; then
		echo 1 > /sys/class/mdnie/mdnie/negative
	else
		echo 0 > /sys/class/mdnie/mdnie/negative
	fi;

	elif [ "$GESTURE" -eq "2" ]; then

		# Power down the screen, for 4.0.3 or 4.0.4 ONLY.
		key=26; service call window 12 i32 1 i32 1 i32 5 i32 0 i32 0 i32 $key i32 0 i32 0 i32 0 i32 8 i32 0 i32 0 i32 0 i32 0; service call window 12 i32 1 i32 1 i32 5 i32 0 i32 1 i32 $key i32 0 i32 0 i32 27 i32 8 i32 0 i32 0 i32 0 i32 0
		
	elif [ "$GESTURE" -eq "3" ]; then
	
		# Start the extweaks
		am start -a android.intent.action.MAIN -n com.darekxan.extweaks.app/.ExTweaksActivity

	elif [ "$GESTURE" -eq "4" ]; then

		echo "if blank GESTURE dont remove me."  > /dev/null 2>&1

		# Edit and uncomment the next line to automatically start a call to the target number
		# WARNING / BONUS: This will work even in the lockscreen with a PIN protection
		# When you ready to add some phone, remove the # before service call...

		#service call phone 2 s16 "your girl number"

	elif [ "$GESTURE" -eq "5" ]; then

		# Start Camera APP
		# for CM10
		am start --activity-exclude-from-recents com.sec.android.app.camera

		# For 4.0.3 or 4.0.4
		am start --activity-exclude-from-recents com.android.camera/.Camera

	fi;

done &);

