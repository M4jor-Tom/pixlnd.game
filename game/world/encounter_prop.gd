## Collision-bearing furnishing, deliberately not a combat entity or DOT target.
extends StaticBody3D
var contents
var key: String


func take_direct_damage(amount: float, from: Node) -> void:
	contents.damage_prop(key, amount, from)
