## npc-role (§3.2, D22): a service NPC standing at its building's door. A StaticBody3D capsule in group "npcs" with
## no HP, so strikes never find it (c-hostile-in-city); `role` = npc-roles.json id, resolved by player.gd#interact_nearest.
## ponytail: no schedule, dialogue or appearance (gen-schedule, gen-npc-appearance).
extends StaticBody3D

var role: StringName
var display_name := ""

func _init(p_role: StringName, p_name: String, color: Color) -> void:
	role = p_role; display_name = p_name
	var cs := CollisionShape3D.new(); var cap := CapsuleShape3D.new()
	cap.radius = 0.4; cap.height = 1.8; cs.shape = cap; cs.position.y = 0.9; add_child(cs)
	var m := MeshInstance3D.new(); var mesh := CapsuleMesh.new()
	mesh.radius = 0.4; mesh.height = 1.8; m.mesh = mesh; m.position.y = 0.9
	m.material_override = StandardMaterial3D.new(); m.material_override.albedo_color = color; add_child(m)
	add_to_group("npcs")
