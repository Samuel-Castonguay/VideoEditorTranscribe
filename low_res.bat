@ECHO OFF
chcp 65001
setlocal EnableDelayedExpansion
ECHO.

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
REM    - It is split into **equal parts**, ensuring all parts are nearly the same length.
REM    - Each segment is at most 59 minutes (3540 seconds) long.
REM    - If the last segment is too short, the segment length is adjusted to avoid very short clips.
REM 5. The processed videos are stored in the "low_res" folder.
REM ==============================================================

mkdir "low_res" 2>nul

REM Check if there are any .mp4 files in the folder
dir /b *.mp4 >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    ECHO No .mp4 files found. Exiting...
    PAUSE
    EXIT /B
)

for %%A in (*.mp4) do (
    REM Debug: Show which file is being processed
    ECHO Processing: "%%A"

    REM Extract filename without extension
    set "FILENAME=%%~nA"

    REM Initialize modified filename
    set "NEWNAME="

    REM Extract only capital letters and numbers from the filename
    for /L %%I in (0,1,255) do (
        set "CHAR=!FILENAME:~%%I,1!"
        for %%J in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9) do (
            if "!CHAR!"=="%%J" set "NEWNAME=!NEWNAME!!CHAR!"
        )
    )

    REM If the NEWNAME contains only one capital letter, revert to the original filename
    if defined NEWNAME (
        set "CHECK=!NEWNAME!"
        set "LENGTH=0"

        REM Count number of characters in NEWNAME
        for /L %%I in (0,1,255) do (
            if not "!CHECK:~%%I,1!"=="" set /A LENGTH+=1
        )

        if !LENGTH! LEQ 1 set "NEWNAME=!FILENAME!"
    ) else (
        set "NEWNAME=!FILENAME!"
    )

    REM Ensure output filename is never empty
    if not defined NEWNAME set "NEWNAME=UNKNOWN"

    REM Debug: Show new filename
    ECHO Adjusted filename: "!NEWNAME!"

    REM Ensure DURATION_RAW is cleared before use
    set "DURATION_RAW="

    REM Write ffprobe output to a temporary file
    ffprobe -i "%%A" -show_entries format=duration -v quiet -of csv=p=0 2>nul > temp_duration.txt

    REM Read the duration from the file
    set /p DURATION_RAW=<temp_duration.txt

    REM Delete the temp file
    del temp_duration.txt

    REM Debug: Show raw duration
    ECHO Raw duration for "%%A": "!DURATION_RAW!"

    REM Check if DURATION_RAW is empty
    if defined DURATION_RAW (
        REM Remove decimal part and convert to integer
        for /f "tokens=1 delims=." %%D in ("!DURATION_RAW!") do set /A DURATION=%%D

        REM Debug: Show processed duration
        ECHO Retrieved duration for "%%A": !DURATION! seconds

        REM Ensure duration is valid
        if !DURATION! GTR 0 (
            REM If video is shorter than 1 hour, convert without splitting
            if !DURATION! LSS 3600 (
                ECHO Video is less than 1 hour, converting without splitting...
                ffmpeg -i "%%A" -vf scale=320:180 -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k -y "low_res/!NEWNAME!.mp4"
            ) else (
                REM Define maximum segment length (3540 seconds)
                set /A MAX_SEGMENT_LENGTH=3540
                
                REM Calculate number of equal segments
                set /A NUM_SEGMENTS=!DURATION! / MAX_SEGMENT_LENGTH
                set /A REMAINDER=!DURATION! %% MAX_SEGMENT_LENGTH

                REM If there’s a remainder, increase the number of segments
                if !REMAINDER! GTR 0 set /A NUM_SEGMENTS+=1

                REM Adjust segment length to ensure the last part isn't too short
                set /A SEGMENT_LENGTH=!DURATION! / !NUM_SEGMENTS!

                REM Ensure the last segment is at least 80% of the other segments
                set /A LAST_SEGMENT_LENGTH=!DURATION! - (SEGMENT_LENGTH * (!NUM_SEGMENTS!-1))
                set /A MIN_LAST_SEGMENT=!SEGMENT_LENGTH! * 80 / 100

                if !LAST_SEGMENT_LENGTH! LSS !MIN_LAST_SEGMENT! (
                    set /A SEGMENT_LENGTH=!DURATION! / (!NUM_SEGMENTS!-1)
                    set /A NUM_SEGMENTS-=1
                )

                ECHO Splitting "%%A" into !NUM_SEGMENTS! equal parts of !SEGMENT_LENGTH! seconds each

                REM Split video into equal parts
                for /L %%I in (0,1,!NUM_SEGMENTS!-1) do (
                    set /A START_TIME=%%I * SEGMENT_LENGTH

                    ECHO Creating segment %%I with duration !SEGMENT_LENGTH! seconds
                    ffmpeg -i "%%A" -vf scale=320:180 -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k -ss !START_TIME! -t !SEGMENT_LENGTH! -reset_timestamps 1 "low_res/!NEWNAME!_%%I.mp4"
                )
            )
        ) else (
            ECHO ERROR: Invalid duration for "%%A". Skipping...
        )
    ) else (
        ECHO ERROR: Could not retrieve duration for "%%A". Skipping...
    )
)

ECHO.
ECHO All videos have been successfully processed!
PAUSE
EXIT /B
