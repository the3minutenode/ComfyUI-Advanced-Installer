@echo off
cd /d "%~dp0"
title ComfyUI Advanced Installer v1.0
:: Bootstrap only: get uv, get Python, extract the embedded comfy.py, hand over.
:: Everything stays in this folder. The Python script is at the end of this file.

if exist "ComfyUI\" (echo [!] ComfyUI folder already exists. Aborting. & pause & exit /b 1)
if exist "python_embeded\" (echo [!] python_embeded folder already exists. Aborting. & pause & exit /b 1)
where git >nul 2>nul || (echo [!] Git not found. Please install Git for Windows. & pause & exit /b 1)
where curl >nul 2>nul || (echo [!] Curl not found. Update Windows or install Curl. & pause & exit /b 1)
set "T0=%time%"

set "UV_NO_CONFIG=1"
set "UV_CACHE_DIR=%~dp0tools\cache"
set "UV_PYTHON_CACHE_DIR=%~dp0tools\cache\python"
set "UV_PYTHON_INSTALL_DIR=%~dp0tools\python"
set "UV_PYTHON_BIN_DIR=%~dp0tools\bin"
set "UV_TOOL_DIR=%~dp0tools\uvtools"
set "UV_TOOL_BIN_DIR=%~dp0tools\bin"
set "UV_PYTHON_INSTALL_BIN=0"
set "UV_PYTHON_INSTALL_REGISTRY=0"
set "UV_PYTHON_DOWNLOADS=manual"

echo [+] Downloading uv...
if not exist "tools" mkdir "tools"
curl -#fL --ssl-no-revoke -o "tools\uv.zip" https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-pc-windows-msvc.zip || goto fail
tar -xf "tools\uv.zip" -C "tools" || goto fail
del "tools\uv.zip" "tools\uvx.exe" "tools\uvw.exe" 2>nul

echo [+] Installing Python 3.13.14...
"tools\uv.exe" python install 3.13.14 --no-bin --no-registry || goto fail
for /d %%d in ("tools\python\cpython-3.13.14-*") do move "%%d" "python_embeded" >nul
rmdir /s /q "tools\python" 2>nul
if not exist "python_embeded\python.exe" goto fail

echo [+] Extracting tools\comfy.py...
"python_embeded\python.exe" -I -c "import sys; t = open(sys.argv[1], encoding='utf-8').read(); open(sys.argv[2], 'w', encoding='utf-8').write(t.split('\n#@@COMFY_PY@@\n', 1)[1])" "%~f0" "tools\comfy.py" || goto fail

"python_embeded\python.exe" -I "tools\comfy.py" install || goto fail
call :elapsed
pause
exit /b 0

:fail
echo [!] Install failed. Delete the ComfyUI, python_embeded and tools folders before retrying.
call :elapsed
pause
exit /b 1

:elapsed
:: Time since T0. %time% may start with a space and use . or , before the centiseconds.
for /f "tokens=1-3 delims=:.," %%a in ("%T0: =0%") do set /a "t0=(1%%a-100)*3600+(1%%b-100)*60+1%%c-100"
for /f "tokens=1-3 delims=:.," %%a in ("%time: =0%") do set /a "t1=(1%%a-100)*3600+(1%%b-100)*60+1%%c-100"
set /a "t=(t1-t0+86400)%%86400, m=t/60, s=t%%60"
echo [+] Total install time: %m%m %s%s
exit /b

#@@COMFY_PY@@
"""ComfyUI Advanced Installer / updater v1.0 (extracted from comfy-adv-install.bat).

Usage (always with the portable interpreter, isolated mode):
    python_embeded\\python.exe -I tools\\comfy.py install
    python_embeded\\python.exe -I tools\\comfy.py update

Rule: everything lives inside the install folder. Only git and curl are used globally.
"""
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

# ---------------------------------------------------------------- paths
ROOT = Path(sys.executable).resolve().parent.parent  # <root>\python_embeded\python.exe
PY = ROOT / "python_embeded" / "python.exe"
COMFY = ROOT / "ComfyUI"
NODES_DIR = COMFY / "custom_nodes"
TOOLS = ROOT / "tools"
UV = TOOLS / "uv.exe"
CACHE = TOOLS / "cache"
OVERRIDES = TOOLS / "uv-overrides.txt"
EXCLUDES = TOOLS / "uv-excludes.txt"
NODES_TXT = ROOT / "nodes.txt"
MANAGER_CFG = COMFY / "user" / "__manager" / "config.ini"

