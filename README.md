# ⚡ ComfyUI Advanced Installer

One-click portable ComfyUI for Windows. Python 3.13, CUDA 13, SageAttention. Everything in one folder.

[![GitHub Release](https://img.shields.io/github/v/release/the3minutenode/ComfyUI-Advanced-Installer)](https://github.com/the3minutenode/ComfyUI-Advanced-Installer/releases/latest)
[![GitHub Release Date](https://img.shields.io/github/release-date/the3minutenode/ComfyUI-Advanced-Installer)](https://github.com/the3minutenode/ComfyUI-Advanced-Installer/releases/latest)
[![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/the3minutenode/ComfyUI-Advanced-Installer/total)](https://github.com/the3minutenode/ComfyUI-Advanced-Installer/releases/latest)
[![Discord](https://img.shields.io/discord/1431137394056233030?label=discord&logo=discord&logoColor=white)](https://discord.com/invite/wDn7cj68gm)
[![YouTube Channel Subscribers](https://img.shields.io/youtube/channel/subscribers/UC8ZKAaWoHYLy58Y6dmypHqg?label=YouTube%20Subscribers)](https://www.youtube.com/@The3MinuteNode)

⚠️ **Official version:** the original repository is `the3minutenode/ComfyUI-Advanced-Installer`. Copies on other accounts are forks.

## Why v1.0

v0.8 worked for months, but its pip installs were slow. v1.0 uses [uv](https://github.com/astral-sh/uv) instead. ComfyUI, every custom node and the pinned packages install in a single pass, and `update.bat` now keeps them consistent. v0.8 is still on the [Releases](https://github.com/the3minutenode/ComfyUI-Advanced-Installer/releases) page. See [CHANGELOG.md](CHANGELOG.md) for the full list of changes.

## Requirements

- Windows 10 or 11, 64-bit
- NVIDIA GPU, RTX 20-series or newer, with a current driver (CUDA 13)
- [Git for Windows](https://git-scm.com/). curl and tar are already part of Windows.
- About 15 GB free during install (about 9 GB after)

## First install

1. Create an empty folder, for example `C:\AI\ComfyUI`.
2. Download `comfy-adv-install.bat` from the [latest release](https://github.com/the3minutenode/ComfyUI-Advanced-Installer/releases/latest) into it.
3. Optional: put a `nodes.txt` next to it to choose your own custom nodes (see [Custom nodes](#custom-nodes)).
4. Double-click `comfy-adv-install.bat`.

It downloads about 6 GB, so it takes a few minutes; about 2 minutes on a fast connection. It ends by printing the installed versions and the total install time. Then start ComfyUI with `run.bat`.

The installer only runs in a folder with no `ComfyUI` or `python_embeded` subfolder, so it can't overwrite an existing install. If an install fails, delete `ComfyUI`, `python_embeded` and `tools`, then run it again.

**Coming from v0.8:** install into a new folder. To keep your models where they are, see [Models](#models).

Demo on YouTube:
[![demo](https://i.ytimg.com/vi/BHuoCsjz0Hg/maxresdefault.jpg)](https://www.youtube.com/watch?v=BHuoCsjz0Hg)

## What you get

```
comfy-adv-install.bat, nodes.txt   safe to delete after install
run.bat                            start ComfyUI
run-*.bat                          launcher examples
update.bat                         update and repair
ComfyUI\                           ComfyUI and custom nodes
python_embeded\                    Python 3.13.14 (private to this folder)
tools\                             uv, the package rules, the installer script
```

Installed and pinned: torch 2.13.0 + CUDA 13.0, torchvision 0.28.0, torchaudio 2.11.0, numpy 2.5.4, SageAttention 2.2.0, FlashAttention 2.8.3, Triton (triton-windows 3.7.1), onnxruntime-gpu 1.24.4, insightface 0.7.3, kokoro-onnx 0.4.4, OpenCV (contrib).

## Running

`run.bat` starts ComfyUI. Any options you add are passed on to ComfyUI. The examples below each call `run.bat`:

| File | Option | Use it for |
|---|---|---|
| `run-sage-attention.bat` | `--use-sage-attention` | Faster generation on NVIDIA GPUs |
| `run-offline.bat` | `--offline` | No internet requests; partner (API) nodes disabled |
| `run-reserve-vram-2gb.bat` | `--reserve-vram 2` | Keep 2 GB of VRAM for other programs |
| `run-custom-folders.bat` | `--input-directory` … | Keep input, output and temp files in `%LOCALAPPDATA%\img` |

To make your own launcher, copy an example and change the last line. Options can be combined:

```bat
@echo off
call "%~dp0run.bat" --use-sage-attention --reserve-vram 2
```

- Always launch through `run.bat`. It sets up uv for ComfyUI-Manager in that window only.
- Avoid `--user-directory`. It moves Manager's settings, and Manager then falls back to slow pip installs.

## Updating

Run `update.bat`. It:

1. Writes the custom nodes you currently have into `nodes.txt`. Disabled nodes are skipped.
2. Updates ComfyUI to the latest `master`.
3. Installs ComfyUI's and every node's requirements in one pass, using the pinned versions.
4. Repairs packages that clash with the pinned ones (see [Dependency clashes](#dependency-clashes)).
5. Prints the installed versions and clears the download cache.

Custom nodes are **not** updated by `update.bat`. Update them in ComfyUI-Manager.

`update.bat` resets the `ComfyUI` folder to the official code, so any edits to ComfyUI's own files are lost. Your models, outputs, custom nodes, user settings and `extra_model_paths.yaml` are not touched.

## Custom nodes

**Default set (14):** ComfyUI-Manager, Easy-Use, KJNodes, Crystools-MonitorOnly, GGUF, SeedVR2 VideoUpscaler, FaceAnalysis, kokoro, ollama, controlnet_aux, RES4LYF, VideoHelperSuite, outputlists-combiner, krea2edit.

**Your own set:** before installing, put a `nodes.txt` next to the installer with one Git URL per line. Lines starting with `#` are ignored.

```
https://github.com/ltdrdata/ComfyUI-Manager
https://github.com/kijai/ComfyUI-KJNodes
```

Keep ComfyUI-Manager in the list. Without it you can't add or update nodes from the ComfyUI interface.

| You did this | What happens / what to do |
|---|---|
| Installed a node with Manager | Manager installs its requirements the next time ComfyUI starts. Then run `update.bat` so everything is checked against the pinned versions. |
| Removed or disabled a node with Manager | Nothing else needed. The next `update.bat` drops it from `nodes.txt`. Packages it installed stay. |
| Cloned a node into `ComfyUI\custom_nodes` with Git | Run `update.bat` to install its requirements. |
| Want the same nodes in a new install | Copy `nodes.txt` (kept up to date by `update.bat`) next to the installer in the new folder. |

## Dependency clashes

Custom nodes often ask for versions that would break others. v1.0 handles this with two lists in `tools\`:

- `uv-overrides.txt`: pinned versions, which always win. These are the packages listed under [What you get](#what-you-get).
- `uv-excludes.txt`: packages that are never installed, because they would overwrite a working one. For example, CPU `onnxruntime` would replace the GPU build, and `opencv-python` would replace OpenCV contrib.

ComfyUI-Manager does not use these lists, so a node it installs can pull in a clashing package. `update.bat` fixes that: it removes the excluded package, reinstalls the correct one and restores the pinned versions.

If a node's requirements can't be satisfied together with the others, the installer and `update.bat` skip that node's requirements and name it. Everything else still installs, but that node may fail to load until its author fixes it.

To change a pin, edit `tools\uv-overrides.txt` and run `update.bat`. To restore the defaults, delete the file and run `update.bat`.

## Models

Models go in `ComfyUI\models\`. To use a model folder you already have, open `ComfyUI\extra_model_paths.yaml`, set `base_path` to that folder and restart ComfyUI:

```yaml
comfyui:
    base_path: D:/AI/models/
```

Subfolder names (`checkpoints`, `loras`, `vae`, …) are listed in the same file.

## What stays outside the folder

Your system Python, PATH, registry and environment variables are not touched. Git and curl are used, but nothing else is installed. This was checked with a full install, repeated updates and a Manager node install. A few small files still end up outside the folder:

| Where | What | Notes |
|---|---|---|
| `%APPDATA%\uv\credentials\` | `credentials.toml.lock` | Empty lock file made by uv |
| `%TEMP%` | `uv-*.lock` | Empty lock files made by uv, one per install folder |
| `%APPDATA%\NVIDIA\ComputeCache` | GPU code cache | Managed by the NVIDIA driver |
| `%TEMP%`, your user folder | PyTorch, Triton, Hugging Face caches | Written by ComfyUI and nodes when a workflow needs them, as with any ComfyUI install |
| `%LOCALAPPDATA%\img` | Your images | Only if you use `run-custom-folders.bat` |

**Uninstall:** delete the folder. The leftover lock files are harmless, and you can delete them too.

## Support

- **Problems?** [Open an issue](https://github.com/the3minutenode/ComfyUI-Advanced-Installer/issues) and include the installer or `update.bat` output.
- [YouTube](https://www.youtube.com/@The3MinuteNode) | [Discord](https://discord.gg/wDn7cj68gm) | [Premium Workflows](https://ko-fi.com/The3MinuteNode) | [Support the Project](https://www.paypal.com/donate/?hosted_button_id=EF3QDPEWK359N)
