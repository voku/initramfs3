#/bin/bash

# Optimization script by @VUKO github

#############################################
#        howto: compress pictures
# You will need to install binary files first
# apt-get install aptitude
# aptitude install optipng pngcrush jpegoptim
#############################################

find . -iname '*.png' -exec optipng -o7 {} \;

for file in `find . -name "*.png"`;do
   echo $file;
   pngcrush -rem alla -reduce -brute "$file" tmp_img_file.png;
   mv -f tmp_img_file.png $file;
done;

find . -iname '*.jpg' -exec jpegoptim --force {} \;

echo "done, picks optimized"

