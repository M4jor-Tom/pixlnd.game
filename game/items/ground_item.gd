## zone.chunk-items (§3.1): a dropped item lying in the world. Area3D: bodies walking in auto-pick
## the types in design.loot.ground.auto-pickup (coins); the rest wait for `pick-up` (E) in range.
## Lives under its zone node so it unloads with it; else vanishes after lifetime-s (≈ 1 game week).
extends Area3D

var item
var label := ""
var _ttl := INF
var _auto: Array = []

func setup(p_item, p_label: String, color: Color, ground: Dictionary) -> void:
	item = p_item; label = p_label
	_ttl = float(ground["lifetime-s"]); _auto = ground["auto-pickup"]
	$Collision.shape.radius = float(ground["pickup-radius"])
	$Body.material_override = StandardMaterial3D.new(); $Body.material_override.albedo_color = color
	add_to_group("ground-items")
	body_entered.connect(_on_body_entered)

func _process(dt: float) -> void:
	rotate_y(dt)
	_ttl -= dt
	if _ttl <= 0.0:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if String(item.type) in _auto and body.has_method("pick_up"):
		body.pick_up(self)
