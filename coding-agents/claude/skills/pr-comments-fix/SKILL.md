---
name: pr-comments-fix
description: PRレビューコメントを収集・分類し、順番に対応する
argument-hint: [<pr-number>]
---

# PR Comments Fix Command

PRレビューコメントを自動収集・分類し、1つずつ対応してコミットする。

## Instructions

### 1. 引数パースとPR番号取得

**PR番号の決定**:
- `$ARGUMENTS` に PR 番号が指定されている場合: その番号を使用
- 指定がない場合: `gh pr view --json number -q '.number'` で現在ブランチから自動検出
- PR が見つからない場合: エラーメッセージを表示して終了

### 2. レビューコメント収集

以下のコマンドでコメントを取得:

```bash
# PR の基本情報とレビュー情報
gh pr view <PR> --json reviews,comments,latestReviews,reviewDecision

# インラインコメント（ファイル・行番号付き）
gh api repos/{owner}/{repo}/pulls/<PR>/comments
```

### 3. コメント分類

コメントを以下の優先度で分類:

| Priority | カテゴリ | 判定基準 |
|----------|---------|---------|
| 1 | 変更要求 | CHANGES_REQUESTED、"fix", "must", "should", "need to", "required" |
| 2 | 提案 | "suggest", "consider", "might", "could", "nit", "optional" |
| 3 | 質問 | "?" で終わる、"why", "how", "what", "can you explain" |
| 4 | 対応不要 | "LGTM", "+1", "looks good", "approved", "great", "nice" |

### 4. フィルタリング

以下のコメントを除外:
- **解決済み**: `isResolved: true` のスレッド
- **自分のコメント**: `gh api user` で取得した自分のユーザー名と一致
- **対応不要 (Priority 4)**: LGTM などのポジティブコメント

### 5. 一覧表示

分類結果をサマリー表示:

```
## PR #<number> レビューコメント

### Priority 1: 変更要求 (X件)
- [ ] file.ts:42 - "この処理は〜に変更してください" (@reviewer)

### Priority 2: 提案 (X件)
- [ ] file.ts:100 - "〜した方が良いかもしれません" (@reviewer)

### Priority 3: 質問 (X件)
- [ ] file.ts:55 - "なぜこの実装にしたのですか？" (@reviewer)

---
対応対象: X件 / 全体: Y件 (除外: Z件)
```

### 6. 順次対応（自動実行）

**常に自動実行モード**: 確認なしで順番に対応を開始

Priority 1 → 2 → 3 の順で各コメントに対応:

**コード変更が必要な場合** (Priority 1, 2):
1. 該当ファイルを読み込む
2. コメント内容に従ってコードを修正
3. 変更をステージング: `git add <file>`
4. コミット作成:
   ```bash
   git commit -m "fix(review): <コメント内容の要約>

   Addresses review comment by @<reviewer>
   - <変更内容の説明>

   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

**質問への回答が必要な場合** (Priority 3):
1. コードを確認して質問に回答
2. PR にコメントで返信:
   ```bash
   gh pr comment <PR> --body "<回答内容>"
   ```

### 7. 最終サマリー

すべての対応完了後、サマリーを表示:

```
## 対応完了

- コード修正: X件
- コミット作成: Y件
- 質問への返信: Z件

### 作成されたコミット:
- abc1234: fix(review): 〜を修正
- def5678: fix(review): 〜を追加
```

### 8. 自動プッシュ

変更がある場合、リモートにプッシュ:

```bash
git push origin HEAD
```

## 使用例

```bash
# 現在のブランチの PR コメントに対応
/pr-comments-fix

# PR 番号を指定して対応
/pr-comments-fix 123
```

## 注意事項

- **自動実行**: すべての対応は確認なしで自動実行される
- **コミット単位**: 各コメントへの対応は個別のコミットとして作成される
- **返信形式**: 質問への返信は簡潔かつ技術的に正確な内容にする
- **対応不可の場合**: 技術的に対応が困難なコメントは、理由を説明するコメントを投稿
