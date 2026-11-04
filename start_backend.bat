@echo off
start "MongoDB Server" "C:\Program Files\MongoDB\Server\8.0\bin\mongod.exe" --dbpath "D:\OFFICEWORKS\Course_APP\qr_registration_app\backend\data"
timeout /t 2 /nobreak >nul
cd /d "D:\OFFICEWORKS\Course_APP\qr_registration_app\backend"
start "Notes Backend Server" node server.js

