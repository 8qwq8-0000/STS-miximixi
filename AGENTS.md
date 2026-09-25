# AGENTS.md —— 这个 Godot 项目的交接须知

先读 [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md)：里面有目录职责、关键数据文件、已实现系统、
导出注意和常用命令。下面只是必须记住的硬规则。

1. **工程根就是这里**（`mygame`）。旧目录 `deck_builder_tutorial-main` 已废弃，不要再去改。
2. **加载资源只用导出安全的方式**：不要写「扫目录 + 只认 `.tres`」的代码，导出版里目录条目是
   `xxx.tres.remap`，那种写法会读到 0 个文件。统一用
   `ResourceFiles.list_resource_paths()`（`custom_resources/resource_dir.gd`）。
3. 改完数据类/加载类代码，跑一次自检探针确认没读空：
   `godot --headless --path <本目录> res://_cn_tools/roster_probe.tscn`
   （正常输出 37 只怪 / 43 种食材 / 29 道料理）。
4. 注释、文档、提交信息一律用中文；提交信息风格 `【存档】……`。Git 仓库在 `D:\cangku\.git`，
   命令用 `git -c safe.directory=* -C <本目录> …`。
5. 不要动 `.gitignore` 里忽略的本机文件（`字体/`、`_cn_tools/`、`export_presets.cfg`、
   `pokemon名单_含种族值.xlsx`、`尖塔饭.zip`）。
6. 美术资源放 `art/` 对应子目录，缺图先用 `art/占位符.png`，用的时候都要缩放到合适大小。
