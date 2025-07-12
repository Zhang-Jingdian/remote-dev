# 远程容器开发环境 (VS Code 一体化版) 🚀

这个项目现在使用一个**极其简化**的开发流程，你不再需要任何手动同步脚本。所有操作都在 VS Code 中无缝完成。

## 🌟 核心优势

- **零手动同步**：VS Code 自动处理所有文件操作。
- **真正的远程开发**：代码直接在远程服务器上，本地只是一个操作终端。
- **极速响应**：由于你的服务器在局域网 (`192.168.0.104`)，体验会像在本地一样流畅。
- **环境隔离**：所有开发都在远程的 Docker 容器中进行，不污染任何本地或远程主机环境。

## 📋 一次性设置

1.  **安装 VS Code 扩展**：
    *   确保你已经安装了 [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) 扩展。

2.  **启动远程容器（首次）**：
    *   SSH 连接到你的远程服务器：
        ```bash
        ssh zjd
        ```
    *   进入项目目录并启动 Docker Compose 服务：
        ```bash
        cd /home/zjd/workspace
        docker-compose up -d
        ```
    *   你可以用 `docker ps` 来确认 `dev` 服务正在运行。
    *   完成后可以退出 SSH。

## 🚀 日常开发流程 (每天只需一步)

1.  **打开 VS Code**。
2.  按下 `F1` (或者 `Ctrl+Shift+P` / `Cmd+Shift+P`) 打开命令面板。
3.  输入并选择 **`Remote-SSH: Connect to Host...`**。
4.  选择你的主机 `zjd`。

    > VS Code 会打开一个新的窗口，并自动连接到你的远程服务器。

5.  在 VS Code 的文件浏览器中，打开文件夹 `/home/zjd/workspace`。
6.  VS Code 会在右下角**自动弹窗**，提示你：
    > "Folder contains a Dev Container configuration file. Reopen in Container."

7.  点击 **`Reopen in Container`**。

**完成！** 🎉

现在，你的 VS Code 已经连接到了**运行在远程服务器上的 Docker 容器内部**。

你在这里做的**任何文件修改都实时发生在远程服务器上**，你运行的任何命令也都在容器里。

## 🔧 开发工作流

*   **编辑代码**：直接在 VS Code 中修改 `src/` 下的文件。
*   **运行/调试**：直接使用 VS Code 的 "Run and Debug" 功能，或者在 VS Code 的集成终端中运行 `python src/main.py`。
*   **管理依赖**：在 VS Code 的终端里运行 `pip install <package>`，并更新 `requirements.txt`。
*   **使用 Git**：就像在本地一样，在 VS Code 的 Git 面板或者终端中使用 `git` 命令。

这个工作流完全利用了你现有的 SSH 配置，提供了最无缝的远程开发体验。你觉得怎么样？是不是简单多了？😊 