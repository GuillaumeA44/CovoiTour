@echo off
setlocal EnableExtensions

:: 1. Recherche de Flutter - Priorite aux chemins connus
set "FLUTTER_COMMAND="

if exist "C:\flutter\bin\flutter.bat" (
    set "FLUTTER_COMMAND=C:\flutter\bin\flutter.bat"
) else if exist "C:\src\flutter\bin\flutter.bat" (
    set "FLUTTER_COMMAND=C:\src\flutter\bin\flutter.bat"
) else (
    :: Si non trouve dans les chemins classiques, on cherche dans le PATH
    where flutter >nul 2>&1
    if not errorlevel 1 (
        set "FLUTTER_COMMAND=flutter"
    )
)

if "%FLUTTER_COMMAND%"=="" (
    echo [ERREUR] Flutter est introuvable.
    echo Veuillez installer Flutter dans C:\flutter ou l'ajouter a votre PATH.
    pause
    exit /b 1
)

:: 2. Recherche dynamique de l'ADB (Android Debug Bridge)
set "ADB_PATH=adb"
where %ADB_PATH% >nul 2>&1
if errorlevel 1 (
    if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
        set "ADB_PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
    ) else (
        set "ADB_PATH="
    )
)

if "%ADB_PATH%"=="" (
    echo [AVERTISSEMENT] ADB introuvable.
    echo La compilation peut continuer, mais le transfert USB automatique echouera.
)

echo [1/2] Recuperation des dependances...
call "%FLUTTER_COMMAND%" pub get
if errorlevel 1 (
    echo [ERREUR] flutter pub get a echoue.
    pause
    exit /b 1
)

echo [2/2] Compilation de l'APK release...
call "%FLUTTER_COMMAND%" build apk --release %*
if errorlevel 1 (
    echo [ECHEC] La compilation a echoue.
    exit /b 1
)

echo.
echo [SUCCES] Compilation terminee !
echo APK: build\app\outputs\flutter-apk\app-release.apk
pause
