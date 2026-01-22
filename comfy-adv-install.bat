@echo off&&cd /d "%~dp0"

Title The 3-Minute Node ComfyUI Advanced Installer v0.4 260122
:: The 3-Minute Node Community Edition

setlocal enabledelayedexpansion

call :set_colors

set "PYTHON_URL=https://www.python.org/ftp/python/3.13.9/python-3.13.9-embed-amd64.zip"
set "TRITON_LIBS_URL=https://github.com/woct0rdho/triton-windows/releases/download/v3.0.0-windows.post1/python_3.13.2_include_libs.zip"
set "EMBED_DIR=%~dp0python_embeded"
set "COMFY_DIR=%~dp0ComfyUI"
set "PYTHON_EXE=%EMBED_DIR%\python.exe"
set "PIP_INDEX=--extra-index-url=https://download.pytorch.org/whl/cu130"
set "PIP_OPTS=--no-cache-dir --no-warn-script-location --timeout=1000 --prefer-binary"

:: Prerequisites Check
where git >nul 2>nul || (echo %RED%[+] Git not found. Please install Git for Windows.%RESET% && pause && exit /b)
where curl >nul 2>nul || (echo %RED%[+] Curl not found. Update your Windows or install Curl.%RESET% && pause && exit /b)

echo %CYAN%[+] Creating Directories...%RESET%
if not exist "%EMBED_DIR%" mkdir "%EMBED_DIR%"

echo %CYAN%[+] Downloading Python 3.13 Embeddable...%RESET%
if not exist "python_embed.zip" curl --ssl-no-revoke -L -o python_embed.zip %PYTHON_URL%

echo %CYAN%[+] Extracting Python...%RESET%
powershell -Command "Expand-Archive -Path 'python_embed.zip' -DestinationPath '%EMBED_DIR%' -Force"
del python_embed.zip

echo %CYAN%[+] Handling Python Include/Libs...%RESET%
echo %CYAN%[+] Downloading 3.13.2 headers/libs for Triton...%RESET%
curl --ssl-no-revoke -L -o "python_libs.zip" %TRITON_LIBS_URL%
echo %CYAN%[+] Merging headers and libraries into %EMBED_DIR%...
powershell -Command "Expand-Archive -Path 'python_libs.zip' -DestinationPath '%EMBED_DIR%' -Force"
del python_libs.zip

echo %CYAN%[+] Configuring Python Paths...%RESET%
powershell -Command "(Get-Content '%EMBED_DIR%\python313._pth') -replace '#import site', 'import site' | Set-Content '%EMBED_DIR%\python313._pth'"
powershell -Command "$content = Get-Content '%EMBED_DIR%\python313._pth'; '../ComfyUI', $content | Set-Content '%EMBED_DIR%\python313._pth'"

echo %CYAN%[+] Downloading pip...%RESET%
curl --ssl-no-revoke -L -o "%EMBED_DIR%\get-pip.py" https://bootstrap.pypa.io/get-pip.py
"%PYTHON_EXE%" "%EMBED_DIR%\get-pip.py" --no-warn-script-location
del "%EMBED_DIR%\get-pip.py"

echo %CYAN%[+] Cloning ComfyUI...%RESET%
if not exist "%COMFY_DIR%" git clone https://github.com/comfyanonymous/ComfyUI.git "%COMFY_DIR%"

echo %CYAN%[+] Installing ComfyUI Base Dependencies...%RESET%
"%PYTHON_EXE%" -m pip install -r "%COMFY_DIR%\requirements.txt" %PIP_OPTS%

echo %CYAN%[+] Installing LOCKED PyTorch CUDA 13.0 (Working Version)...%RESET%
"%PYTHON_EXE%" -m pip install torch==2.9.1+cu130 torchvision==0.24.1+cu130 torchaudio==2.9.1+cu130 --force-reinstall %PIP_INDEX% %PIP_OPTS%
:: "%PYTHON_EXE%" -m pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu130

echo %CYAN%[+] Installing Specialized Dependencies...%RESET%
echo %CYAN%[+] Installing Insightface...%RESET%
"%PYTHON_EXE%" -m pip install https://github.com/Gourieff/Assets/raw/main/Insightface/insightface-0.7.3-cp313-cp313-win_amd64.whl %PIP_OPTS%

echo %CYAN%[+] Installing Kokoro-ONNX...%RESET%
"%PYTHON_EXE%" -m pip install kokoro-onnx==0.4.4 %PIP_OPTS%

echo %CYAN%[+] Installing Triton for Windows...%RESET%
"%PYTHON_EXE%" -m pip install triton-windows==3.5.1.post24 %PIP_OPTS%

echo %CYAN%[+] Installing SageAttention...%RESET%
"%PYTHON_EXE%" -m pip install https://github.com/woct0rdho/SageAttention/releases/download/v2.2.0-windows.post4/sageattention-2.2.0+cu130torch2.9.0andhigher.post4-cp39-abi3-win_amd64.whl %PIP_OPTS%

