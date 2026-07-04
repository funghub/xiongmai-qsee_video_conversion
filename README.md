# Quick Start
To run as a script:

convert.sh
	
To run in a directory of the .mp4 files:

run_in_dir.txt


# Recovering and Stitching Q-See / Xiongmai NVR Recordings

If you extract an `ext4` formatted drive or SD card from a legacy **Q-See** or **Xiongmai (XM)** surveillance system / Mobile DVR, you will find raw `.mp4` video files organized neatly by date and camera channel.

However, trying to play these files directly in standard media players usually results in errors, or a 100MB video playing back in a chaotic 3-second burst.

### The Problem

These embedded platforms record raw H.264 video bytes directly to disk to preserve CPU cycles, skipping the generation of a standard container header (`moov atom`) until a file closes cleanly. Furthermore, the file system writes raw bytes at the end of files or inside indexing logs (`video_file_list`) that confuse modern media players. Because raw H.264 streams contain no native framerate data, modern players default to an astronomical playback speed (often 1200 fps), packing minutes of video into a few unwatchable seconds.

### The Solution

The bash pipeline below fixes this by recursively scanning the storage tree, forcing FFmpeg to parse the input as raw H.264 data at a proper surveillance baseline (`-r 25`), building proper file containers, sorting them chronologically, and stitching them into a unified, seamless master video track.

## Storage Directory Architecture

The recovery command can be executed from **any level** of your extracted drive directory tree (the root, inside `videoout`, or within a specific day/channel subfolder).

```text
.
├── lost+found
└── videoout
    ├── 20160205
    │   ├── channel1
    │   ├── channel2
    │   └── channel3
    └── 20160206
        ├── channel0
        ├── channel1
        ├── channel2
        └── channel3
```

## The Recovery Pipeline

Run the following command in your terminal from the folder level you wish to aggregate:

```bash
find . -type f -name "*.mp4" ! -name "*-output.mp4" -print0 | \
xargs -0 -n 1 -I {} sh -c 'ffmpeg -y -r 25 -f h264 -i "$1" -c copy "${1%.mp4}-output.mp4" < /dev/null' _ {} \
&& for f in $(find . -name "*-output.mp4" | sort); do echo "file '$PWD/${f#./}'"; done > filelist.txt \
&& ffmpeg -f concat -safe 0 -i filelist.txt -c copy combined.mp4 \
&& find . -name "*-output.mp4" -delete && rm -f filelist.txt
```

> **Note on Framerates:** This script fixes the "3-second fast forward" bug by setting `-r 25` (25 frames per second). If your original camera settings were configured differently and the video speed looks slightly unnatural, adjust `-r 25` to `-r 30` (NTSC standard) or down to `-r 15` / `-r 12` (common space-saving security framerates).

Run the following command in your terminal if you do not wish to combine/aggregate the videos into one combined file:
```bash
find . -type f -name "*.mp4" ! -name "*-output.mp4" -print0 | \
xargs -0 -n 1 -I {} sh -c 'ffmpeg -y -r 25 -f h264 -i "$1" -c copy "${1%.mp4}-output.mp4" < /dev/null' _ {}
```

## How it Works Under the Hood

1. **`find . ... -print0 | xargs -0`**: Safely crawls down your `videoout` directories recursively, completely bypassing spaces or weird character encoding native to embedded Linux filesystems.
2. **`-f h264 -i "$1" -r 25`**: Disregards the corrupt NVR wrapper, pulls the underlying raw H.264 stream, and maps it onto a proper 25fps clock timeline.
3. **`-c copy`**: Directly clones the video codecs without re-encoding. This means the entire process completes instantly without losing any video quality.
4. **`ffmpeg -f concat`**: Aggregates the newly stamped, playable target files, reads them chronologically based on their folder timestamps, and outputs a singular continuous history file named `combined.mp4`.
5. **Cleanup**: Automatically purges the intermediate temporary files to keep your drive clear of clutter.
