# VideoEditorTranscribe

REM ==============================================================

REM Batch Script for Video Processing and Splitting

REM --------------------------------------------------------------

REM This script processes all .mp4 files in the current directory.

REM It performs the following tasks:

REM 1. Extracts only capital letters and numbers from the filename.

REM    - If the extracted filename is a single capital letter, the original filename is used.

REM 2. Converts all videos to a resolution of 320x180.

REM 3. If the video is less than 1 hour long, it is converted without splitting.

REM 4. If the video is 1 hour or longer:

REM    - It is split into **equal parts**, ensuring all parts are the same length.

REM    - Each segment is at most 50 minutes (3000 seconds) long.

REM    - The last segment is adjusted to maintain equal segment lengths.

REM 5. The processed videos are stored in the "low_res" folder.

REM ==============================================================
