#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");

function parseEnvFile(envFilePath) {
  if (!fs.existsSync(envFilePath)) {
    return {};
  }

  const out = {};
  const text = fs.readFileSync(envFilePath, "utf8");
  const lines = text.split(/\r?\n/);

  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) {
      continue;
    }

    const eq = line.indexOf("=");
    if (eq <= 0) {
      continue;
    }

    const key = line.slice(0, eq).trim();
    let value = line.slice(eq + 1).trim();

    // Strip matching single or double quotes.
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    out[key] = value;
  }

  return out;
}

function parsePortFromGodotServer(godotServerFile) {
  const text = fs.readFileSync(godotServerFile, "utf8");
  const match = text.match(/var\s+port\s*:?=\s*(\d+)/);
  if (!match) {
    throw new Error(
      `Could not find 'var port := <number>' in ${godotServerFile}`
    );
  }
  return Number(match[1]);
}

function resolveServerEntry(workspaceRoot, env) {
  if (env.GODOT_MCP_SERVER_ENTRY) {
    return env.GODOT_MCP_SERVER_ENTRY;
  }

  if (env.GODOT_MCP_ROOT) {
    return path.join(env.GODOT_MCP_ROOT, "server", "dist", "index.js");
  }

  // Convenience fallback for sibling repo layout: <parent>/godot-mcp
  return path.resolve(workspaceRoot, "..", "godot-mcp", "server", "dist", "index.js");
}

function main() {
  const workspaceRoot = process.cwd();
  const envFilePath = path.join(workspaceRoot, ".vscode", ".env");
  const envFromFile = parseEnvFile(envFilePath);
  const runtimeEnv = { ...process.env, ...envFromFile };

  const godotServerFile = path.join(
    workspaceRoot,
    "addons",
    "godot_mcp",
    "mcp_server.gd"
  );

  if (!fs.existsSync(godotServerFile)) {
    throw new Error(`Godot MCP server file not found: ${godotServerFile}`);
  }

  const port = parsePortFromGodotServer(godotServerFile);
  const wsUrl = `ws://127.0.0.1:${port}`;
  const serverEntry = resolveServerEntry(workspaceRoot, runtimeEnv);

  if (!fs.existsSync(serverEntry)) {
    throw new Error(
      [
        `Node MCP entrypoint not found: ${serverEntry}`,
        "Set GODOT_MCP_ROOT or GODOT_MCP_SERVER_ENTRY to a valid path.",
      ].join("\n")
    );
  }

  const child = spawn(
    process.execPath,
    ["--experimental-modules", serverEntry],
    {
      stdio: "inherit",
      env: {
        ...runtimeEnv,
        GODOT_WS_URL: wsUrl,
      },
    }
  );

  child.on("exit", (code, signal) => {
    if (signal) {
      process.kill(process.pid, signal);
      return;
    }
    process.exit(code ?? 1);
  });
}

try {
  main();
} catch (err) {
  console.error("[start-godot-mcp]", err.message);
  process.exit(1);
}