echo %CYAN%[+] Installing Custom Nodes...%RESET%
set "NODES=https://github.com/ltdrdata/ComfyUI-Manager https://github.com/rgthree/rgthree-comfy https://github.com/yolain/ComfyUI-Easy-Use https://github.com/kijai/ComfyUI-KJNodes https://github.com/crystian/ComfyUI-Crystools https://github.com/city96/ComfyUI-GGUF https://github.com/Fannovel16/comfyui_controlnet_aux https://github.com/ltdrdata/ComfyUI-Impact-Pack https://github.com/ltdrdata/ComfyUI-Impact-Subpack https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler https://github.com/cubiq/ComfyUI_IPAdapter_plus https://github.com/stavsap/comfyui-kokoro"

cd /d "%COMFY_DIR%\custom_nodes"
for %%i in (%NODES%) do (
    set "URL=%%i"
    for /f "delims=" %%a in ("%%i") do set "FOLDER_NAME=%%~na"
    echo.
    echo %GREEN%[+] Processing: !FOLDER_NAME!%RESET%
    if not exist "!FOLDER_NAME!" (
        git clone !URL!
    )
    if exist "!FOLDER_NAME!\requirements.txt" (
		if "!FOLDER_NAME!"=="comfyui-kokoro" (
            echo %YELLOW%[+] Skipping requirements for comfyui-kokoro%RESET%
        ) else (
            echo %GREEN%[+] Installing requirements for !FOLDER_NAME!...%RESET%
            "%PYTHON_EXE%" -m pip install -r "!FOLDER_NAME!\requirements.txt" %PIP_INDEX% %PIP_OPTS%
        )
    )
)

cd /d "%~dp0"

echo.
echo %CYAN%[+] Forcing final NumPy version 2.3.5...%RESET%
"%PYTHON_EXE%" -m pip install numpy==2.3.5 --force-reinstall %PIP_OPTS%

echo.
echo %CYAN%[+] Making run.bat...%RESET%
(
echo @echo off
echo python_embeded\python.exe -s ComfyUI\main.py --windows-standalone-build --disable-api-nodes --use-sage-attention
echo pause
) > run.bat

echo.
echo %CYAN%[+] Making update.bat...%RESET%
(
echo @echo off
echo cd /d "%%~dp0ComfyUI"
echo echo [+] Pulling latest ComfyUI...
echo git fetch --all
echo git reset --hard origin/master
echo echo [+] Updating requirements...
echo ..\python_embeded\python.exe -m pip install -r requirements.txt --no-cache-dir --no-warn-script-location --timeout=1000 --prefer-binary
echo echo [+] Done.
echo pause
) > update.bat

:: extra model paths setup
echo.
echo %CYAN%[+] Would you like to link an existing ComfyUI model folder?%RESET%
set /p "LINK_MODELS=Enter 'y' for Yes or press Enter to skip:"

if /i "%LINK_MODELS%"=="y" (
    echo %GREEN%[+] Opening folder picker... please select your MODEL root folder.%RESET%

    :: Use PowerShell to open a Folder Selection Dialog
    for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description = 'Select your existing Model Folder (contains checkpoints, loras, etc)'; if($f.ShowDialog() -eq 'OK'){ $f.SelectedPath } "`) do set "USER_PATH=%%I"

    if defined USER_PATH (
        echo %GREEN%[+] Path selected: !USER_PATH!%RESET%

        :: Create the YAML file. We use forward slashes to avoid escape issues in YAML.
        set "ESCAPED_PATH=!USER_PATH:\=/!"

        (
			echo comfyui:
			echo     base_path: !ESCAPED_PATH!
			echo     is_default: true
			echo     audio_encoders: audio_encoders
			echo     checkpoints: checkpoints
			echo     clip: clip
			echo     clip_vision: clip_vision
			echo     configs: configs
			echo     controlnet: controlnet
			echo     diffusers: diffusers
			echo     diffusion_models: diffusion_models
			echo     embeddings: embeddings
			echo     gligen: gligen
			echo     hypernetworks: hypernetworks
			echo     latent_upscale_models: latent_upscale_models
			echo     loras: loras
			echo     model_patches: model_patches
			echo     photomaker: photomaker
			echo     style_models: style_models
			echo     text_encoders: text_encoders
			echo     unet: unet
			echo     upscale_models: upscale_models
			echo     vae: vae
			echo     vae_approx: vae_approx
			echo     vibevoice: vibevoice
			echo     ipadapter: ipadapter
			echo     insightface: insightface
			echo     LLM: LLM
			echo     sams: sams
			echo     sam2: sam2
			echo     SEEDVR2: SEEDVR2
			echo     ultralytics: ultralytics
			echo     wav2vec2: wav2vec2
        ) > "%COMFY_DIR%\extra_model_paths.yaml"

        echo %GREEN%[+] extra_model_paths.yaml created successfully.%RESET%
    ) else (
        echo %YELLOW%[+] No folder selected. Skipping...%RESET%
    )
)

echo.
echo %CYAN%[+] Setup Complete.%RESET%
echo %CYAN%[+] Start: python_embeded\python.exe -s ComfyUI\main.py --windows-standalone-build%RESET%
pause
exit /b

:: subroutines

:set_colors
for /f "delims=" %%a in ('powershell -command "[char]27"') do set "ESC=%%a"
set "RESET=%ESC%[0m"
set "GREEN=%ESC%[92m"
set "CYAN=%ESC%[96m"
set "RED=%ESC%[91m"
set "YELLOW=%ESC%[93m"
exit /b
