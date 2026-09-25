extends RefCounted

## 目录里的资源清单工具。
##
## 编辑器里 res://monsters/ 下看到的是 bagon.tres；导出成 exe 之后，Godot 会把 .tres
## 重新打包成二进制资源，目录里只剩下 bagon.tres.remap（文件内容是真正资源的路径）。
## 按 ".tres" 结尾过滤的话，导出版一条都读不到 —— 导出的游戏只剩教程三怪、食材和
## 料理全空，就是这个原因。
##
## 这里两种后缀都认，把 ".remap" 去掉以后再交给 load()。


static func list_resource_paths(dir_path: String) -> PackedStringArray:
	var paths := PackedStringArray()
	var dir := _open(dir_path)
	if dir == null:
		push_warning("ResourceDir: 打不开 %s，本次读不到任何资源。" % dir_path)
		return paths

	for file_name in dir.get_files():
		var name := file_name.trim_suffix(".remap")
		if not name.ends_with(".tres") and not name.ends_with(".res"):
			continue
		paths.append("%s/%s" % [dir_path.trim_suffix("/"), name])

	return paths


static func _open(dir_path: String) -> DirAccess:
	var dir := DirAccess.open(dir_path)
	if dir == null and not dir_path.ends_with("/"):
		dir = DirAccess.open(dir_path + "/")
	return dir
