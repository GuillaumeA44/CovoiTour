@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ADB_PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
set "APK_PATH=%~dp0build\app\outputs\flutter-apk\app-release.apk"
set "PACKAGE_NAME=com.covoitour.covoi_tour"
set "CLEAN_INSTALL=0"

if /I "%~1"=="--clean" set "CLEAN_INSTALL=1"
if /I "%~1"=="clean" set "CLEAN_INSTALL=1"

if not exist "%ADB_PATH%" (
    echo [ERREUR] ADB introuvable : %ADB_PATH%
    echo Activez le debogage USB et adaptez ADB_PATH si necessaire.
    pause
    exit /b 1
)

if not exist "%APK_PATH%" (
    echo [ERREUR] APK release introuvable : %APK_PATH%
    echo Lancez d'abord CompilationRelease.bat.
    pause
    exit /b 1
)

echo [1/2] Appareils Android connectes...
"%ADB_PATH%" devices

if "%CLEAN_INSTALL%"=="1" (
    echo [INFO] Desinstallation de la version precedente...
    "%ADB_PATH%" uninstall "%PACKAGE_NAME%" >nul 2>&1
)

echo [2/2] Installation de l'APK release...
"%ADB_PATH%" install -r "%APK_PATH%"
if errorlevel 1 (
    echo [ECHEC] Installation impossible.
    echo Verifiez le debogage USB et l'autorisation RSA sur le telephone.
    pause
    exit /b 1
)

echo [SUCCES] CovoiTour est installe sur le telephone.
pause
