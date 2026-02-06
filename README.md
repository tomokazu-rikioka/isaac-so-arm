# isaac-so-arm

highreso HPC クラスタ上で SO-ARM ロボットの強化学習 (Isaac Lab) を実行するためのセットアップ一式。

学習コード本体は [MuammerBay/isaac_so_arm101](https://github.com/MuammerBay/isaac_so_arm101) を `git clone` して使用する。

## ディレクトリ構成

```
isaac-so-arm/           # このリポジトリ
├── .gitignore
├── README.md
├── containers/
│   └── isaac-lab.def   # Singularity 定義ファイル
└── templates/
    └── run_rl.sh.example  # Slurm テンプレート（参考用）
```

HPC 上の作業ディレクトリ:

```
~/isaac/
├── containers/
│   ├── isaac-lab.def   # このリポジトリからコピー
│   └── isaac-lab.sif   # ビルド済みイメージ
├── gitrepo/
│   └── isaac_so_arm101/  # 学習コード (git clone)
└── tmp/                  # ジョブ一時ファイル
```

## セットアップ手順

### 1. 作業ディレクトリの作成

```bash
mkdir -p ~/isaac/containers ~/isaac/gitrepo
```

### 2. Singularity コンテナのビルド

このリポジトリの定義ファイルを使ってコンテナをビルドする。

```bash
cd ~/isaac/containers
cp <このリポジトリのパス>/containers/isaac-lab.def .
singularity build --fakeroot isaac-lab.sif isaac-lab.def
```

ビルド確認:

```bash
ls -lh isaac-lab.sif
```

### 3. 学習リポジトリの clone

```bash
cd ~/isaac/gitrepo
git clone https://github.com/MuammerBay/isaac_so_arm101.git
cd isaac_so_arm101
```

### 4. Python 環境構築 (初回のみ)

コンテナ内に入って `uv sync` を実行する。

```bash
singularity shell --nv ~/isaac/containers/isaac-lab.sif
```

コンテナ内:

```bash
uv sync
exit
```

### 5. Slurm バッチファイルの作成

`templates/run_rl.sh.example` を参考に、HPC 上でバッチファイルを作成する。

```bash
cd ~/isaac/gitrepo/isaac_so_arm101
vi run_rl.sh
```

テンプレート内容 (`templates/run_rl.sh.example`):

```bash
#!/bin/bash
#SBATCH --job-name=isaac-sim_rl_so101
#SBATCH --nodes=1
#SBATCH --gpus=1
#SBATCH --partition=debug

cd ~/isaac/gitrepo/isaac_so_arm101

# ジョブ固有の一時領域
export JOB_TMP="${SLURM_TMPDIR:-$HOME/isaac/tmp/$SLURM_JOB_ID}"
mkdir -p "$JOB_TMP/IsaacLab"

singularity exec --nv --writable-tmpfs \
  --bind "$JOB_TMP/IsaacLab:/tmp/IsaacLab" \
  ~/isaac/containers/isaac-lab.sif \
  uv run src/isaac_so_arm101/scripts/rsl_rl/train.py \
    --task Isaac-SO-ARM100-Reach-v0 \
    --headless
```

実行権限を付与:

```bash
chmod +x run_rl.sh
```

### 6. ジョブ投入・確認

```bash
sbatch run_rl.sh
```

ジョブ状態の確認:

```bash
squeue -u $USER
```

出力ログの確認:

```bash
cat slurm-<JOB_ID>.out
```
