# Godot MCP Setup (VS Code)

This project is configured to run a Node-based MCP server from VS Code and connect it to the Godot MCP WebSocket server started by the `godot_mcp` addon.

## How It Works

- Godot addon listens on the port in `addons/godot_mcp/mcp_server.gd`.
- VS Code starts the MCP server defined in `.vscode/mcp.json`.
- `.vscode/start-godot-mcp.js` reads the Godot port from `mcp_server.gd` and sets:
  - `GODOT_WS_URL=ws://127.0.0.1:<port>`
- Then it launches the Node MCP entrypoint.

This means you only set the port once in Godot, and VS Code uses the same port automatically.

## Prerequisites

- Node.js installed and available on `PATH`
- VS Code with GitHub Copilot Chat that supports MCP
- Godot project includes `addons/godot_mcp`
- A built Node MCP server entrypoint (`server/dist/index.js`) in your `godot-mcp` repo

## 1. Choose MCP Server Path

Set one of these environment variables:

- Preferred: `GODOT_MCP_SERVER_ENTRY`
  - Full path to `index.js`
- Alternative: `GODOT_MCP_ROOT`
  - Path to your `godot-mcp` repo root

If neither is set, the launcher tries this fallback path:

- `../godot-mcp/server/dist/index.js` (relative to this project folder)

### Project-local env file (recommended)

This repo includes `.vscode/.env.example`.

1. Copy `.vscode/.env.example` to `.vscode/.env`
2. Set either `GODOT_MCP_SERVER_ENTRY` or `GODOT_MCP_ROOT`

`start-godot-mcp.js` automatically loads `.vscode/.env` and uses those values for this project.

Notes:

- `.vscode/.env` is ignored by git.
- `.vscode/.env` values override inherited system/user env vars for this launcher.

### PowerShell examples

```powershell
# Option A: Full entrypoint path
$env:GODOT_MCP_SERVER_ENTRY = "C:\Users\you\code\godot-mcp\server\dist\index.js"

# Option B: Repo root path
$env:GODOT_MCP_ROOT = "C:\Users\you\code\godot-mcp"
```

To persist environment variables on Windows, use System Properties > Environment Variables or your shell profile.

## 2. Set Project Port in Godot Addon

Edit `addons/godot_mcp/mcp_server.gd`:

```gdscript
var port := 9080
```

Use a different port per project to avoid conflicts when multiple projects run at the same time.

## 3. VS Code MCP Configuration

This project already includes `.vscode/mcp.json`:

```json
{
  "servers": {
    "godot-mcp-server": {
      "type": "stdio",
      "command": "node",
      "args": [
        "${workspaceFolder}/.vscode/start-godot-mcp.js"
      ]
    }
  },
  "inputs": []
}
```

No manual `GODOT_WS_URL` entry is needed.

## 4. Start and Use

1. Open this project in Godot and run/open the editor so the addon starts listening.
2. Open the same folder in VS Code.
3. Ensure the MCP-enabled Copilot experience is active in VS Code.
4. Start a Copilot chat that uses MCP tools.

If MCP is already running and you changed env vars/port, reload the VS Code window and restart Godot.

## Troubleshooting

- `Node MCP entrypoint not found`
  - Set `GODOT_MCP_SERVER_ENTRY` or `GODOT_MCP_ROOT` correctly.
- `Could not find 'var port := <number>'`
  - Keep a numeric `var port := ...` line in `addons/godot_mcp/mcp_server.gd`.
- Connection refused / no responses
  - Verify Godot addon is running and listening on the configured port.
  - Confirm no other process is using the same port.
- Multiple projects at once
  - Give each project a unique `var port` value.

## Copy To New Project (Quick Checklist)

1. Copy `addons/godot_mcp` into the new Godot project.
2. Copy `.vscode/mcp.json` and `.vscode/start-godot-mcp.js` into the new project.
3. Set a unique port in `addons/godot_mcp/mcp_server.gd`:

   ```gdscript
   var port := 9081
   ```

4. Ensure one of these is configured in your environment: `GODOT_MCP_SERVER_ENTRY`, `GODOT_MCP_ROOT`, or `.vscode/.env` (recommended).

5. Open the new project in Godot so the addon starts the WebSocket listener.
6. Open the same folder in VS Code and start using MCP in Copilot chat.

Tip: Keep a simple port map (project -> port) to avoid collisions when running multiple projects.

## Gameplay Modes

On launch, the project now opens `res://scenes/start_menu.tscn`, which lets the player choose one of two camera perspectives:

- Over-the-Shoulder (`res://scenes/main.tscn`)
  - Player-aligned third-person chase camera (locked behind/above the character).
- Free Rotate (`res://scenes/main_free_rotate.tscn`)
  - Third-person camera that orbits independently from player facing direction.

## Controls

- Movement:
  - `W` = move forward
  - `S` = move backward
  - `A` = turn left
  - `D` = turn right
  - `Shift` = sprint
- Free rotate camera mode:
  - Move mouse (while captured) = rotate camera
  - Left click = capture mouse
  - `Esc` = release mouse
