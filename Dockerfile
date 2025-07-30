FROM nvcr.io/nvidia/pytorch:25.06-py3-igpu
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN <<EOF
set -e

git clone https://github.com/vllm-project/vllm.git
cd vllm

uv venv
python3 use_existing_torch.py
uv pip install -r requirements/build.txt

export MAX_JOBS=2
export NVCC_THREADS=1
export TORCH_CUDA_ARCH_LIST="8.7"
export VLLM_TARGET_DEVICE=cuda
uv pip install --no-build-isolation --verbose -e .
EOF
