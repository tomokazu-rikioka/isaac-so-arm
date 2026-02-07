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

# .env から環境変数を読み込む
ENV_FILE=~/isaac-so-arm/.env
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# コンテナ内で CUDA_VISIBLE_DEVICES を unset する
# Omniverse は独自の GPU 管理を行うため、CUDA_VISIBLE_DEVICES との競合でハングする
singularity exec --nv --writable-tmpfs \
  --bind "$JOB_TMP/IsaacLab:/tmp/IsaacLab" \
  ${WANDB_API_KEY:+--env WANDB_API_KEY="$WANDB_API_KEY"} \
  ~/isaac-so-arm/containers/isaac-lab.sif \
  bash -c 'unset CUDA_VISIBLE_DEVICES && exec uv run src/isaac_so_arm101/scripts/rsl_rl/train.py \
    --task Isaac-SO-ARM100-Reach-v0 \
    --headless \
    --logger wandb \
    --log_project_name so-arm'

echo "=== Job finished at $(date) with exit code $? ==="
