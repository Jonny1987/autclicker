#!/bin/bash
convert -resize 400%  $1 _1.png
convert -threshold $2% _1.png _2.png
convert -resample 300 _2.png _3.png
convert -resize 25% _3.png _.png
tesseract --psm 7 _.png _ &> /dev/null
echo "$(head -n 1 _.txt)" 
