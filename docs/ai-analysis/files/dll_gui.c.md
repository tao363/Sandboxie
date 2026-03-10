# dll/gui.c 系列 — GUI Hook

拦截 Win32 GUI API，实现窗口隔离和沙箱标记。

## 文件职责

| 文件 | 职责 |
|------|------|
| `gui.c` | 核心初始化 |
| `guimsg.c` | SendMessage/PostMessage 拦截 |
| `guienum.c` | EnumWindows/FindWindow 过滤 |
| `guititle.c` | 窗口标题添加 [BoxName] 标记 |
| `guidde.c` | DDE 隔离 |
| `gdi.c` | GDI 对象控制 |

## 主要功能

- 窗口标题标记：`"Notepad"` → `"Notepad [DefaultBox]"`
- 枚举过滤：默认只返回同沙箱内窗口
- 消息隔离：阻止向沙箱外窗口发送危险消息
- 剪贴板：通过 `API_GUI_CLIPBOARD` IOCTL 控制（`OpenClipboard=y/n`）
