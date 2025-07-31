FROM quay.io/ncao/wheels:torch AS torch
FROM docker.io/pytorch/manylinuxaarch64-builder:cuda12.8-2.7 AS build
RUN cp /etc/ld.so.cache{,bak} && dnf install -y numactl-devel && cp /etc/ld.so.cache{bak,} && dnf clean all

RUN --mount=from=torch,target=/mnt/torch <<EOF
set -euxo pipefail

git clone --branch v0.10.0 --depth 1 --recurse-submodules https://github.com/vllm-project/vllm.git /vllm
cd /vllm

python3.11 use_existing_torch.py
python3.11 -m pip install /mnt/torch/wheels/*.whl torchvision torchaudio \
  --index-url https://download.pytorch.org/whl/cu128
python3.11 -m pip install -r requirements/build.txt

export MAX_JOBS=2
export NVCC_THREADS=1
export TORCH_CUDA_ARCH_LIST="8.7"
export VLLM_TARGET_DEVICE=cuda

python3.11 -m build --no-isolation .
EOF

FROM scratch
COPY --from=build /vllm/dist /wheels
