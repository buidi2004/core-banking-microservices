# Multi-stage: đóng gói sẵn model weights (Giai đoạn 5)
# GPU stack: onnxruntime-gpu 1.22 (CUDA 12) + NVIDIA pip wheels — không cần repo apt NVIDIA
# (repo CUDA13 của NVIDIA bị apt mới từ chối chữ ký SHA1; trong container dùng CUDA12 ổn định hơn)
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
        libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir \
        onnxruntime-gpu==1.22.0 \
        nvidia-cuda-runtime-cu12>=12.3.0 \
        nvidia-cuda-nvrtc-cu12>=12.3.0 \
        nvidia-cublas-cu12==12.3.4.1 \
        nvidia-cudnn-cu12==9.1.0.70 \
        nvidia-cufft-cu12==11.2.1.3 \
        nvidia-curand-cu12==10.3.5.147 \
        nvidia-cusolver-cu12==11.6.1.9 \
        nvidia-cusparse-cu12==12.5.1.3 \
        nvidia-nvjitlink-cu12==12.9.86 \
    && rm -rf /root/.cache

# ORT CUDA EP tìm lib qua LD_LIBRARY_PATH (pip wheel layout)
ENV LD_LIBRARY_PATH=/usr/local/lib/python3.12/site-packages/nvidia/cuda_runtime/lib:/usr/local/lib/python3.12/site-packages/nvidia/cuda_nvrtc/lib:/usr/local/lib/python3.12/site-packages/nvidia/cublas/lib:/usr/local/lib/python3.12/site-packages/nvidia/cudnn/lib:/usr/local/lib/python3.12/site-packages/nvidia/cufft/lib:/usr/local/lib/python3.12/site-packages/nvidia/curand/lib:/usr/local/lib/python3.12/site-packages/nvidia/cusolver/lib:/usr/local/lib/python3.12/site-packages/nvidia/cusparse/lib:/usr/local/lib/python3.12/site-packages/nvidia/nvjitlink/lib

# Models và mã nguồn đóng sẵn vào image (build context chứa models/ và scripts/)
COPY models/ /app/models/
COPY scripts/ /app/scripts/
COPY app/ /app/app/

EXPOSE 8900
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8900", "--workers", "1"]
