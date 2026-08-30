import { execFile } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";

const statusScript = join(homedir(), ".tmux", "agent-status.sh");

const updateStatus = (status) =>
  new Promise((resolve, reject) => {
    execFile("sh", [statusScript, status], (error) => {
      if (error) {
        reject(error);
        return;
      }
      resolve();
    });
  });

export default {
  id: "tmux-status-tui",
  setup(context) {
    const belongsToCurrentLocation = (event) =>
      !context.location || event.location?.directory === context.location.directory;

    const stops = [
      context.data.on("session.execution.started", (event) => {
        if (belongsToCurrentLocation(event)) void updateStatus("working");
      }),
      context.data.on("session.execution.failed", (event) => {
        if (belongsToCurrentLocation(event)) void updateStatus("blocked");
      }),
      context.data.on("session.execution.succeeded", (event) => {
        if (belongsToCurrentLocation(event)) void updateStatus("idle");
      }),
      context.data.on("session.execution.interrupted", (event) => {
        if (belongsToCurrentLocation(event)) void updateStatus("idle");
      }),
    ];

    return () => {
      for (const stop of stops) stop();
    };
  },
};
