@echo off&&cd /d "%~dp0"

Title The 3-Minute Node ComfyUI IPAdapter Downloader v0.1 260122
:: The 3-Minute Node Community Edition

setlocal enabledelayedexpansion

call :set_colors

:: --- STORAGE WARNING ---
echo %RED%===========================================================%RESET%
echo %YELLOW%                     STORAGE WARNING%RESET%
echo %RED%===========================================================%RESET%
echo This script will download approximately %GREEN%15GB%RESET% of models.
echo Please ensure you have enough disk space on this drive.
echo.
echo Press any key to start the download, or close this window to cancel.
pause >nul
echo.

:: Create the base directory structure
set "MODELS=ComfyUI\models"
if not exist "%MODELS%" mkdir "%MODELS%"
if not exist "%MODELS%\clip_vision" mkdir "%MODELS%\clip_vision"
if not exist "%MODELS%\ipadapter" mkdir "%MODELS%\ipadapter"
if not exist "%MODELS%\loras" mkdir "%MODELS%\loras"

echo %CYAN%[1/3] Downloading CLIP Vision models...%RESET%
call :download "https://huggingface.co/h94/IP-Adapter/resolve/main/models/image_encoder/model.safetensors" "%MODELS%\clip_vision\CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors"
call :download "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/image_encoder/model.safetensors" "%MODELS%\clip_vision\CLIP-ViT-bigG-14-laion2B-39B-b160k.safetensors"

echo %CYAN%[2/3] Downloading IPAdapter models...%RESET%
:: SD1.5
:: Basic model, average strength
call :download "https://huggingface.co/h94/IP-Adapter/resolve/main/models/ip-adapter_sd15.safetensors" "%MODELS%\ipadapter\ip-adapter_sd15.safetensors"
:: Light impact model
call :download "https://huggingface.co/h94/IP-Adapter/resolve/main/models/ip-adapter_sd15_light_v11.bin" "%MODELS%\ipadapter\ip-adapter_sd15_light_v11.bin"
:: Plus model, very strong
call :download "https://huggingface.co/h94/IP-Adapter/resolve/main/models/ip-adapter-plus_sd15.safetensors" "%MODELS%\ipadapter\ip-adapter-plus_sd15.safetensors"
:: Face model, portraits
call :download "https://huggingface.co/h94/IP-Adapter/resolve/main/models/ip-adapter-plus-face_sd15.safetensors" "%MODELS%\ipadapter\ip-adapter-plus-face_sd15.safetensors"
:: Stronger face model, not necessarily better
call :download "https://huggingface.co/h94/IP-Adapter/resolve/main/models/ip-adapter-full-face_sd15.safetensors" "%MODELS%\ipadapter\ip-adapter-full-face_sd15.safetensors"
:: Base model, requires bigG clip vision encoder
call :download "https://huggingface.co/h94/IP-Adapter/resolve/main/models/ip-adapter_sd15_vit-G.safetensors" "%MODELS%\ipadapter\ip-adapter_sd15_vit-G.safetensors"

:: SDXL
:: Base model
call :download "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter_sdxl_vit-h.safetensors" "%MODELS%\ipadapter\ip-adapter_sdxl_vit-h.safetensors"
:: SDXL plus model
call :download "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter-plus_sdxl_vit-h.safetensors" "%MODELS%\ipadapter\ip-adapter-plus_sdxl_vit-h.safetensors"
:: SDXL face model
call :download "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter-plus-face_sdxl_vit-h.safetensors" "%MODELS%\ipadapter\ip-adapter-plus-face_sdxl_vit-h.safetensors"
:: vit-G SDXL model, requires bigG clip vision encoder
call :download "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter_sdxl.safetensors" "%MODELS%\ipadapter\ip-adapter_sdxl.safetensors"

:: FaceID
:: base FaceID model
call :download "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid_sd15.bin" "%MODELS%\ipadapter\ip-adapter-faceid_sd15.bin"
:: FaceID plus v2
call :download "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-plusv2_sd15.bin" "%MODELS%\ipadapter\ip-adapter-faceid-plusv2_sd15.bin"
:: text prompt style transfer for portraits
call :download "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-portrait-v11_sd15.bin" "%MODELS%\ipadapter\ip-adapter-faceid-portrait-v11_sd15.bin"
:: SDXL base FaceID
call :download "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid_sdxl.bin" "%MODELS%\ipadapter\ip-adapter-faceid_sdxl.bin"
:: SDXL plus v2
call :download "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-plusv2_sdxl.bin" "%MODELS%\ipadapter\ip-adapter-faceid-plusv2_sdxl.bin"
:: SDXL text prompt style transfer
call :download "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-portrait_sdxl.bin" "%MODELS%\ipadapter\ip-adapter-faceid-portrait_sdxl.bin"
:: very strong style transfer SDXL only
call :download "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-portrait_sdxl_unnorm.bin" "%MODELS%\ipadapter\ip-adapter-faceid-portrait_sdxl_unnorm.bin"

echo %CYAN%[3/3] Downloading LoRAs...%RESET%
call :download "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid_sd15_lora.safetensors" "%MODELS%\loras\ip-adapter-faceid_sd15_lora.safetensors"
call :download "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-plusv2_sd15_lora.safetensors" "%MODELS%\loras\ip-adapter-faceid-plusv2_sd15_lora.safetensors"
:: SDXL FaceID LoRA
call :download "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid_sdxl_lora.safetensors" "%MODELS%\loras\ip-adapter-faceid_sdxl_lora.safetensors"
:: SDXL plus v2 LoRA
call :download "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-plusv2_sdxl_lora.safetensors" "%MODELS%\loras\ip-adapter-faceid-plusv2_sdxl_lora.safetensors"

echo %CYAN%All downloads complete.%RESET%
pause
exit /b

:: --- SUBROUTINES ---

:set_colors
for /f "delims=" %%a in ('powershell -command "[char]27"') do set "ESC=%%a"
set "RESET=%ESC%[0m"
set "GREEN=%ESC%[92m"
set "CYAN=%ESC%[96m"
set "RED=%ESC%[91m"
set "YELLOW=%ESC%[93m"
exit /b

:download
if not exist "%~2" (
    echo %GREEN%Downloading %~2...%RESET%
    :: Added -# for progress bar and -f to fail quietly on 404s
    curl --ssl-no-revoke -f -L -# "%~1" -o "%~2"
) else (
    echo %YELLOW%%~2 already exists, skipping.%RESET%
)
exit /b
