@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ADB_PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
set "APK_PATH=%~dp0build\app\outputs\flutter-apk\app-release.apk"
set "PACKAGE_NAME=com.covoitour.covoi_tour"
set "CLEAN_INSTALL=0"

if /I "%~1"=="--clean" set "CLEAN_INSTALL=1"
if /I "%~1"=="clean" set "CLEAN_INSTALL=1"

if not exist "%ADB_PATH%" (
    echo [ERREUR] ADB non trouve : %ADB_PATH%
    echo Modifiez ADB_PATH dans ce script si besoin.
    pause
    exit /b 1
)

if not exist "%APK_PATH%" (
    echo [ERREUR] APK release non trouve : %APK_PATH%
    echo Lancez d'abord CompilationRelease.bat.
    pause
    exit /b 1
)

echo [1/3] Appareils Android connectes :
"%ADB_PATH%" devices

if "%CLEAN_INSTALL%"=="1" (
    echo [2/3] Suppression de l'application et de ses donnees...
    "%ADB_PATH%" uninstall "%PACKAGE_NAME%" >nul 2>&1
) else (
    echo [2/3] Installation par-dessus la version existante...
)

echo [3/3] Installation de l'APK release...
"%ADB_PATH%" install -r "%APK_PATH%"
if errorlevel 1 (
    echo [ECHEC] Installation impossible. Verifiez le debogage USB et l'autorisation RSA.
    pause
    exit /b 1
)

echo [SUCCES] Installation terminee !
pause
