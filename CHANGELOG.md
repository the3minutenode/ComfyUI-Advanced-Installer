# Changelog

## v1.0

v0.8 was stable but slow, because it installed with pip. v1.0 rebuilds the installer around uv.

**Install**
- uv replaces pip. ComfyUI, all custom nodes and the pinned packages install in one pass instead of 11 pip runs plus one per custom node, several with forced reinstalls.
- Python 3.13.14 is a full, private build installed by uv. It replaces the embeddable zip plus the headers zip, the `._pth` edits and get-pip.
- Clashing packages are blocked by an exclude list (`tools\uv-excludes.txt`). This replaces the per-node workarounds (skipping kokoro's requirements, filtering dlib) and the forced reinstalls.
- New pins: numpy 2.5.4 (was 2.5.2) and triton-windows 3.7.1.post27 (was 3.5.1.post24). torch 2.13.0, torchvision 0.28.0, torchaudio 2.11.0, SageAttention 2.2.0, FlashAttention 2.8.3, onnxruntime-gpu 1.24.4, insightface 0.7.3 and kokoro-onnx 0.4.4 are unchanged.
- ComfyUI is cloned from `master` only.
- rgthree-comfy is no longer in the default nodes (14 nodes).
- `ipadapter-downloader.bat` is removed because it was outdated.
- The model-folder prompt is gone. To use an existing model folder, edit `base_path` in `ComfyUI\extra_model_paths.yaml`.
- A failed download now stops the install instead of saving an error page as the file.
- The total install time is printed at the end.

**Update**
- `update.bat` now also installs custom node requirements, repairs clashing packages, re-applies the pins and records your current nodes in `nodes.txt`. v0.8 only reinstalled ComfyUI's own requirements.

**Run**
- `run.bat` starts ComfyUI with no extra options and passes on any options you add. v0.8 always added `--disable-api-nodes --use-sage-attention`.
- New launcher examples: `run-sage-attention.bat`, `run-offline.bat`, `run-reserve-vram-2gb.bat`, `run-custom-folders.bat`.
- ComfyUI-Manager installs nodes with uv. Its installs stay inside the folder.

**Upgrading:** v1.0 can't be installed over v0.8. Install it into a new folder.

## v0.1 – v0.8

pip-based releases. Downloads and notes are on the [Releases](https://github.com/the3minutenode/ComfyUI-Advanced-Installer/releases) page.
