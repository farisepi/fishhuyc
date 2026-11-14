extends StorageRoom

const DUCT_TOP := 910.0
const DUCT_BOTTOM := 1000.0

func room_ready(_first: bool) -> void:
	var x0 = room_rect.position.x - 200.0
	var w = room_rect.size.x + 400.0
	var inner = ColorRect.new()
	inner.color = Color(0.13, 0.14, 0.15)
	inner.position = Vector2(x0, DUCT_TOP)
	inner.size = Vector2(w, DUCT_BOTTOM - DUCT_TOP)
	inner.z_index = -9
	add_child(inner)
	var x = room_rect.position.x
	while x < room_rect.end.x:
		var seam = ColorRect.new()
		seam.color = Color(0.07, 0.075, 0.08)
		seam.position = Vector2(x, DUCT_TOP)
		seam.size = Vector2(3, DUCT_BOTTOM - DUCT_TOP)
		seam.z_index = -8
		add_child(seam)
		for ry in [DUCT_TOP + 8.0, DUCT_BOTTOM - 12.0]:
			var rivet = ColorRect.new()
			rivet.color = Color(0.24, 0.25, 0.27)
			rivet.position = Vector2(x + 9.0, ry)
			rivet.size = Vector2(3, 3)
			rivet.z_index = -8
			add_child(rivet)
		x += 96.0
	var shine = ColorRect.new()
	shine.color = Color(0.3, 0.32, 0.34, 0.35)
	shine.position = Vector2(x0, DUCT_TOP + 4.0)
	shine.size = Vector2(w, 2)
	shine.z_index = -8
	add_child(shine)
	var above = ColorRect.new()
	above.color = Color(0.015, 0.015, 0.02)
	above.position = Vector2(x0, room_rect.position.y - 600.0)
	above.size = Vector2(w, DUCT_TOP - 40.0 - (room_rect.position.y - 600.0))
	above.z_index = 4
	add_child(above)
	var gx = room_rect.position.x + 300.0
	while gx < room_rect.end.x - 200.0:
		var light = PointLight2D.new()
		light.texture = preload("res://GameAssets/Sprites/UserInterfaceSprites/LightTextures/Light_Option10_Texture.png")
		light.texture_scale = 0.5
		light.color = Color(0.55, 0.75, 1.0)
		light.energy = 0.55
		light.position = Vector2(gx, DUCT_TOP + 10.0)
		add_child(light)
		var slot = ColorRect.new()
		slot.color = Color(0.5, 0.65, 0.8, 0.7)
		slot.position = Vector2(gx - 14.0, DUCT_TOP - 2.0)
		slot.size = Vector2(28, 3)
		slot.z_index = 6
		add_child(slot)
		gx += 380.0
