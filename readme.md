# MCBESM: Minecraft Bedrock Edition Server Manager

**MCBESM** is a modular, Bash-based CLI suite designed to deploy, manage, and orchestrate multiple Minecraft Bedrock Edition server instances on Linux. 

Built with a focus on automation and networking efficiency, this tool handles the entire lifecycle of a server—from dynamic API-based installation to background process management.

---

## 🚀 Key Features

- **Multi-Instance Orchestration**: Create and run multiple worlds simultaneously, each isolated in its own directory.
- **Smart Port Allocation**: Automatically detects occupied ports and assigns the next available pair. Implements a **+2 increment logic** to prevent collisions between IPv4 and IPv6 sockets.
- **Version Management & Pinning**: Supports downloading the latest stable release via the Minecraft API or pinning specific versions for stability.
- **Headless Configuration**: Edit `server.properties` directly from the CLI using `sed` automation—no text editor required.
- **Process Isolation**: Utilizes `GNU Screen` to run servers in detached background sessions, allowing for 24/7 uptime and easy console attachment.
- **Modular Architecture**: Built following the DRY (Don't Repeat Yourself) principle, separating logic (`core.sh`), UI styling (`ui.sh`), and environment variables (`mcbesm.conf`).

---

## 🛠️ Technical Stack

- **Language:** Bash (Shell Scripting)
- **Process Management:** GNU Screen
- **Data Retrieval:** Curl (with User-Agent spoofing for API access)
- **Stream Processing:** Sed, Grep, Awk (for config injection and status parsing)
- **Version Control:** Git & GitHub

---

## 📂 Project Structure

```text
mcbesm/
├── bin/mcbesm            # Main entry point (Executable)
├── lib/
│   ├── core.sh          # Backend logic (Start/Stop/Create/Config)
│   └── ui.sh            # UI Components (Colors, Tables, Icons)
├── config/mcbesm.conf    # Global environment settings
├── .cache/              # (Ignored) Stores server binaries
└── instances/           # (Ignored) Individual server world data
