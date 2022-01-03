@echo off
copy script.js script.orig.js
echo Compressing...
cmd /C closurejs --js_output_file script.js script.orig.js 
del /Q script.orig.js
