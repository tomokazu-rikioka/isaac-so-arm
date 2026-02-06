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
└── slurm/
    └── run_rl.sh          # Slurm バッチスクリプト
```

ビルド後の追加ファイル:

```
~/isaac-so-arm/
├── containers/
│   └── isaac-lab.sif      # ビルド済みコンテナイメージ (.gitignore)
└── tmp/                   # ジョブ一時ファイル (.gitignore)
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

コンテナ内に入って `uv sync` を実行する。

```bash
singularity shell --nv ~/isaac-so-arm/containers/isaac-lab.sif
```

コンテナ内:

```bash
uv sync
exit
```

### 5. ジョブ投入・確認

```bash
cd ~/isaac-so-arm
sbatch slurm/run_rl.sh
```

ジョブ状態の確認:

```bash
squeue -u $USER
```

出力ログの確認:

```bash
cat slurm-<JOB_ID>.out
```