COMFY_REPO = "https://github.com/comfyanonymous/ComfyUI.git"
TORCH_INDEX = "https://download.pytorch.org/whl/cu130"
CUDA_DLL_URL = "https://huggingface.co/datasets/the3minutenode/comfy-install/resolve/main"
CUDA_DLLS = ["cublas64_12.dll", "cublasLt64_12.dll", "cudart64_12.dll", "cufft64_11.dll"]

# ---------------------------------------------------------------- policy
OVERRIDES_TXT = """\
# Pinned versions. Every package named here is also always installed (core set).
torch==2.13.0+cu130
torchvision==0.28.0+cu130
torchaudio==2.11.0+cu130
numpy==2.5.4
onnxruntime-gpu==1.24.4
kokoro-onnx==0.4.4
triton-windows==3.7.1.post27
sageattention @ https://github.com/woct0rdho/SageAttention/releases/download/v2.2.0-windows.post6/sageattention-2.2.0+cu130torch2.10.0andhigher.post6-cp310-abi3-win_amd64.whl
flash-attn @ https://github.com/mjun0812/flash-attention-prebuild-wheels/releases/download/v0.9.52/flash_attn-2.8.3+cu130torch2.13-cp313-cp313-win_amd64.whl
insightface @ https://github.com/Gourieff/Assets/raw/main/Insightface/insightface-0.7.3-cp313-cp313-win_amd64.whl
"""

EXCLUDES_TXT = """\
# CPU onnxruntime would overwrite onnxruntime-gpu - same 'onnxruntime' module
onnxruntime
# no Windows wheel, needs a C++ compiler - ComfyUI_FaceAnalysis works with insightface
dlib
# linux-only package name; triton-windows provides the 'triton' module
triton
# albumentationsx ships the SAME 'albumentations' module folder - two owners corrupt it
albumentations
# opencv-python / -headless / -contrib all ship 'cv2'; keep only opencv-contrib-python (superset)
opencv-python
opencv-python-headless
# ComfyUI-Manager lists uv; the only uv is tools\\uv.exe (run.bat puts it on PATH)
uv
"""

# Always installed besides the override names.
# No `uv` package here: the only uv is tools\uv.exe. run.bat puts tools\ on PATH (that window only)
# and sets UV_PYTHON, so ComfyUI-Manager's `uv pip` fallback installs into python_embeded.
EXTRA_CORE = ["opencv-contrib-python"]

# Excluded package -> real owner of the same module folder (reinstalled after the impostor is removed).
OWNERS = {
    "onnxruntime": "onnxruntime-gpu",
    "triton": "triton-windows",
    "albumentations": "albumentationsx",
    "opencv-python": "opencv-contrib-python",
    "opencv-python-headless": "opencv-contrib-python",
}

DEFAULT_NODES = """\
https://github.com/ltdrdata/ComfyUI-Manager
https://github.com/yolain/ComfyUI-Easy-Use
https://github.com/kijai/ComfyUI-KJNodes
https://github.com/BobRandomNumber/ComfyUI-Crystools-MonitorOnly
https://github.com/city96/ComfyUI-GGUF
https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler
https://github.com/cubiq/ComfyUI_FaceAnalysis
https://github.com/stavsap/comfyui-kokoro
https://github.com/stavsap/comfyui-ollama
https://github.com/Fannovel16/comfyui_controlnet_aux
https://github.com/ClownsharkBatwing/RES4LYF
https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
https://github.com/geroldmeisinger/ComfyUI-outputlists-combiner
https://github.com/lbouaraba/comfyui-krea2edit
"""

