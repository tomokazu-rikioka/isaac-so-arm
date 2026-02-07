#!/bin/bash
#SBATCH --job-name=isaac-sim_play_so101
#SBATCH --nodes=1
#SBATCH --gpus=1
#SBATCH --partition=debug
#SBATCH --output=logs/%x_%j.log

cd ~/isaac-so-arm/gitrepo/isaac_so_arm101

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

singularity exec --nv --writable-tmpfs \
  --bind "$JOB_TMP/IsaacLab:/tmp/IsaacLab" \
  --bind "$JOB_TMP/vulkan/icd.d/nvidia_icd.json:/usr/share/vulkan/icd.d/nvidia_icd.json:ro" \
  --bind /usr/share/glvnd/egl_vendor.d/10_nvidia.json:/usr/share/glvnd/egl_vendor.d/10_nvidia.json:ro \
  --env VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json \
  --env VK_DRIVER_FILES=/usr/share/vulkan/icd.d/nvidia_icd.json \
  ${WANDB_API_KEY:+--env WANDB_API_KEY="$WANDB_API_KEY"} \
  ~/isaac-so-arm/containers/isaac-lab.sif \
  uv run src/isaac_so_arm101/scripts/rsl_rl/play.py \
    --task Isaac-SO-ARM100-Reach-v0 \
    --num_envs 1 \
    --headless \
    --enable_cameras \
    --video \
    --video_length 500
