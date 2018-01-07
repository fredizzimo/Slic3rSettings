@echo off
setlocal
cd /d %~dp0
call create_env.bat
python set_temperatures.py %*