# ---------------------------------------------------------------- generated files
RUN_BAT = r"""@echo off
cd /d "%~dp0"
:: ComfyUI-Manager installs with uv (use_uv = True) using the one uv in tools\.
:: PATH and UV_PYTHON apply to this window only; cache and config stay inside this folder.
:: Extra ComfyUI options are passed through (%*), e.g. "call run.bat --offline". See the run-*.bat examples.
set "PATH=%~dp0tools;%PATH%"
set "UV_PYTHON=%~dp0python_embeded\python.exe"
set "UV_NO_CONFIG=1"
set "UV_CACHE_DIR=%~dp0tools\cache"
set "UV_PYTHON_DOWNLOADS=never"
set "UV_LINK_MODE=copy"
.\python_embeded\python.exe -s -W ignore::FutureWarning .\ComfyUI\main.py --windows-standalone-build %*
pause
"""


def example_bat(about, args, setup=()):
    """A small launcher that calls run.bat with extra ComfyUI options."""
    return "\n".join(["@echo off", f":: {about}",
                      ":: Starts run.bat with the options below. Copy this file to make your own.",
                      *setup, f'call "%~dp0run.bat" {args}', ""])


EXAMPLE_BATS = {
    "run-offline.bat": example_bat(
        "Offline: the frontend makes no internet requests and partner (API) nodes are disabled.",
        "--offline"),
    "run-sage-attention.bat": example_bat(
        "SageAttention: faster attention on NVIDIA GPUs (installed by this installer).",
        "--use-sage-attention"),
    "run-reserve-vram-2gb.bat": example_bat(
        "Keep 2 GB of VRAM free for other programs (browser, video player, games).",
        "--reserve-vram 2"),
    "run-custom-folders.bat": example_bat(
        "Keep input, output and temp files in %LOCALAPPDATA%\\img (outside this folder; temp goes to img\\temp).",
        r'--input-directory "%IMG%\in" --output-directory "%IMG%\out" --temp-directory "%IMG%"',
        [r'set "IMG=%LOCALAPPDATA%\img"']),
}

UPDATE_BAT = r"""@echo off
cd /d "%~dp0"
title ComfyUI Advanced Updater v1.0
"python_embeded\python.exe" -I "tools\comfy.py" update
pause
"""

EXTRA_MODEL_PATHS = """\
comfyui:
    base_path: models/
    is_default: true
    audio_encoders: audio_encoders
    checkpoints: checkpoints
    clip: clip
    clip_vision: clip_vision
    configs: configs
    controlnet: controlnet
    diffusers: diffusers
    diffusion_models: diffusion_models
    embeddings: embeddings
    gligen: gligen
    hypernetworks: hypernetworks
    latent_upscale_models: latent_upscale_models
    loras: loras
    model_patches: model_patches
    photomaker: photomaker
    style_models: style_models
    text_encoders: text_encoders
    unet: unet
    upscale_models: upscale_models
    vae: vae
    vae_approx: vae_approx
    vibevoice: vibevoice
    ipadapter: ipadapter
    insightface: insightface
    LLM: LLM
    sams: sams
    sam2: sam2
    SEEDVR2: SEEDVR2
    ultralytics: ultralytics
    wav2vec2: wav2vec2
"""

# uv stays inside the folder: no user config, local cache, no downloads, no shims, no registry.
os.environ.update({
    "UV_NO_CONFIG": "1",
    "UV_CACHE_DIR": str(CACHE),
    "UV_PYTHON_CACHE_DIR": str(CACHE / "python"),
    "UV_PYTHON_INSTALL_DIR": str(TOOLS / "python"),
    "UV_PYTHON_BIN_DIR": str(TOOLS / "bin"),
    "UV_TOOL_DIR": str(TOOLS / "uvtools"),
    "UV_TOOL_BIN_DIR": str(TOOLS / "bin"),
    "UV_PYTHON_INSTALL_BIN": "0",
    "UV_PYTHON_INSTALL_REGISTRY": "0",
    "UV_PYTHON_DOWNLOADS": "never",
    "UV_LINK_MODE": "copy",
    "GIT_TERMINAL_PROMPT": "0",  # a dead node URL fails instead of waiting for a login
})

# ---------------------------------------------------------------- output
CYAN, GREEN, YELLOW, RED, RESET = "\033[96m", "\033[92m", "\033[93m", "\033[91m", "\033[0m"


def step(msg):
    print(f"\n{CYAN}[+] {msg}{RESET}", flush=True)


def warn(msg):
    print(f"{YELLOW}[!] {msg}{RESET}", flush=True)


def die(msg):
    print(f"{RED}[x] {msg}{RESET}", flush=True)
    sys.exit(1)


