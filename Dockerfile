FROM docker.io/rockylinux/rockylinux:9.4
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN <<EOF
set -e
dnf install -y 'dnf-command(config-manager)'
dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/sbsa/cuda-rhel9.repo
dnf install -y git-core python3 python3-devel numactl-devel cuda-toolkit-12-6
dnf clean all
EOF

RUN <<EOF
set -e
dnf config-manager --add-repo https://repo.download.nvidia.com/jetson/rhel-9.4/jp6.1/nvidia-l4t.repo
dnf install -y nvidia-jetpack-all
dnf clean all
EOF

RUN <<EOF
set -e
git clone https://github.com/vllm-project/vllm.git
cd vllm

export UV_PYTHON=python3.11

uv venv
python3 use_existing_torch.py
uv pip install --torch-backend cu126 torch torchvision torchaudio
uv pip install -r requirements/build.txt

export MAX_JOBS=2
export NVCC_THREADS=1
export DG_JIT_USE_NVRTC=1
export TORCH_CUDA_ARCH_LIST="8.7"
uv pip install --no-build-isolation --verbose -e .
EOF
