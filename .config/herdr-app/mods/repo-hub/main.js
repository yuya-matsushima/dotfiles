import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, TextView } from "gpui-base";
import { exec, focused, nextCommand, panes, props, settings, spaces, theme, window } from "herdr";

const PR_FIELDS =
  "number,title,state,author,isDraft,reviewDecision,statusCheckRollup,updatedAt,url,closingIssuesReferences";
// parent / subIssues need `gh` 2.94 or newer (GitHub sub-issues); the same list
// without them is the fallback for an older gh or a GHES without sub-issues.
const ISSUE_FIELDS =
  "number,title,state,author,labels,comments,updatedAt,url,parent,subIssues,subIssuesSummary,closedByPullRequestsReferences";
const ISSUE_FIELDS_PLAIN =
  "number,title,state,author,labels,comments,updatedAt,url";
const PR_DETAIL_FIELDS =
  "body,additions,deletions,changedFiles,files,baseRefName,headRefName,reviewDecision,statusCheckRollup,comments,url,state,createdAt,updatedAt";
const ISSUE_DETAIL_FIELDS = "body,state,labels,comments,url,createdAt,updatedAt";

function parseGithub(url) {
  const m = /github\.com[:/]([^/\s]+)\/([^/\s]+?)(?:\.git)?\/?$/.exec(url.trim());
  return m ? `${m[1]}/${m[2]}` : null;
}

function timeAgo(iso) {
  const then = new Date(iso).getTime();
  if (!then) return "";
  const s = Math.max(0, (Date.now() - then) / 1000);
  if (s < 60) return "now";
  if (s < 3600) return `${Math.floor(s / 60)}m`;
  if (s < 86400) return `${Math.floor(s / 3600)}h`;
  if (s < 86400 * 30) return `${Math.floor(s / 86400)}d`;
  if (s < 86400 * 365) return `${Math.floor(s / 86400 / 30)}mo`;
  return `${Math.floor(s / 86400 / 365)}y`;
}

function reviewBadge(decision) {
  switch (decision) {
    case "APPROVED":
      return { text: "APPROVED", color: "done" };
    case "CHANGES_REQUESTED":
      return { text: "CHANGES", color: "blocked" };
    case "REVIEW_REQUIRED":
      return { text: "REVIEW", color: "muted" };
    default:
      return null;
  }
}

function checkBadge(item) {
  const checks = item.statusCheckRollup ?? [];
  if (!checks.length) return null;
  let failing = 0;
  let pending = 0;
  for (const check of checks) {
    const conclusion = String(check.conclusion ?? "").toUpperCase();
    const status = String(check.status ?? "").toUpperCase();
    if (
      ["FAILURE", "TIMED_OUT", "CANCELLED", "ACTION_REQUIRED", "STARTUP_FAILURE"].includes(
        conclusion,
      )
    ) {
      failing += 1;
    } else if (!conclusion || (status && status !== "COMPLETED")) {
      pending += 1;
    }
  }
  if (failing) return { text: `${failing} failing`, color: "blocked" };
  if (pending) return { text: `${pending} pending`, color: "working" };
  return { text: "checks", color: "done" };
}

