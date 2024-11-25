@echo off
title Steam Backup Script

:: Configuration
:: To get your Steam API key:
:: 1. Visit: https://steamcommunity.com/dev/apikey
:: 2. Log in with your Steam account
:: 3. Enter a domain name (can be anything if for personal use)
:: 4. Your API key will be generated and displayed
set "STEAM_API_KEY="
set "STEAM_USERNAME="
set "STEAM_DIR=C:\Program Files (x86)\Steam"
set "BACKUP_DIR=%USERPROFILE%\steam_backups"
set "TIMESTAMP=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "TIMESTAMP=%TIMESTAMP: =0%"

echo Steam Backup Script
echo ==========================================
echo.

:: Get Steam ID using API
echo Fetching Steam ID for user: %STEAM_USERNAME%
curl -s "http://api.steampowered.com/ISteamUser/ResolveVanityURL/v0001/?key=%STEAM_API_KEY%&vanityurl=%STEAM_USERNAME%" > steam_id.json

:: Parse Steam ID
for /f %%i in ('powershell -Command "$json = Get-Content steam_id.json | ConvertFrom-Json; $steamId = $json.response.steamid; $localId = [bigint]$steamId - 76561197960265728; Write-Output $localId"') do set "LOCAL_ID=%%i"
del steam_id.json

if "%LOCAL_ID%"=="" (
    echo Error: Could not find Steam ID for username %STEAM_USERNAME%
    pause
    exit /b 1
)

echo Found user: %STEAM_USERNAME%
echo Local ID: %LOCAL_ID%
echo.

set "BACKUP_FULL_PATH=%BACKUP_DIR%\backup_%TIMESTAMP%_%STEAM_USERNAME%_%LOCAL_ID%"

echo Creating backup directories...
if not exist "%BACKUP_FULL_PATH%" (
    mkdir "%BACKUP_FULL_PATH%\clientui"
    mkdir "%BACKUP_FULL_PATH%\config"
    mkdir "%BACKUP_FULL_PATH%\userdata"
    mkdir "%BACKUP_FULL_PATH%\skins"
    mkdir "%BACKUP_FULL_PATH%\cloud_saves"
    echo Created directory structure at: %BACKUP_FULL_PATH%
) else (
    echo Backup directory already exists!
)
echo.

echo Backing up Steam files...
echo ==========================================

echo Backing up Client UI preferences...
xcopy "%STEAM_DIR%\clientui\*" "%BACKUP_FULL_PATH%\clientui\" /E /H /I /Y
if errorlevel 1 (
    echo Warning: Some Client UI files could not be copied
) else (
    echo Client UI backup complete
)
echo.

echo Backing up Global Steam configs...
xcopy "%STEAM_DIR%\config\config.vdf" "%BACKUP_FULL_PATH%\config\" /H /I /Y
xcopy "%STEAM_DIR%\config\loginusers.vdf" "%BACKUP_FULL_PATH%\config\" /H /I /Y
xcopy "%STEAM_DIR%\config\dialogconfig.vdf" "%BACKUP_FULL_PATH%\config\" /H /I /Y
if errorlevel 1 (
    echo Warning: Some config files could not be copied
) else (
    echo Global configs backup complete
)
echo.

echo Backing up User Data...
xcopy "%STEAM_DIR%\userdata\%LOCAL_ID%\config\localconfig.vdf" "%BACKUP_FULL_PATH%\userdata\" /H /I /Y
xcopy "%STEAM_DIR%\userdata\%LOCAL_ID%\7\remote\sharedconfig.vdf" "%BACKUP_FULL_PATH%\userdata\" /H /I /Y
xcopy "%STEAM_DIR%\userdata\%LOCAL_ID%\760\screenshots.vdf" "%BACKUP_FULL_PATH%\userdata\" /H /I /Y
xcopy "%STEAM_DIR%\userdata\%LOCAL_ID%\config\shortcuts.vdf" "%BACKUP_FULL_PATH%\userdata\" /H /I /Y
xcopy "%STEAM_DIR%\userdata\%LOCAL_ID%\241100" "%BACKUP_FULL_PATH%\userdata\241100\" /E /H /I /Y
xcopy "%STEAM_DIR%\userdata\%LOCAL_ID%\config\controller_configs" "%BACKUP_FULL_PATH%\userdata\controller_configs\" /E /H /I /Y
xcopy "%STEAM_DIR%\userdata\%LOCAL_ID%\7\remote" "%BACKUP_FULL_PATH%\userdata\collections\" /E /H /I /Y
if errorlevel 1 (
    echo Warning: Some user data files could not be copied
) else (
    echo User data backup complete
)
echo.

echo Backing up Steam Skins...
xcopy "%STEAM_DIR%\skins\*" "%BACKUP_FULL_PATH%\skins\" /E /H /I /Y
if errorlevel 1 (
    echo Warning: Some skin files could not be copied
) else (
    echo Skins backup complete
)
echo.

echo Backing up Cloud Saves...
xcopy "%STEAM_DIR%\userdata\%LOCAL_ID%\*\remote\*" "%BACKUP_FULL_PATH%\cloud_saves\" /E /H /I /Y
if errorlevel 1 (
    echo Warning: Some cloud save files could not be copied
) else (
    echo Cloud saves backup complete
)
echo.

echo ==========================================
echo Backup completed successfully!
echo.
echo Files saved to: %BACKUP_FULL_PATH%
echo.
echo Press any key to exit...
pause >nul