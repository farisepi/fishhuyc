extends Node
## Шутка для друзей: в собранной игре (не в редакторе) при запуске один раз ставит фото кота
## на рабочий стол Windows. Старые обои запоминаются, так что можно вернуть всё назад.
##   - только Windows;
##   - только экспортированная сборка (OS.has_feature("editor") == false), чтобы не трогать
##     свои обои при тестах в редакторе;
##   - срабатывает один раз на машину (флаг в user://), чтобы не менять обои каждый запуск;
##   - окно PowerShell скрыто, игра не ждёт его завершения.
## Откат: запусти рядом с игрой файл user://restore_wallpaper.bat (путь печатается в консоль),
## или вручную поставь обои обратно.

const IMG_RES := "res://GameAssets/Sprites/PrankSprites/cat_prank.jpg"
const DONE_FLAG := "user://.catprank_done"

func _ready() -> void:
	if OS.has_feature("editor"):
		return   # в редакторе не трогаем свои обои
	if OS.get_name() != "Windows":
		return
	if FileAccess.file_exists(DONE_FLAG):
		return
	call_deferred("_do_prank")

func _do_prank() -> void:
	# распаковать картинку из .pck в реальный файл на диске
	var src := FileAccess.open(IMG_RES, FileAccess.READ)
	if src == null:
		return
	var bytes := src.get_buffer(src.get_length())
	src.close()

	var dir := OS.get_user_data_dir()
	var img_path := dir.path_join("cat_prank.jpg")
	var out := FileAccess.open("user://cat_prank.jpg", FileAccess.WRITE)
	if out == null:
		return
	out.store_buffer(bytes)
	out.close()

	# PowerShell-скрипт: сохранить текущие обои, потом поставить кота
	var ps_path := dir.path_join("set_wallpaper.ps1")
	var ps := """
$sig = @'
using System.Runtime.InteropServices;
using System.Text;
public class Wp {
  [DllImport("user32.dll", CharSet=CharSet.Auto)]
  public static extern int SystemParametersInfo(int a, int u, string p, int f);
  [DllImport("user32.dll", CharSet=CharSet.Auto)]
  public static extern int SystemParametersInfo(int a, int u, StringBuilder p, int f);
}
'@
Add-Type $sig
$dir = "%DIR%"
$backup = Join-Path $dir "old_wallpaper.txt"
if (-not (Test-Path $backup)) {
  $sb = New-Object System.Text.StringBuilder 260
  [Wp]::SystemParametersInfo(0x0073, 260, $sb, 0) | Out-Null
  Set-Content -Path $backup -Value $sb.ToString()
}
[Wp]::SystemParametersInfo(0x0014, 0, "%IMG%", 0x01 -bor 0x02) | Out-Null
""".replace("%DIR%", dir).replace("%IMG%", img_path)

	var psf := FileAccess.open("user://set_wallpaper.ps1", FileAccess.WRITE)
	if psf == null:
		return
	psf.store_string(ps)
	psf.close()

	# откатный .bat рядом — вернуть прежние обои
	var restore := """@echo off
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command ^
  "$sig='using System.Runtime.InteropServices;public class Wp{[DllImport(\\"user32.dll\\",CharSet=CharSet.Auto)]public static extern int SystemParametersInfo(int a,int u,string p,int f);}';Add-Type $sig;$old=Get-Content '%DIR%\\old_wallpaper.txt';[Wp]::SystemParametersInfo(0x0014,0,$old,0x03)|Out-Null"
echo Wallpaper restored.
""".replace("%DIR%", dir)
	var bf := FileAccess.open("user://restore_wallpaper.bat", FileAccess.WRITE)
	if bf:
		bf.store_string(restore)
		bf.close()

	# запустить скрыто, не блокируя игру
	OS.create_process("powershell.exe", [
		"-NoProfile", "-ExecutionPolicy", "Bypass",
		"-WindowStyle", "Hidden", "-File", ps_path])

	# отметить, что уже сделано (чтобы не повторять каждый запуск)
	var flag := FileAccess.open(DONE_FLAG, FileAccess.WRITE)
	if flag:
		flag.store_string("1")
		flag.close()

	print("[prank] готово. откат: ", dir.path_join("restore_wallpaper.bat"))
