#!/bin/sh
set -e

# 親ブランチを自動検出する
# 成功時: ブランチ名を stdout に出力して exit 0
# 失敗時: エラーメッセージを stderr に出力して exit 1

# Note: PR スキルとは異なり、upstream tracking branch は使用しない
# upstream は通常 origin/feature/... で現在のブランチ自身を指すため、
# レビュー用途では適切なベースブランチにならない

# デフォルトブランチを順に探索
for branch in develop main master; do
    if git rev-parse --verify "$branch" >/dev/null 2>&1; then
        echo "$branch"
        exit 0
    fi
done

# 3. Error
echo "Error: No default base branch found. Please specify: codex-review-fix <base-branch>" >&2
exit 1
