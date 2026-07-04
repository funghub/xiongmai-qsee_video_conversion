#!/bin/bash

echo "Converting files (ffmpeg framerate -r 25)"
find . -type f -name "*.mp4" ! -name "*-output.mp4" -print0 | \
xargs -0 -n 1 -I {} sh -c 'ffmpeg -y -r 25 -f h264 -i "$1" -c copy "${1%.mp4}-output.mp4" < /dev/null' _ {}
echo "Finished converting files (ffmpeg framerate -r 25)"

echo "Combining output files into one list for combining all videos"
for f in *-output.mp4; do echo "file '$PWD/$f'"; done | sort > filelist.txt \
echo "Finished combining output files into one list for combining all videos"

echo "Combining all videos"
ffmpeg -f concat -safe 0 -i filelist.txt -c copy combined.mp4
echo "Finished combining all videos"

echo "Remove *-output.mp4 intermediate files"
rm -f -- *-output.mp4
echo "Finished Removing *-output.mp4 intermediate files"

echo "Conversion Finished"
