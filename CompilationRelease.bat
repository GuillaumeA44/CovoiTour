@echo off
setlocal EnableExtensions

set "FLUTTER_COMMAND=flutter"
set "ADB_PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"

where "%FLUTTER_COMMAND%" >nul 2>&1
if errorlevel 1 (
    echo [ERREUR] Flutter est introuvable dans le PATH.
    echo Installez Flutter puis relancez ce script.
    pause
    exit /b 1
)

if not exist "%ADB_PATH%" (
    echo [AVERTISSEMENT] ADB introuvable : %ADB_PATH%
    echo La compilation peut continuer, mais le transfert USB ne sera pas disponible.
)

echo [1/3] Verification de l'environnement Flutter...
call flutter doctor -v
if errorlevel 1 (
    echo [ERREUR] flutter doctor a signale un probleme bloquant.
    pause
    exit /b 1
)

echo [2/3] Recuperation des dependances...
call flutter pub get
if errorlevel 1 (
    echo [ERREUR] flutter pub get a echoue.
    pause
    exit /b 1
)

echo [3/3] Compilation de l'APK release...
call flutter build apk --release %*
if errorlevel 1 (
    echo [ECHEC] La compilation a echoue.
    exit /b 1
)

echo.
echo [SUCCES] Compilation terminee !
echo APK: build\app\outputs\flutter-apk\app-release.apk
pause
