# ComfyUI-Advanced-Installer

A high-performance, **one-click deployment script** for ComfyUI on Windows. This repository provides a fully portable, "embedded" environment using **Python 3.13.9** and **CUDA 13.0**, optimized for the latest generation of AI models.

## 🚀 Features

* **Zero Manual Setup**: Automates the download of Python, Pip, and Git dependencies.
* **Python 3.13 Ready**: Pre-patched to support Python 3.13, including headers and libraries for complex wheels.
* **High-Performance Libraries**:
* **Triton for Windows**: Pre-configured for faster kernels.
* **SageAttention**: Integrated for cutting-edge attention optimization.
* **Insightface**: Includes custom wheels compatible with Python 3.13.
* **Portable**: Everything is contained within the folder—no system-wide environment variables required.

## 🛠️ Included Custom Nodes

By default, this script clones and prepares the following essential nodes:

* [ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager)
* [rgthree-comfy](https://github.com/rgthree/rgthree-comfy)
* [ComfyUI-Easy-Use](https://github.com/yolain/ComfyUI-Easy-Use)
* [ComfyUI-KJNodes](https://github.com/kijai/ComfyUI-KJNodes)
* [ComfyUI-Crystools](https://github.com/crystian/ComfyUI-Crystools)
* [comfyui-kokoro](https://github.com/stavsap/comfyui-kokoro)

## 📦 Installation

1. **Prerequisites**: Ensure you have [Git](https://git-scm.com/) installed on your Windows machine.
2. **Download**: Clone this repository or download the `.bat` file.
3. **Run**: Double-click `comfy-adv-install.bat`.
4. **Wait**: The script will download approximately 3-5GB of dependencies (PyTorch, Python, etc.).
5. **Launch**: Once finished, use the generated path to start ComfyUI:
```bash
python_embeded\python.exe -s ComfyUI\main.py --windows-standalone-build
```

## 🔧 Technical Notes

### The "Kokoro" Bypass

Standard installations of `comfyui-kokoro` often fail on Python 3.13 because they request `kokoro 0.4.2`. This script bypasses that requirement and manually injects `kokoro-onnx 0.4.4`, which is fully compatible with the 3.13 runtime, preventing installation crashes.

### Performance Tweaks

The script installs **SageAttention** and **Triton Windows** by default. If you are using an NVIDIA 30-series or 40-series card, you will see significantly improved inference times and reduced VRAM overhead in compatible workflows.

## ⚠️ Disclaimer

This script is provided "as-is." It downloads binaries from various third-party sources (Python, PyTorch, GitHub). Always review the `.bat` file before running it on your system.
---

### Would you like me to add a "Troubleshooting" section or a section on how to add more custom nodes to the script?
