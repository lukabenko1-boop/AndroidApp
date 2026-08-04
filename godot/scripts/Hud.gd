extends Control
class_name Hud
## Immediate-mode HUD: health / ki / overcharge bars, names, form labels, and
## the title / round-start / K.O. overlays. Mirrors the web build's HUD.

var p1 : Fighter
var p2 : Fighter
var state := "title"
var winner : Fighter
var ko_timer := 0.0
var intro_t := 0.0
var font : Font

func _ready() -> void:
	font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _bar(x: float, y: float, w: float, h: float, frac: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), Color(0.04, 0.055, 0.1, 0.72))
	draw_rect(Rect2(x + 2, y + 2, (w - 4) * clampf(frac, 0.0, 1.0), h - 4), c)
	draw_rect(Rect2(x, y, w, h), Color(1, 1, 1, 0.15), false, 1.0)

func _label(cx: float, y: float, text: String, size: int, col: Color) -> void:
	draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, cx, size, col)

func _draw() -> void:
	var vs := get_viewport_rect().size
	if p1 != null and p2 != null:
		_bar(24, 26, 300, 22, p1.hp / 100.0, Color(0.37, 0.88, 0.54))
		_bar(24, 52, 240, 11, p1.ki / 100.0, Color(0.37, 0.69, 1.0))
		if p1.overcharge > 2.0: _bar(24, 65, 240, 6, p1.overcharge / 100.0, Color(1, 0.88, 0.44))
		_bar(vs.x - 324, 26, 300, 22, p2.hp / 100.0, Color(1, 0.56, 0.42))
		_bar(vs.x - 264, 52, 240, 11, p2.ki / 100.0, Color(0.75, 0.56, 1.0))
		if p2.overcharge > 2.0: _bar(vs.x - 264, 65, 240, 6, p2.overcharge / 100.0, Color(1, 0.88, 0.44))
		draw_string(font, Vector2(24, 20), p1.fighter_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
		draw_string(font, Vector2(vs.x - 200, 20), p2.fighter_name, HORIZONTAL_ALIGNMENT_RIGHT, 176, 15, Color.WHITE)
		_form_label(p1, 24, false)
		_form_label(p2, vs.x - 200, true)
	if state == "playing" and intro_t > 0.0:
		_label(vs.x, vs.y * 0.5, "ROUND START", 46, Color(1, 0.88, 0.44))
	elif state == "title":
		draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.02, 0.03, 0.06, 0.5))
		_label(vs.x, vs.y * 0.32, "KI BLOBS 3D", 64, Color(1, 0.89, 0.48))
		_label(vs.x, vs.y * 0.32 + 40, "AERIAL BRAWL", 24, Color(0.48, 0.82, 1.0))
		_label(vs.x, vs.y * 0.55, "PRESS SPACE / TAP A BUTTON TO FIGHT", 20, Color.WHITE)
	elif state == "ko":
		draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.02, 0.03, 0.06, 0.5))
		var win := winner == p1
		_label(vs.x, vs.y * 0.46, "K.O.  " + ("YOU WIN!" if win else "YOU LOSE"), 54,
			Color(0.37, 0.88, 0.54) if win else Color(1, 0.42, 0.48))
		if ko_timer > 0.8:
			_label(vs.x, vs.y * 0.46 + 44, "PRESS SPACE / TAP TO REMATCH", 20, Color.WHITE)

func _form_label(f: Fighter, x: float, right: bool) -> void:
	var lbl := ""
	var col := Color(0.62, 0.82, 1.0)
	if f.form > 0:
		lbl = Fighter.FORMS[f.form].n
		col = f.aura_color()
	elif f.overcharge >= 100.0:
		lbl = "TRANSFORM! (T)"; col = Color(1, 0.88, 0.44)
	elif f.overcharge > 2.0:
		lbl = "SURGE"; col = Color(1, 0.88, 0.44)
	elif f.tier > 0:
		lbl = "CHARGE %d" % f.tier
	var al := HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	if lbl != "":
		draw_string(font, Vector2(x, 88), lbl, al, 176 if right else -1, 13, col)
	# LBZ scouter-style power readout
	var pcol := Color(1, 0.75, 0.48) if f.power_level() > 3.4 else Color(0.56, 0.69, 0.85)
	draw_string(font, Vector2(x, 104), "PWR %d" % int(round(f.power_level() * 1000.0)), al, 176 if right else -1, 13, pcol)