# ---------------------------------------------------------------- helpers
def run(*cmd, check=True):
    """Run a command with live output. Return its exit code; stop on failure if check."""
    code = subprocess.run([str(c) for c in cmd]).returncode
    if check and code:
        die(f"Command failed ({code}): {' '.join(str(c) for c in cmd[:4])} ...")
    return code


def norm(name):
    return re.sub(r"[-_.]+", "-", name).lower()


def policy_names(path):
    """Package names from a requirements-style file (comments and blanks skipped)."""
    names = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.split(" #")[0].strip()
        if line and not line.startswith("#"):
            names.append(norm(re.split(r"[\s=<>!~@;\[]", line, maxsplit=1)[0]))
    return names


def core_set():
    return policy_names(OVERRIDES) + EXTRA_CORE


def node_url(d):
    """Repo URL of a node folder: git origin, or [project.urls] Repository of a registry (zip) install."""
    if (d / ".git").exists():
        r = subprocess.run(["git", "-C", str(d), "remote", "get-url", "origin"],
                           capture_output=True, text=True)
        return r.stdout.strip() if r.returncode == 0 else ""
    try:
        import tomllib
        urls = tomllib.loads((d / "pyproject.toml").read_text(encoding="utf-8"))["project"]["urls"]
        return next((v for k, v in urls.items() if k.lower() == "repository"), "")
    except Exception:
        return ""


def uv_pip(*args, check=True):
    return run(UV, "pip", *args, "--python", PY, check=check)


POLICY = ["--overrides", OVERRIDES, "--excludes", EXCLUDES,
          "--index", TORCH_INDEX, "--index-strategy", "unsafe-best-match"]


def installed():
    out = subprocess.run([str(UV), "pip", "list", "--python", str(PY), "--format", "json"],
                         capture_output=True, text=True, check=True).stdout
    return {norm(p["name"]): p["version"] for p in json.loads(out)}


def write_if_missing(path, text):
    if not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")


def repo_name(url):
    name = url.rstrip("/").rsplit("/", 1)[-1]
    return name[:-4] if name.endswith(".git") else name


def has_packages(f):
    """False for an empty or comment-only file (uv would warn 'does not contain any dependencies')."""
    return any(l.strip() and not l.strip().startswith("#")
               for l in f.read_text(encoding="utf-8", errors="ignore").splitlines())


def node_requirements():
    return sorted((f for f in NODES_DIR.glob("*/requirements.txt") if has_packages(f)),
                  key=lambda p: p.parent.name.lower())


# ---------------------------------------------------------------- shared steps
def sync():
    """Resolve ComfyUI + all custom nodes + core set in ONE pass, then repair impostors."""
    step("Resolving ComfyUI + custom node requirements against overrides/excludes")
    reqs = [COMFY / "requirements.txt"] + node_requirements()
    as_args = lambda files: [a for f in files for a in ("-r", f)]

    if uv_pip("install", *as_args(reqs), *core_set(), *POLICY, check=False):
        warn("Combined resolve failed. Checking requirement files one by one...")
        good, bad = [], []
        for r in reqs:
            ok = uv_pip("install", "--dry-run", "-r", r, *core_set(), *POLICY, check=False) == 0
            (good if ok else bad).append(r)
        if COMFY / "requirements.txt" in bad:
            die("ComfyUI's own requirements cannot be resolved.")
        for r in bad:
            warn(f"Skipped (unresolvable): {r.relative_to(ROOT)}")
        uv_pip("install", *as_args(good), *core_set(), *POLICY)

    step("Checking for packages that clash with core packages")
    have = installed()
    stray = [p for p in policy_names(EXCLUDES) if p in have]
    if not stray:
        print("    none found")
        return
    warn(f"Removing: {', '.join(stray)}")
    uv_pip("uninstall", *stray)
    # The impostor shared a module folder with its owner; uninstalling it deleted owner files too.
    owners = sorted({OWNERS[p] for p in stray if OWNERS.get(p) in have})
    if owners:
        warn(f"Reinstalling: {', '.join(owners)}")
        reinstall = [a for o in owners for a in ("--reinstall-package", o)]
        uv_pip("install", *owners, *reinstall, *POLICY)


