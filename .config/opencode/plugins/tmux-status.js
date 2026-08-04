export const TmuxStatusPlugin = async ({ $ }) => {
  return {
    "session.idle": async () => {
      await $`sh ~/.tmux/agent-status.sh idle`.quiet();
    },
    "tool.execute.before": async () => {
      await $`sh ~/.tmux/agent-status.sh working`.quiet();
    },
    "session.error": async () => {
      await $`sh ~/.tmux/agent-status.sh blocked`.quiet();
    },
  };
};
