FROM docker.io/rockylinux/rockylinux:9.4
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN <<EOF
set -e
dnf install -y 'dnf-command(config-manager)'
dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/sbsa/cuda-rhel9.repo
dnf install -y git-core python3.11 python3.11-devel numactl-devel cuda-toolkit-12-8
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
dnf config-manager --set-enabled crb
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf install -y ccache
EOF

RUN <<EOF
set -e
git clone https://github.com/vllm-project/vllm.git
cd vllm

export UV_PYTHON=$(which python3.11)
export UV_TORCH_BACKEND=cu128

uv venv
python3.11 use_existing_torch.py
uv pip install torch torchvision torchaudio pytorch-triton --index-url https://download.pytorch.org/whl/cu128
uv pip install -r requirements/build.txt

export MAX_JOBS=2
export NVCC_THREADS=1
export DG_JIT_USE_NVRTC=1
export TORCH_CUDA_ARCH_LIST="8.7"
export VLLM_TARGET_DEVICE=cuda
uv pip install --no-build-isolation --verbose -e .
EOF
