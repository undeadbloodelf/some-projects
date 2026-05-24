# :: This dual-line prefix allows the file to be parsed as Batch on Windows and Bash on Linux
# ::: Run on Linux/macOS using: bash run.bat
# ::: Run on Windows using: Double-click run.bat
# :; @echo off
# :; goto WINDOWS

# ==============================================================================
# LINUX / MACOS SECTION
# ==============================================================================
set -e
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

echo "========================================="
echo " System: Linux/macOS                     "
echo " Checking Dependencies...               "
echo "========================================="

install_linux_deps() {
    echo "[*] Missing system packages. Requesting root privileges..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update -y && sudo apt-get install -y python3 python3-pip python3-venv ffmpeg
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y python3 python3-pip ffmpeg
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu --noconfirm python python-pip ffmpeg
    elif command -v brew &> /dev/null; then
        brew install python ffmpeg
    else
        echo "[-] Package manager not supported. Install Python3, Pip, & FFmpeg manually."
        exit 1
    fi
}

if ! command -v python3 &> /dev/null || ! command -v pip3 &> /dev/null || ! command -v ffmpeg &> /dev/null; then
    install_linux_deps
fi

if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi
source .venv/bin/activate
pip install --upgrade pip yt-dlp --quiet

python mp3converter.py

read -p "Process finished. Press [Enter] to close."
exit 0

# ==============================================================================
# WINDOWS SECTION
# ==============================================================================
:WINDOWS
cls
echo =========================================
echo  System: Windows 10/11                   
echo  Checking Dependencies...                
echo =========================================

:: 1. Check Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Python is not installed. Downloading installer...
    curl -L -o python_installer.exe https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe
    echo [*] Installing Python silently... Please wait...
    start /wait python_installer.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
    del python_installer.exe
    call RefreshEnv.cmd >nul 2>&1 || set "PATH=%PATH%;%ProgramFiles%\Python311\;%ProgramFiles%\Python311\Scripts\"
)

:: 2. Check FFmpeg
ffmpeg -version >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] FFmpeg not found. Downloading standalone builds...
    if not exist "ffmpeg.exe" (
        curl -L -o ffmpeg.zip https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip
        powershell -Command "Expand-Archive -Path ffmpeg.zip -DestinationPath temp_ffmpeg -Force"
        xcopy /y "temp_ffmpeg\ffmpeg-master-latest-win64-gpl\bin\ffmpeg.exe" . >nul
        xcopy /y "temp_ffmpeg\ffmpeg-master-latest-win64-gpl\bin\ffprobe.exe" . >nul
        del ffmpeg.zip
        rmdir /s /q temp_ffmpeg
    )
)

:: 3. Setup Virtual Environment
if not exist ".venv" (
    echo [*] Creating isolated environment (.venv)...
    python -m venv .venv
)

:: 4. Activate and install
call .venv\Scripts\activate.bat
echo [*] Updating pip and installing yt-dlp...
python -m pip install --upgrade pip --quiet
pip install --upgrade yt-dlp --quiet

echo =========================================
echo  Launching Downloader...                 
echo =========================================
echo.

python mp3converter.py

echo.
echo =========================================
pause
exit /b

