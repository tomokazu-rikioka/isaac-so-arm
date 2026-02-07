# isaac-so-arm

highreso HPC クラスタ上で SO-ARM ロボットの強化学習 (Isaac Lab) を実行するためのセットアップ一式。

学習コード本体は [MuammerBay/isaac_so_arm101](https://github.com/MuammerBay/isaac_so_arm101) を `git clone` して使用する。

## ディレクトリ構成

```
isaac-so-arm/              # このリポジトリ (HPC 上では ~/isaac-so-arm/)
├── .gitignore
├── README.md
├── containers/
│   └── isaac-lab.def      # Singularity 定義ファイル
├── gitrepo/               # 学習コードの配置先
│   └── isaac_so_arm101/   # git clone で取得
├── logs/                  # Slurm ジョブログ出力先
└── slurm/
    └── template/
        ├── run_rl.sh      # 学習 (動画録画付き)
        ├── run_rl_fast.sh # 学習 (動画なし・高速)
        └── play_rl.sh     # 学習済みモデルの再生
```

## セットアップ手順

### 1. リポジトリの clone

```bash
cd ~
git clone <このリポジトリの URL> isaac-so-arm
cd isaac-so-arm
```

### 2. Singularity コンテナのビルド

```bash
cd ~/isaac-so-arm/containers
singularity build --fakeroot isaac-lab.sif isaac-lab.def
```

ビルド確認:

```bash
ls -lh isaac-lab.sif
```

### 3. 学習リポジトリの clone

```bash
cd ~/isaac-so-arm/gitrepo
git clone https://github.com/MuammerBay/isaac_so_arm101.git
cd isaac_so_arm101
```

### 4. Python 環境構築 (初回のみ)

コンテナ内に入って依存をインストールする。

```bash
cd ~/isaac-so-arm/gitrepo/isaac_so_arm101
singularity shell --nv ~/isaac-so-arm/containers/isaac-lab.sif
uv sync
uv add wandb
exit
```

### 5. WandB の設定

学習曲線（報酬・損失・エピソード長）を [wandb.ai](https://wandb.ai) でリアルタイムに確認できる。

`.env.example` をコピーして API キーを設定:

```bash
cd ~/isaac-so-arm
cp .env.example .env
vi .env  # WANDB_API_KEY を記入
```

### 6. ジョブ投入・確認

```bash
cd ~/isaac-so-arm
sbatch slurm/template/run_rl.sh
```

ジョブ状態の確認:

```bash
squeue -u $USER
```

出力ログの確認:

```bash
cat logs/isaac-sim_rl_so101_<JOB_ID>.log
```

学習中の動画は以下に保存される:

```
gitrepo/isaac_so_arm101/logs/rsl_rl/Isaac-SO-ARM100-Reach-v0/<timestamp>/videos/train/
```

動画をローカルにダウンロード:

```bash
rsync -avz user@highreso:~/isaac-so-arm/gitrepo/isaac_so_arm101/logs/ ./local_logs/
```

> **注**: `slurm/template/run_rl.sh` は動画録画付きのため学習速度が低下する。高速に学習のみ行う場合は `slurm/template/run_rl_fast.sh` を使用する。

### 7. 学習済みモデルの再生

学習後、ポリシーの動作を動画として確認:

```bash
sbatch slurm/template/play_rl.sh
```

動画は `logs/rsl_rl/Isaac-SO-ARM100-Reach-v0/<timestamp>/videos/` に保存される。
