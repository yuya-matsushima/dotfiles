#!/bin/sh
set -e

# 親ブランチを自動検出する
# 成功時: ブランチ名を stdout に出力して exit 0
# 失敗時: エラーメッセージを stderr に出力して exit 1

# 1. upstream tracking branch をチェック
upstream=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null || true)
if [ -n "$upstream" ]; then
    # remote prefix を除去 (origin/feature/big-feature → feature/big-feature)
    branch=${upstream#*/}
    if git rev-parse --verify "$branch" >/dev/null 2>&1; then
        echo "$branch"
        exit 0
    fi
fi

# 2. Fallback to default branches
for branch in develop main master; do
    if git rev-parse --verify "$branch" >/dev/null 2>&1; then
        echo "$branch"
        exit 0
    fi
done

# 3. Error
echo "Error: No default base branch found (tried: upstream, develop, main, master). Please specify a base branch explicitly: pr <base-branch> [--auto]" >&2
exit 1