export default class RepoHub extends View {
  init(_props, cx) {
    this.tab = "pr";
    this.repo = null;
    this.root = null;
    this.prs = [];
    this.issues = [];
    this.error = null;
    this.loading = false;
    this.cwd = null;
    this.on = null;
    this.expanded = new Set();
    this.childrenOf = new Map();
    this.issueIndex = new Map();
    this.roots = [];
    this.prChildrenOf = new Map();
    this.prRoots = [];
    this.prByNumber = new Map();
    this.prLinks = new Map(); // issue number -> its pull requests
    this.prIssueLinks = new Map(); // pr number -> [{ ref, issue }]
    this.stacks = new Map(); // pr number -> its stack
    this.details = {};
    this.detailLoading = {};
    this.job = 0;
    // Issues are grouped under their umbrella by default, pull requests under
    // their stack; a plain list is one click away per tab and remembers the
    // choice. The search box filters the tab you are on, and each tab keeps
    // what was typed in it.
    let savedFlat = null;
    try {
      savedFlat = JSON.parse(localStorage.getItem("flat") ?? "null");
    } catch {
      savedFlat = null;
    }
    this.flat =
      savedFlat && typeof savedFlat === "object"
        ? { pr: Boolean(savedFlat.pr), issues: Boolean(savedFlat.issues) }
        : { pr: false, issues: savedFlat === 1 || savedFlat === "1" };
    this.queries = { pr: "", issues: "" };
    this.query = "";
    this.searchFocused = false;
    this.search = InputState.new({ placeholder: "Search #id or title" });
    this.search.on("change", (_e, cx) => {
      this.queries[this.tab] = this.search.value();
      this.query = this.queries[this.tab];
      cx.notify();
    });
    this.search.on("focus", (_e, cx) => {
      this.searchFocused = true;
      cx.notify();
    });
    this.search.on("blur", (_e, cx) => {
      this.searchFocused = false;
      cx.notify();
    });
    this.handle = cx.focus_handle();
    this.refresh(cx);
    cx.timer.every(60000, (cx) => this.refresh(cx));
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        if (command === "refresh") {
          this.forceRefresh(cx);
          cx.notify();
        }
      }
    });
  }

  // The focused terminal's folder and machine; when this panel has the
  // keyboard, keep the last folder that belonged to a terminal.
  location() {
    const f = focused();
    const pane = panes().find((p) => p.focused && p.cwd);
    const space = spaces().find((s) => s.active);
    let on = space?.machine ?? null;
    // A visible layout terminal block names its machine in the address; a
    // focused pane belongs to the shown space.
    if (f?.pane === null && f?.terminal) {
      on = f.terminal.includes("/") ? f.terminal.split("/")[0] : null;
    }
    return { cwd: f?.cwd || pane?.cwd || space?.folder || this.cwd, on };
  }

  refresh(cx, force = false) {
    const { cwd, on } = this.location();
    if (!cwd) {
      this.repo = null;
      this.prs = [];
      this.issues = [];
      this.childrenOf = new Map();
      this.issueIndex = new Map();
      this.roots = [];
      this.prChildrenOf = new Map();
      this.prRoots = [];
      this.prByNumber = new Map();
      this.prLinks = new Map();
      this.prIssueLinks = new Map();
      this.stacks = new Map();
      return;
    }
    this.cwd = cwd;
    this.on = on;
    if (this.loading && !force) return;
    const job = ++this.job;
    this.loading = true;
    this.error = null;
    cx.spawn(async (cx) => {
      try {
        const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on });
        if (top.code !== 0) throw new Error("Not a git repository");
        const root = top.stdout.trim();
        const remote = await exec("git", ["remote", "get-url", "origin"], { cwd: root, on });
        let repo = remote.code === 0 ? parseGithub(remote.stdout) : null;
        if (!repo) {
          const view = await exec(
            "gh",
            ["repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
            { cwd: root, on },
          );
          if (view.code === 0) repo = view.stdout.trim();
        }
        if (!repo) throw new Error("No GitHub repository for this folder");

        const [prs, rich, stacks] = await Promise.all([
          exec(
            "gh",
            ["pr", "list", "--repo", repo, "--limit", "30", "--json", PR_FIELDS],
            { cwd: root, on },
          ),
          exec(
            "gh",
            ["issue", "list", "--repo", repo, "--limit", "50", "--json", ISSUE_FIELDS],
            { cwd: root, on },
          ),
          this.loadStacks(repo, root, on),
        ]);
        // An older gh (or a host without sub-issues) rejects the newer fields:
        // ask again without them rather than losing the whole list.
        let issues = rich;
        if (
          rich.code !== 0 &&
          /unknown json field|doesn't exist|does not exist|not supported/i.test(
            rich.stderr ?? "",
          )
        ) {
          issues = await exec(
            "gh",
            ["issue", "list", "--repo", repo, "--limit", "50", "--json", ISSUE_FIELDS_PLAIN],
            { cwd: root, on },
          );
        }
        if (prs.code !== 0) throw new Error(prs.stderr.trim() || "gh pr list failed");
        if (issues.code !== 0) throw new Error(issues.stderr.trim() || "gh issue list failed");
        if (job !== this.job) return;

        if (this.repo !== repo) {
          this.expanded.clear();
          this.details = {};
          this.detailLoading = {};
          this.queries = { pr: "", issues: "" };
          this.query = "";
          this.search.set_value("");
        }
        this.repo = repo;
        this.root = root;
        this.prs = JSON.parse(prs.stdout);
        this.issues = JSON.parse(issues.stdout);
        this.stacks = stacks;
        this.groupIssues();
        this.linkPrs();
        this.groupPrs();
        this.error = null;
        this.reloadExpanded(cx);
      } catch (e) {
        if (job !== this.job) return;
        this.repo = null;
        this.prs = [];
        this.issues = [];
        this.childrenOf = new Map();
        this.issueIndex = new Map();
        this.roots = [];
        this.prChildrenOf = new Map();
        this.prRoots = [];
        this.prByNumber = new Map();
        this.prLinks = new Map();
        this.prIssueLinks = new Map();
        this.stacks = new Map();
        this.error = e?.message ?? String(e);
      } finally {
        if (job === this.job) {
          this.loading = false;
          cx.notify();
        }
      }
    });
  }

  forceRefresh(cx) {
    this.details = {};
    this.detailLoading = {};
    this.refresh(cx, true);
  }

  setTab(id, cx) {
    this.tab = id;
    this.query = this.queries[id] ?? "";
    this.search.set_value(this.query);
    cx.notify();
  }

  toggleFlat(cx) {
    this.flat[this.tab] = !this.flat[this.tab];
    localStorage.setItem("flat", JSON.stringify(this.flat));
    cx.notify();
  }

  clearSearch(cx) {
    this.queries[this.tab] = "";
    this.query = "";
    this.search.set_value("");
    cx.notify();
  }

  // What the search box shows for this tab, or null when it is empty. A number
  // matches ids (exact first), anything else matches titles.
  findItems(list) {
    const raw = this.query.trim().replace(/^#/, "");
    if (!raw) return null;
    const numeric = /^\d+$/.test(raw);
    const q = raw.toLowerCase();
    const hit = numeric
      ? (item) => String(item.number).startsWith(q)
      : (item) => (item.title ?? "").toLowerCase().includes(q);
    const exact = (item) => String(item.number) === q;
    return list
      .filter(hit)
      .sort((a, b) => Number(exact(b)) - Number(exact(a)));
  }

  searchRow(found, count, t) {
    return h_flex()
      .h(34)
      .flex_none()
      .px(8)
      .gap(6)
      .items_center()
      .border_b(1)
      .border_color(t.border)
      .child(svg("mods/workspace-chrome/search.svg").size(12).flex_none().text_color(t.dim))
      .child(
        div()
          .flex_1()
          .min_w(0)
          .child(
            Input.new(this.search)
              .h(24)
              .px(6)
              .rounded(6)
              .border_1()
              .border_color(this.searchFocused ? t.accent : t.input)
              .bg(t.background)
              .text_size(11)
              .text_color(t.foreground),
          ),
      )
      .when(Boolean(this.query), (e) =>
        e.child(
          div()
            .id("search-clear")
            .p(2)
            .rounded(4)
            .flex_none()
            .cursor_pointer()
            .text_color(t.dim)
            .hover((s) => s.bg(t.hover).text_color(t.foreground))
            .on_click((_e, cx) => this.clearSearch(cx))
            .child(svg("mods/workspace-chrome/x.svg").size(11).flex_none()),
        ),
      )
      .when(found !== null, (e) =>
        e.child(div().flex_none().text_size(9).text_color(t.dim).child(String(count))),
      );
  }

  // An umbrella issue carries its sub-issues as (open list) issues too: nest
  // them under it, open first, closed last and dimmed. Two levels are drawn;
  // anything deeper keeps its place in the top list, with a `↳ #parent` line,
  // so no issue disappears.
  groupIssues() {
    const open = new Map(this.issues.map((issue) => [issue.number, issue]));
    const childrenOf = new Map();
    const index = new Map(open);
    for (const issue of this.issues) {
      const nodes = issue.subIssues?.nodes ?? [];
      if (!nodes.length) continue;
      for (const node of nodes) if (!index.has(node.number)) index.set(node.number, node);
      const kids = nodes
        .map((node) => index.get(node.number) ?? node)
        .filter((kid) => kid.number !== issue.number)
        .sort(
          (a, b) =>
            Number(a.state === "CLOSED") - Number(b.state === "CLOSED") ||
            a.number - b.number,
        );
      if (kids.length) childrenOf.set(issue.number, kids);
    }

    // Only two levels are drawn: collect the issues placed there and leave
    // everything deeper (and orphans) in the top list.
    const placed = new Set();
    const place = (number, depth) => {
      for (const kid of childrenOf.get(number) ?? []) {
        if (placed.has(kid.number)) continue;
        placed.add(kid.number);
        if (depth < 2) place(kid.number, depth + 1);
      }
    };
    for (const issue of this.issues) {
      if (!issue.parent || !open.has(issue.parent.number)) place(issue.number, 1);
    }
    this.childrenOf = childrenOf;
    this.issueIndex = index;
    this.roots = this.issues.filter((issue) => !placed.has(issue.number));
  }

  // The stack containing each open PR, from one repository-wide call. A repo
  // without stacks (or a host that has none) answers 404 or []: no stacks.
  async loadStacks(repo, root, on) {
    try {
      const r = await exec("gh", ["api", `repos/${repo}/stacks?per_page=100`], {
        cwd: root,
        on,
      });
      if (r.code !== 0) return new Map();
      const list = JSON.parse(r.stdout);
      const map = new Map();
      for (const stack of Array.isArray(list) ? list : []) {
        const members = (stack.pull_requests ?? []).map((pr, i) => ({
          ...pr,
          position: i + 1,
        }));
        const entry = {
          number: stack.number,
          size: stack.size ?? members.length,
          members,
        };
        for (const member of members) {
          map.set(member.number, { ...entry, position: member.position });
        }
      }
      return map;
    } catch {
      return new Map();
    }
  }

  // Only links inside this repository: the sidebar shows one repo's list.
  sameRepoRef(ref) {
    const repository = ref?.repository;
    if (!repository?.owner?.login || !repository?.name) return true;
    return `${repository.owner.login}/${repository.name}` === this.repo;
  }

  // Both directions of the closing links: the issue list knows its pull
  // requests, the pull request list knows the issues it closes. Use the open
  // record when there is one for titles and checks, else the reference itself.
  linkPrs() {
    this.prByNumber = new Map(this.prs.map((pr) => [pr.number, pr]));
    this.prLinks = new Map();
    for (const issue of this.issues) {
      const refs = (issue.closedByPullRequestsReferences ?? []).filter((ref) =>
        this.sameRepoRef(ref),
      );
      if (!refs.length) continue;
      this.prLinks.set(
        issue.number,
        refs.map((ref) => this.prByNumber.get(ref.number) ?? ref),
      );
    }
    this.prIssueLinks = new Map();
    for (const pr of this.prs) {
      const refs = (pr.closingIssuesReferences ?? []).filter((ref) =>
        this.sameRepoRef(ref),
      );
      this.prIssueLinks.set(
        pr.number,
        refs.map((ref) => ({ ref, issue: this.issueIndex.get(ref.number) })),
      );
    }
  }

  // Stacked pull requests: the open members of a stack sit under its lowest
  // open member, like sub-issues under an umbrella. A stack whose other layers
  // are merged or outside the fetched list stays where it is.
  groupPrs() {
    const open = new Set(this.prs.map((pr) => pr.number));
    const childrenOf = new Map();
    const placed = new Set();
    const seen = new Set();
    for (const pr of this.prs) {
      const stack = this.stacks.get(pr.number);
      if (!stack || seen.has(stack.number)) continue;
      seen.add(stack.number);
      const present = stack.members
        .filter((member) => open.has(member.number))
        .sort((a, b) => a.position - b.position);
      if (present.length < 2) continue;
      const bottom = present[0];
      childrenOf.set(
        bottom.number,
        present.slice(1).map((member) => this.prByNumber.get(member.number) ?? member),
      );
      for (const member of present.slice(1)) placed.add(member.number);
    }
    this.prChildrenOf = childrenOf;
    this.prRoots = this.prs.filter((pr) => !placed.has(pr.number));
  }

  // A small link that opens another issue or pull request on GitHub.
  chip(text, color, url, t) {
    return div()
      .px(4)
      .py(1)
      .rounded(3)
      .bg(`${color}22`)
      .text_color(color)
      .text_size(9)
      .cursor_pointer()
      .hover((s) => s.text_color(t.foreground))
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .on_click((_e, cx) => {
        cx.stop_propagation();
        this.open(url);
      })
      .child(text);
  }

  // The issues a pull request closes, with the umbrella it belongs to.
  linkedIssues(links, t) {
    return v_flex()
      .w_full()
      .gap(3)
      .child(div().text_size(9).text_color(t.dim).child("LINKED ISSUES"))
      .children(
        links.map(({ ref, issue }) =>
          h_flex()
            .w_full()
            .gap(6)
            .items_center()
            .text_size(10)
            .child(this.chip(`#${ref.number}`, t.accent, ref.url, t))
            .child(
              div()
                .flex_1()
                .min_w(0)
                .truncate()
                .text_color(t.muted)
                .child(issue?.title ?? ""),
            )
            .when(Boolean(issue?.parent), (e) =>
              e.child(
                this.chip(
                  `↳ #${issue.parent.number}`,
                  t.dim,
                  issue.parent.url,
                  t,
                ),
              ),
            ),
        ),
      );
  }

  // The pull requests that close an issue, for the issue's own detail.
  linkedPrs(prs, t) {
    return v_flex()
      .w_full()
      .gap(3)
      .child(div().text_size(9).text_color(t.dim).child("PULL REQUESTS"))
      .children(
        prs.map((pr) =>
          h_flex()
            .w_full()
            .gap(6)
            .items_center()
            .text_size(10)
            .child(this.chip(`#${pr.number}`, t.accent, pr.url, t))
            .child(
              div()
                .flex_1()
                .min_w(0)
                .truncate()
                .text_color(t.muted)
                .child(pr.title ?? ""),
            ),
        ),
      );
  }

  // Every layer of a stack, bottom first.
  stackList(stack, current, t) {
    const members = [...stack.members].sort((a, b) => a.position - b.position);
    return v_flex()
      .w_full()
      .gap(3)
      .child(
        div()
          .text_size(9)
          .text_color(t.dim)
          .child(`STACK ${stack.number} · ${stack.size} PRs`),
      )
      .children(
        members.map((member) => {
          const pr = this.prByNumber.get(member.number);
          const state = member.merged_at ? "merged" : member.state;
          const here = member.number === current;
          return h_flex()
            .w_full()
            .gap(6)
            .items_center()
            .rounded(4)
            .px(3)
            .py(1)
            .when(here, (e) => e.bg(t.raised))
            .text_size(10)
            .child(
              div()
                .w(12)
                .flex_none()
                .text_color(t.dim)
                .child(String(member.position)),
            )
            .child(
              div()
                .flex_none()
                .text_color(here ? t.foreground : t.accent)
                .child(`#${member.number}`),
            )
            .child(
              div()
                .flex_1()
                .min_w(0)
                .truncate()
                .text_color(t.muted)
                .child(pr?.title ?? member.title ?? ""),
            )
            .when(Boolean(member.draft), (e) =>
              e.child(div().text_size(9).text_color(t.dim).child("draft")),
            )
            .when(state !== "open", (e) =>
              e.child(div().text_size(9).text_color(t.dim).child(state ?? "")),
            );
        }),
      );
  }

  // The sub-issues under an umbrella as a list: a small heading, then one row
  // each. Opening a row shows its detail and, one level down, its own list.
  subIssues(kids, t, cx, depth = 1) {
    const shown = kids.slice(0, 50);
    return v_flex()
      .w_full()
      .gap(1)
      .pt(2)
      .when(depth > 1, (e) => e.pl(10))
      .child(
        div()
          .pb(2)
          .text_size(9)
          .text_color(t.dim)
          .child("Sub-issues"),
      )
      .children(shown.map((kid) => this.subRow(kid, t, cx, depth)))
      .when(kids.length > shown.length, (e) =>
        e.child(
          div()
            .py(1)
            .text_size(9)
            .text_color(t.dim)
            .child(`… and ${kids.length - shown.length} more`),
        ),
      );
  }

  subRow(kid, t, cx, depth) {
    const key = `issues:${kid.number}`;
    const closed = String(kid.state ?? "").toUpperCase() === "CLOSED";
    const detailOpen = this.expanded.has(key);
    const kids = depth < 2 ? this.childrenOf.get(kid.number) : null;
    return v_flex()
      .w_full()
      .flex_none()
      .child(
        h_flex()
          .id(`issue-sub-${kid.number}`)
          .w_full()
          .h(23)
          .pl(2)
          .pr(2)
          .gap(6)
          .items_center()
          .rounded(5)
          .cursor_pointer()
          .hover((s) => s.bg(t.hover))
          .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
          .on_click((_e, cx) => {
            cx.stop_propagation();
            this.toggleCard(kid, "issues", cx);
          })
          .child(
            div()
              .w(10)
              .flex_none()
              .text_size(10)
              .text_color(closed ? t.done : t.dim)
              .child(closed ? "✓" : "○"),
          )
          .child(
            div()
              .flex_none()
              .text_size(10)
              .text_color(closed ? t.dim : t.accent)
              .when(!closed, (e) => e.underline())
              .when(closed, (e) => e.line_through())
              .cursor_pointer()
              .hover((s) => s.text_color(t.foreground))
              .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
              .on_click((_e, cx) => {
                cx.stop_propagation();
                this.open(kid.url);
              })
              .child(`#${kid.number}`),
          )
          .child(
            div()
              .flex_1()
              .min_w(0)
              .truncate()
              .text_size(11.5)
              .text_color(closed ? t.dim : t.muted)
              .child(kid.title ?? ""),
          )
          .when((this.prLinks.get(kid.number)?.length ?? 0) > 0, (e) =>
            e.child(
              div()
                .flex_none()
                .px(4)
                .rounded(3)
                .bg(`${t.accent}22`)
                .text_color(t.accent)
                .text_size(8)
                .child("PR"),
            ),
          ),
      )
      .when(detailOpen, (e) =>
        e.child(
          v_flex()
            .w_full()
            .when(Boolean(kids?.length), (el) =>
              el.child(this.subIssues(kids, t, cx, depth + 1)),
            )
            .child(this.detail(key, t, "issues", kid, depth > 1 ? 10 : 0)),
        ),
      );
  }

  reloadExpanded(cx) {
    for (const key of [...this.expanded]) {
      const [kind, number] = key.split(":");
      const item =
        kind === "pr"
          ? this.prs.find((x) => String(x.number) === number)
          : this.issueIndex.get(Number(number));
      if (!item) {
        this.expanded.delete(key);
        continue;
      }
      this.loadDetail(item, kind, cx, true);
    }
  }

  open(url) {
    const platform = window()?.platform;
    if (platform === "windows") {
      exec("cmd", ["/c", "start", "", url]).catch(() => {});
    } else {
      exec(platform === "macos" ? "open" : "xdg-open", [url]).catch(() => {});
    }
  }

  loadDetail(item, kind, cx, force = false) {
    const key = `${kind}:${item.number}`;
    if (force) {
      delete this.details[key];
      this.detailLoading[key] = false;
    } else if (this.details[key] || this.detailLoading[key]) {
      return;
    }
    const repo = this.repo;
    const root = this.root;
    const on = this.on;
    if (!repo) return;
    this.detailLoading[key] = true;
    cx.spawn(async (cx) => {
      try {
        const fields = kind === "pr" ? PR_DETAIL_FIELDS : ISSUE_DETAIL_FIELDS;
        const command = kind === "pr" ? "pr" : "issue";
        const r = await exec(
          "gh",
          [command, "view", String(item.number), "--repo", repo, "--json", fields],
          { cwd: root, on },
        );
        if (r.code !== 0) throw new Error((r.stderr || "gh view failed").trim());
        this.details[key] = JSON.parse(r.stdout);
      } catch (e) {
        this.details[key] = { error: e?.message ?? String(e) };
      } finally {
        this.detailLoading[key] = false;
        cx.notify();
      }
    });
  }

  toggleCard(item, kind, cx) {
    const key = `${kind}:${item.number}`;
    if (this.expanded.has(key)) {
      this.expanded.delete(key);
    } else {
      this.expanded.add(key);
      this.loadDetail(item, kind, cx);
    }
    cx.notify();
  }

  detail(key, t, kind, item) {
    const data = this.details[key];
    if (this.detailLoading[key] || !data) {
      return div()
        .p(8)
        .text_size(10)
        .text_color(t.dim)
        .child("Loading details…");
    }
    if (data.error) {
      return div().p(8).text_size(10).text_color(t.blocked).child(data.error);
    }
    const body = (data.body ?? "").trim();
    const text = body;
    const files = kind === "pr" ? (data.files ?? []) : [];
    const link = (url, label) =>
      div()
        .text_size(10)
        .text_color(t.accent)
        .underline()
        .cursor_pointer()
        .hover((s) => s.text_color(t.foreground))
        .on_click((_e, cx) => {
          cx.stop_propagation();
          this.open(url);
        })
        .child(label);
    return v_flex()
      .w_full()
      .p(8)
      .gap(6)
      .border_t(1)
      .border_color(t.border)
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .child(
        h_flex()
          .w_full()
          .gap(8)
          .items_center()
          .text_size(10)
          .text_color(t.muted)
          .when(kind === "pr" && data.headRefName, (e) =>
            e.child(`${data.headRefName} → ${data.baseRefName}`),
          )
          .when(kind === "pr", (e) =>
            e.child(
              `+${data.additions ?? 0} −${data.deletions ?? 0} · ${
                data.changedFiles ?? 0
              } files`,
            ),
          )
          .when(kind === "issues", (e) =>
            e.child(
              `${data.state ?? ""} · ${(data.comments ?? []).length} comments`,
            ),
          )
          .child(div().flex_1())
          .child(link(data.url ?? item.url, "GitHub ↗")),
      )
      .when(
        kind === "pr" && (this.prIssueLinks.get(item.number)?.length ?? 0) > 0,
        (e) => e.child(this.linkedIssues(this.prIssueLinks.get(item.number), t)),
      )
      .when(kind === "issues" && this.prLinks.has(item.number), (e) =>
        e.child(this.linkedPrs(this.prLinks.get(item.number), t)),
      )
      .child(
        TextView.markdown(`detail-${key}`, text || "No description.")
          .text_size(12)
          .text_color(t.foreground)
          .scrollable(false),
      )
      .when(kind === "pr" && files.length > 0, (e) =>
        e.child(
          v_flex()
            .w_full()
            .gap(4)
            .child(div().text_size(9).text_color(t.dim).child("FILES"))
            .child(
              v_flex()
                .w_full()
                .gap(2)
                .font_family(settings().font_family ?? "JetBrains Mono")
                .text_size(10)
                .children(
                  files.slice(0, 100).map((file) => {
                    const mark =
                      file.changeType === "ADDED"
                        ? "A"
                        : file.changeType === "DELETED"
                          ? "D"
                          : file.changeType === "RENAMED"
                            ? "R"
                            : file.changeType === "COPIED"
                              ? "C"
                              : "M";
                    const color =
                      mark === "A" ? t.ansi2 : mark === "D" ? t.ansi1 : t.muted;
                    return h_flex()
                      .w_full()
                      .h(18)
                      .gap(6)
                      .items_center()
                      .child(
                        div()
                          .w(10)
                          .flex_none()
                          .text_color(color)
                          .child(mark),
                      )
                      .child(
                        div()
                          .flex_1()
                          .min_w(0)
                          .truncate()
                          .text_color(t.muted)
                          .child(file.path),
                      )
                      .child(
                        div()
                          .flex_none()
                          .text_color(t.ansi2)
                          .child(`+${file.additions ?? 0}`),
                      )
                      .child(
                        div()
                          .flex_none()
                          .text_color(t.ansi1)
                          .child(`−${file.deletions ?? 0}`),
                      );
                  }),
                ),
            )
            .when(files.length > 100, (e) =>
              e.child(
                div()
                  .pt(2)
                  .text_size(9)
                  .text_color(t.dim)
                  .child(`… and ${files.length - 100} more files`),
              ),
            ),
        ),
      )
;
  }

  card(item, t, kind, cx) {
    const key = `${kind}:${item.number}`;
    const draft = kind === "pr" && item.isDraft;
    const review = kind === "pr" ? reviewBadge(item.reviewDecision) : null;
    const checks = kind === "pr" ? checkBadge(item) : null;
    const labels = kind === "issues" ? (item.labels ?? []).slice(0, 3) : [];
    const kids = kind === "issues" ? this.childrenOf.get(item.number) : null;
    const summary = kind === "issues" ? item.subIssuesSummary : null;
    const done = Boolean(summary?.total) && summary.completed >= summary.total;
    const linked = kind === "pr" ? this.prIssueLinks.get(item.number) ?? [] : [];
    const stack = kind === "pr" ? this.stacks.get(item.number) : null;
    const issuePrs = kind === "issues" ? this.prLinks.get(item.number) ?? [] : [];
    // A sub-issue shown on its own (its parent fell outside the fetched page,
    // or is a nested umbrella) says whose it is.
    const parent = kind === "issues" ? item.parent ?? null : null;
    const badge = (text, color) =>
      div()
        .px(5)
        .py(1)
        .rounded(3)
        .bg(`${color}22`)
        .text_color(color)
        .text_size(9)
        .child(text);
    return v_flex()
      .id(`${kind}-${item.number}`)
      .w_full()
      .flex_none()
      .p(9)
      .gap(5)
      .rounded(8)
      .border_1()
      .border_color(t.border)
      .bg(t.surface)
      .cursor_pointer()
      .hover((s) => s.bg(t.raised).border_color(t.input))
      .on_click((_e, cx) => this.toggleCard(item, kind, cx))
      .child(
        h_flex()
          .w_full()
          .gap(6)
          .items_center()
          .child(
            div()
              .text_size(10)
              .text_color(t.accent)
              .underline()
              .cursor_pointer()
              .hover((s) => s.text_color(t.foreground))
              .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
              .on_click((_e, cx) => {
                cx.stop_propagation();
                this.open(item.url);
              })
              .child(`#${item.number}`),
          )
          .when(draft, (e) => e.child(badge("DRAFT", t.dim)))
          .when(Boolean(review), (e) =>
            e.child(badge(review.text, t[review.color] ?? t.dim)),
          )
          .when(linked.length > 0, (e) =>
            e.child(
              this.chip(`#${linked[0].ref.number}`, t.accent, linked[0].ref.url, t),
            ),
          )
          .when(Boolean(linked[0]?.issue?.parent), (e) =>
            e.child(
              this.chip(
                `↳ #${linked[0].issue.parent.number}`,
                t.dim,
                linked[0].issue.parent.url,
                t,
              ),
            ),
          )
          .when(linked.length > 1, (e) =>
            e.child(
              div().text_size(9).text_color(t.dim).child(`+${linked.length - 1}`),
            ),
          )
          .when(Boolean(stack), (e) =>
            e.child(
              this.chip(
                `stack ${stack.position}/${stack.size}`,
                t.muted,
                item.url,
                t,
              ),
            ),
          )
          .when(Boolean(summary?.total), (e) =>
            e.child(
              badge(
                `${summary.completed}/${summary.total}`,
                done ? t.done : t.muted,
              ),
            ),
          )
          .child(div().flex_1())
          .child(div().text_size(10).text_color(t.dim).child(timeAgo(item.updatedAt))),
      )
      .child(div().text_size(12.5).text_color(t.foreground).child(item.title))
      .child(
        h_flex()
          .w_full()
          .gap(6)
          .items_center()
          .flex_wrap()
          .child(
            div()
              .text_size(10)
              .text_color(t.dim)
              .child(`@${item.author?.login ?? "ghost"}`),
          )
          .when(Boolean(checks), (e) =>
            e.child(
              div()
                .text_size(10)
                .text_color(t[checks.color] ?? t.dim)
                .child(checks.text),
            ),
          )
          .when(kind === "issues" && item.comments > 0, (e) =>
            e.child(
              div()
                .text_size(10)
                .text_color(t.dim)
                .child(`${item.comments} comments`),
            ),
          )
          .when(kind === "issues" && issuePrs.length > 0, (e) =>
            e.child(
              this.chip(`PR #${issuePrs[0].number}`, t.accent, issuePrs[0].url, t),
            ),
          )
          .when(kind === "issues" && issuePrs.length > 1, (e) =>
            e.child(
              div()
                .text_size(9)
                .text_color(t.dim)
                .child(`+${issuePrs.length - 1}`),
            ),
          )
          .when(Boolean(parent), (e) =>
            e.child(
              div()
                .text_size(9)
                .text_color(t.dim)
                .child(`↳ #${parent.number}`),
            ),
          )
          .children(
            labels.map((label) =>
              div()
                .px(5)
                .py(1)
                .rounded(3)
                .bg(`#${label.color}22`)
                .text_color(`#${label.color}`)
                .text_size(9)
                .child(label.name),
            ),
          ),
      )
      .when(this.expanded.has(key), (e) =>
        e.child(
          v_flex()
            .w_full()
            .when(Boolean(kids?.length), (el) =>
              el.child(this.subIssues(kids, t, cx)),
            )
            .when(kind === "pr" && Boolean(stack), (el) =>
              el.child(this.stackList(stack, item.number, t)),
            )
            .child(this.detail(key, t, kind, item)),
        ),
      );
  }

  tabButton(id, icon, count, t) {
    const on = this.tab === id;
    return h_flex()
      .id(`tab-${id}`)
      .h(26)
      .px(8)
      .gap(5)
      .items_center()
      .rounded(6)
      .cursor_pointer()
      .when(on, (e) => e.bg(t.selected))
      .text_color(on ? t.foreground : t.muted)
      .hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => this.setTab(id, cx))
      .child(svg(icon).size(14).flex_none())
      .when(count > 0, (e) =>
        e.child(
          div()
            .text_size(9)
            .text_color(on ? t.muted : t.dim)
            .child(String(count)),
        ),
      );
  }

  render(cx) {
    const { cwd, on } = this.location();
    if (cwd && (cwd !== this.cwd || on !== this.on)) {
      this.cwd = cwd;
      this.on = on;
      this.refresh(cx);
    }
    const t = theme();
    const panel = Boolean(props()?.panel);
    const all = this.tab === "pr" ? this.prs : this.issues;
    const flat = Boolean(this.flat[this.tab]);
    const found = this.findItems(all);
    const items = found ?? (flat ? all : this.tab === "pr" ? this.prRoots : this.roots);
    const canGroup =
      this.tab === "pr" ? this.prChildrenOf.size > 0 : this.childrenOf.size > 0;

    return v_flex()
      .id("repo-hub")
      .size_full()
      .min_h(0)
      .bg(panel ? t.surface : t.background)
      .when(panel, (e) =>
        e.rounded(10).border_1().border_color(t.border).overflow_hidden(),
      )
      .text_color(t.foreground)
      .text_size(12)
      .track_focus(this.handle)
      .on_key_down((e, cx) => {
        if (e.key === "escape" && this.query) {
          this.clearSearch(cx);
          cx.stop_propagation();
        }
      })
      .child(
        h_flex()
          .h(42)
          .flex_none()
          .px(12)
          .gap(8)
          .items_center()
          .border_b(1)
          .border_color(t.border)
          .child(div().font_semibold().child("PR / Issues"))
          .child(
            div()
              .flex_1()
              .min_w(0)
              .truncate()
              .text_size(11)
              .text_color(this.repo ? t.muted : t.dim)
              .when(Boolean(this.repo), (e) =>
                e.cursor_pointer().on_click(() =>
                  this.open(`https://github.com/${this.repo}`),
                ),
              )
              .child(this.repo ?? "No repository"),
          )
          .child(
            div()
              .id("refresh")
              .size(24)
              .flex()
              .items_center()
              .justify_center()
              .rounded(6)
              .cursor_pointer()
              .text_color(t.muted)
              .hover((s) => s.bg(t.hover))
              .on_click((_e, cx) => this.forceRefresh(cx))
              .child(this.loading ? "…" : "↻"),
          ),
      )
      .child(
        h_flex()
          .h(38)
          .flex_none()
          .px(8)
          .gap(4)
          .items_center()
          .border_b(1)
          .border_color(t.border)
          .child(this.tabButton("pr", "repo-hub-icons/pull-request.svg", this.prs.length, t))
          .child(this.tabButton("issues", "repo-hub-icons/issue.svg", this.issues.length, t))
          .child(div().flex_1())
          .when(canGroup, (e) =>
            e.child(
              div()
                .id("view-mode")
                .flex_none()
                .p(2)
                .rounded(4)
                .cursor_pointer()
                .text_color(t.dim)
                .tooltip(flat ? "Grouped list" : "Flat list")
                .hover((s) => s.bg(t.hover).text_color(t.foreground))
                .on_click((_e, cx) => this.toggleFlat(cx))
                .child(
                  svg(
                    `mods/workspace-chrome/${flat ? "files" : "layers"}.svg`,
                  )
                    .size(13)
                    .flex_none(),
                ),
            ),
          )
          .child(
            div()
              .text_size(10)
              .text_color(t.dim)
              .child(this.loading ? "Syncing…" : "60s"),
          ),
      )
      .child(this.searchRow(found, items.length, t))
      .child(
        v_flex()
          .id("list")
          .flex_1()
          .min_h(0)
          .overflow_y_scrollbar()
          .p(8)
          .gap(8)
          .when(Boolean(this.error), (e) =>
            e.child(div().p(12).text_color(t.blocked).child(this.error)),
          )
          .when(!this.error && !this.repo && !this.loading, (e) =>
            e.child(
              div()
                .p(12)
                .text_color(t.muted)
                .child("Focus a terminal inside a GitHub repository."),
            ),
          )
          .when(!this.error && Boolean(this.repo) && !items.length && !this.loading, (e) =>
            e.child(
              div()
                .p(12)
                .text_color(t.muted)
                .child(
                  found !== null
                    ? "No matches."
                    : this.tab === "pr"
                      ? "No open pull requests."
                      : "No open issues.",
                ),
            ),
          )
          .children(items.map((item) => this.card(item, t, this.tab, cx))),
      );
  }
}
