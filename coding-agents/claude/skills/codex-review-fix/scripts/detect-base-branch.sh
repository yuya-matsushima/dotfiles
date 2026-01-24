#!/bin/sh
set -e

# 親ブランチを自動検出する
# 成功時: ブランチ名を stdout に出力して exit 0
# 失敗時: エラーメッセージを stderr に出力して exit 1

# 候補ブランチ
CANDIDATES="develop main master"

# 1. origin/HEAD からリモートのデフォルトブランチを取得
default_ref=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || true)
if [ -n "$default_ref" ]; then
    branch=$(echo "$default_ref" | sed 's@refs/remotes/origin/@@')
    # ローカルブランチを優先、なければリモート追跡ブランチ
    if git rev-parse --verify "$branch" >/dev/null 2>&1; then
        echo "$branch"
        exit 0
    elif git rev-parse --verify "origin/$branch" >/dev/null 2>&1; then
        echo "origin/$branch"
        exit 0
    fi
fi

# 2. merge-base 距離計算で最も近いブランチを選択
closest_ref=""
min_distance=999999

for candidate in $CANDIDATES; do
    # 候補ブランチが存在するか確認 (ローカルまたはリモート)
    if git rev-parse --verify "$candidate" >/dev/null 2>&1; then
        ref="$candidate"
    elif git rev-parse --verify "origin/$candidate" >/dev/null 2>&1; then
        ref="origin/$candidate"
    else
        continue
    fi

    # 現在のブランチと候補の共通祖先を見つける
    merge_base=$(git merge-base HEAD "$ref" 2>/dev/null || true)
    if [ -z "$merge_base" ]; then
        continue
    fi

    # HEAD から merge-base までのコミット数 (= 分岐してからのコミット数)
    distance=$(git rev-list --count "$merge_base"..HEAD 2>/dev/null || echo 999999)

    # 最も距離が短いブランチを記録 (実際に解決可能な ref を保存)
    if [ "$distance" -lt "$min_distance" ]; then
        min_distance=$distance
        closest_ref=$ref
    fi
done

if [ -n "$closest_ref" ]; then
    echo "$closest_ref"
    exit 0
fi

# 3. フォールバック: 候補ブランチを順に探索 (ローカル優先、なければリモート)
for branch in $CANDIDATES; do
    if git rev-parse --verify "$branch" >/dev/null 2>&1; then
        echo "$branch"
        exit 0
    elif git rev-parse --verify "origin/$branch" >/dev/null 2>&1; then
        echo "origin/$branch"
        exit 0
    fi
done

# 4. Error
echo "Error: No default base branch found. Please specify: codex-review-fix <base-branch>" >&2
exit 1
