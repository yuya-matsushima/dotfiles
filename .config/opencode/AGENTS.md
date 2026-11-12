## 横断調査の委譲

複数の issue / docs / レポートをまたぐ調査(対応順の検討, 依存関係の整理, docs と現状の食い違い探し)は,
メインスレッドで Read / Grep / Glob を回さず, 読み取り専用の Explore subagent に委譲する。
メインスレッドには結論だけを戻し, 読み込んだ本文をコンテキストに残さない。

## GitHub へのリンク

ユーザーへの返信や GitHub のコメントで具体的な対象に言及するときは、確認済みの URL を使って Markdown リンクにする。

- リポジトリ → `[yuya-matsushima/dotfiles](URL)`
- Issue・PR → 1 つのリポジトリを参照するセッションでは `[#100](URL)`、複数のリポジトリを参照するセッションでは `[fillin-inc/sales-skills#100](URL)` のように `[owner/repo#番号](URL)` とする。
- コミット → `[a1b2c3d](URL)`
- ブランチ・タグ・リリース → `[fix/update-config](URL)`、`[v1.2.3](URL)`、`[v1.2.3 のリリース](URL)`
- ファイル・該当行 → `[bin/link.sh](URL)`、`[bin/link.sh:42](URL)`
- GitHub Actions の実行・ジョブ → `[CI の実行結果](URL)`、`[shellcheck ジョブ](URL)`
- Issue・PR のコメントやレビュー → `[該当コメント](URL)`、`[レビュー指摘](URL)`
- PR の差分・比較ページ → `[PR #100 の差分](URL)`、`[v1.2.2 → v1.2.3 の差分](URL)`
- GitHub 周辺の対象 → `[プレビュー環境](URL)`、`[公開ドキュメント](URL)`、`[外部 CI の実行結果](URL)`

セッション途中で 2 つ目のリポジトリを参照した時点から、作業中のリポジトリも含め、以降の返信やコメントに出すすべての Issue・PR に `owner/repo#番号` を使う。1 件だけ言及するときも同じ形式にする。

特定の時点のコードや行を根拠として示すときは、コミット SHA に固定したパーマリンクを使う。URL を確認できない場合は、対象名をプレーンテキストで記載する。

## Issue と PR の併記

Issue に対して PR を作成して作業する場合、会話中でその Issue を参照するときは `#issue-num` ではなく `#issue-num(PR #num)` の形式で、対応する PR 番号も併記する。表示は「GitHub へのリンク」に従って Markdown リンクにする。

- 例: `[#42](Issue の URL)(PR [#43](PR の URL))`
- 複数のリポジトリを参照するセッションでは `[owner/repo#42](Issue の URL)(PR [owner/repo#43](PR の URL))`
- PR が未作成、または Issue と PR の対応関係を確認できない場合は、Issue 番号のみを表示する