def clean():
    step("Removing uv cache")
    run(UV, "cache", "clean", check=False)
    shutil.rmtree(CACHE, ignore_errors=True)


def report():
    step("Core package versions")
    have = installed()
    print(f"    {'python':<26}{sys.version.split()[0]}")
    for name in core_set() + ["comfyui-frontend-package"]:
        print(f"    {name:<26}{have.get(norm(name), RED + 'NOT INSTALLED' + RESET)}")


# ---------------------------------------------------------------- commands
def install():
    step("Preparing portable Python")
    (PY.parent / "Lib" / "EXTERNALLY-MANAGED").unlink(missing_ok=True)
    write_if_missing(OVERRIDES, OVERRIDES_TXT)
    write_if_missing(EXCLUDES, EXCLUDES_TXT)

    if not NODES_TXT.exists():
        warn("nodes.txt not found. Creating default...")
        NODES_TXT.write_text(DEFAULT_NODES, encoding="utf-8")
    urls = [u for line in NODES_TXT.read_text(encoding="utf-8").splitlines()
            if not line.strip().startswith("#") for u in line.split()]

    step("Cloning ComfyUI")
    # master only: other upstream branches differ only in case (deepme987/ComfyUI vs /comfyui)
    # and break ref updates on Windows' case-insensitive file system.
    run("git", "clone", "--branch", "master", "--single-branch", COMFY_REPO, COMFY)

    step("Cloning custom nodes")
    for url in urls:
        dest = NODES_DIR / repo_name(url)
        print(f"{GREEN}    {dest.name}{RESET}")
        if not dest.exists() and run("git", "clone", url, dest, check=False):
            warn(f"Clone failed, skipped: {url}")

    step("Downloading CUDA 12 runtime DLLs (for onnxruntime-gpu)")
    for dll in CUDA_DLLS:
        run("curl", "-#fL", "--ssl-no-revoke", "-o", PY.parent / dll, f"{CUDA_DLL_URL}/{dll}")

    sync()

    step("Writing run.bat, run-*.bat examples, update.bat, extra_model_paths.yaml and Manager config")
    (ROOT / "run.bat").write_text(RUN_BAT, encoding="utf-8")
    for name, text in EXAMPLE_BATS.items():
        (ROOT / name).write_text(text, encoding="utf-8")
    (ROOT / "update.bat").write_text(UPDATE_BAT, encoding="utf-8")
    write_if_missing(COMFY / "extra_model_paths.yaml", EXTRA_MODEL_PATHS)
    write_if_missing(MANAGER_CFG, "[default]\nuse_uv = True\n")

    report()
    clean()  # last: any uv call recreates the cache
    print(f"\n{GREEN}[+] Install complete. Start with run.bat (or a run-*.bat example), update with update.bat.{RESET}")
    print(f"{GREEN}[+] You may delete the install bat and nodes.txt in this folder.{RESET}")


def update():
    write_if_missing(OVERRIDES, OVERRIDES_TXT)
    write_if_missing(EXCLUDES, EXCLUDES_TXT)

    step("Rebuilding nodes.txt from custom_nodes")
    urls = []
    for d in sorted(NODES_DIR.iterdir(), key=lambda p: p.name.lower()):
        url = node_url(d) if d.is_dir() and not d.name.startswith(".") else ""
        if url:
            urls.append(url)
    NODES_TXT.write_text("\n".join(urls) + "\n", encoding="utf-8")
    print(f"    {len(urls)} nodes written to nodes.txt")

    step("Updating ComfyUI (hard reset to origin/master)")
    run("git", "-C", COMFY, "fetch", "origin", "master")  # master only, see install()
    run("git", "-C", COMFY, "reset", "--hard", "origin/master")

    sync()
    report()
    clean()  # last: any uv call recreates the cache
    print(f"\n{GREEN}[+] Update complete.{RESET}")


if __name__ == "__main__":
    os.system("")  # enable ANSI colors in cmd
    if not PY.exists() or not UV.exists():
        die("Run this through the install bat / update.bat (python_embeded or tools\\uv.exe missing).")
    command = sys.argv[1] if len(sys.argv) > 1 else ""
    if command not in ("install", "update"):
        die("Usage: python -I tools\\comfy.py install|update")
    install() if command == "install" else update()
