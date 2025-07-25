FROM docker.io/rockylinux/rockylinux:9.4
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN <<EOF
dnf install -y 'dnf-command(config-manager)'
dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/sbsa/cuda-rhel9.repo
dnf install -y git-core python3-devel cuda-toolkit-12-6
dnf clean all
EOF

RUN <<EOF
git clone https://github.com/vllm-project/vllm.git
cd vllm

uv venv
uv run python use_existing_torch.py
uv pip install --torch-backend cu126 torch torchvision torchaudio
uv pip install -r requirements/build.txt
uv pip install --no-build-isolation -e .
EOF
