#!/bin/bash
#SBATCH --job-name=isaac-sim_rl_so101
#SBATCH --nodes=1
#SBATCH --gpus=1
#SBATCH --partition=debug
#SBATCH --output=logs/%x_%j.log

cd ~/isaac-so-arm/gitrepo/isaac_so_arm101

# ジョブ固有の一時領域
export JOB_TMP="${SLURM_TMPDIR:-$HOME/isaac-so-arm/tmp/$SLURM_JOB_ID}"
mkdir -p "$JOB_TMP/IsaacLab"

singularity exec --nv --writable-tmpfs \
  --bind "$JOB_TMP/IsaacLab:/tmp/IsaacLab" \
  ~/isaac-so-arm/containers/isaac-lab.sif \
  uv run src/isaac_so_arm101/scripts/rsl_rl/train.py \
    --task Isaac-SO-ARM100-Reach-v0 \
    --headless
