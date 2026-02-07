#!/bin/bash
#SBATCH --job-name=isaac-sim_rl_so101
#SBATCH --nodes=1
#SBATCH --gpus=1
#SBATCH --partition=debug
#SBATCH --output=logs/%x_%j.log

cd ~/isaac-so-arm/gitrepo/isaac_so_arm101

echo "=== Job started at $(date) on $(hostname) ==="
echo "SLURM_JOB_ID=$SLURM_JOB_ID, CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES"

# ジョブ固有の一時領域
export JOB_TMP="${SLURM_TMPDIR:-$HOME/isaac-so-arm/tmp/$SLURM_JOB_ID}"
mkdir -p "$JOB_TMP/IsaacLab"

# nvidia-container-cli に graphics capability を有効にさせる（--nv 実行前に設定が必要）
export NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics,display

# コンテナ内で動作する Vulkan ICD JSON を生成
mkdir -p "$JOB_TMP/vulkan/icd.d"
cat > "$JOB_TMP/vulkan/icd.d/nvidia_icd.json" <<'VICD'
{
    "file_format_version" : "1.0.0",
    "ICD": {
        "library_path": "libGLX_nvidia.so.0",
        "api_version" : "1.3"
    }
}
VICD

# .env から環境変数を読み込む
ENV_FILE=~/isaac-so-arm/.env
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# Slurm が設定する CUDA_VISIBLE_DEVICES を記録し、コンテナ内では unset する
# Omniverse は独自の GPU 管理を行うため、CUDA_VISIBLE_DEVICES との競合でハングする
SLURM_CUDA_DEVICES="${CUDA_VISIBLE_DEVICES:-}"

singularity exec --nv --writable-tmpfs \
  --bind "$JOB_TMP/IsaacLab:/tmp/IsaacLab" \
  --bind "$JOB_TMP/vulkan/icd.d/nvidia_icd.json:/usr/share/vulkan/icd.d/nvidia_icd.json:ro" \
  --bind /usr/share/glvnd/egl_vendor.d/10_nvidia.json:/usr/share/glvnd/egl_vendor.d/10_nvidia.json:ro \
  --env VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json \
  --env VK_DRIVER_FILES=/usr/share/vulkan/icd.d/nvidia_icd.json \
  ${WANDB_API_KEY:+--env WANDB_API_KEY="$WANDB_API_KEY"} \
  ~/isaac-so-arm/containers/isaac-lab.sif \
  bash -c 'unset CUDA_VISIBLE_DEVICES && exec uv run src/isaac_so_arm101/scripts/rsl_rl/train.py \
    --task Isaac-SO-ARM100-Reach-v0 \
    --headless \
    --logger wandb \
    --log_project_name so-arm'

echo "=== Job finished at $(date) with exit code $? ==="
