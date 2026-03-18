# MIT License

# Copyright (c) 2026-present Poing Studios

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

static func manage_visibility() -> void:
	var is_csharp_project := false
	var dir := DirAccess.open("res://")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.get_extension() == "csproj":
				is_csharp_project = true
				break
			file_name = dir.get_next()
	
	var csharp_gdignore_path := "res://addons/admob/csharp/.gdignore"
	if is_csharp_project:
		if FileAccess.file_exists(csharp_gdignore_path):
			DirAccess.remove_absolute(csharp_gdignore_path)
			print("AdMob: C# project detected, showing C# folder.")
	else:
		if not FileAccess.file_exists(csharp_gdignore_path):
			var file := FileAccess.open(csharp_gdignore_path, FileAccess.WRITE)
			if file:
				file.store_string("")
				file.close()
				print("AdMob: Non-C# project detected, hiding C# folder.")
