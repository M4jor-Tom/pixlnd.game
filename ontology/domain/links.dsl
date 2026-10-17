// Explicit incidence and answer references only; no implied relationships or inheritance.
r_hazard = element "hazard" "EndpointTerm" {
    tags "EndpointTerm"
    properties {
        "id" "hazard"
        "definition-status" "source term without class definition"
    }
}
r_magic_crystal = element "magic-crystal" "EndpointTerm" {
    tags "EndpointTerm"
    properties {
        "id" "magic-crystal"
        "definition-status" "source term without class definition"
    }
}
r_dungeon = element "dungeon" "EndpointTerm" {
    tags "EndpointTerm"
    properties {
        "id" "dungeon"
        "definition-status" "source term without class definition"
    }
}
r_poi = element "poi" "EndpointTerm" {
    tags "EndpointTerm"
    properties {
        "id" "poi"
        "definition-status" "source term without class definition"
    }
}
r_elixir = element "elixir" "EndpointTerm" {
    tags "EndpointTerm"
    properties {
        "id" "elixir"
        "definition-status" "source term without class definition"
    }
}
r_mechanic = element "mechanic" "EndpointTerm" {
    tags "EndpointTerm"
    properties {
        "id" "mechanic"
        "definition-status" "source term without class definition"
    }
}
r_cq1 -> r_race "answered by" {
    properties {
        "reference-order" "001"
    }
}
r_cq1 -> r_character_class "answered by" {
    properties {
        "reference-order" "002"
    }
}
r_cq1 -> r_specialization "answered by" {
    properties {
        "reference-order" "003"
    }
}
r_cq1 -> r_appearance "answered by" {
    properties {
        "reference-order" "004"
    }
}
r_cq2 -> r_ability "answered by" {
    properties {
        "reference-order" "001"
    }
}
r_cq2 -> r_weapon_type "answered by" {
    properties {
        "reference-order" "002"
    }
}
r_cq2 -> r_resource "answered by" {
    properties {
        "reference-order" "003"
    }
}
r_cq2 -> r_control_action "answered by" {
    properties {
        "reference-order" "004"
    }
}
r_cq3 -> r_stat "answered by" {
    properties {
        "reference-order" "001"
    }
}
r_cq3 -> r_item "answered by" {
    properties {
        "reference-order" "002"
    }
}
r_cq3 -> r_level_formula "answered by" {
    properties {
        "reference-order" "004"
    }
}
r_cq4 -> r_landscape "answered by" {
    properties {
        "reference-order" "001"
    }
}
r_cq4 -> r_terrain_feature "answered by" {
    properties {
        "reference-order" "002"
    }
}
r_cq4 -> r_creature "answered by" {
    properties {
        "reference-order" "003"
    }
}
r_cq4 -> r_flora "answered by" {
    properties {
        "reference-order" "004"
    }
}
r_cq4 -> r_deposit "answered by" {
    properties {
        "reference-order" "005"
    }
}
r_cq4 -> r_dungeon_type "answered by" {
    properties {
        "reference-order" "006"
    }
}
r_cq4 -> r_poi_type "answered by" {
    properties {
        "reference-order" "007"
    }
}
r_cq4 -> r_spawns_in "answered by" {
    properties {
        "reference-order" "008"
    }
}
r_cq4 -> r_placed_in "answered by" {
    properties {
        "reference-order" "009"
    }
}
r_cq5 -> r_world "answered by" {
    properties {
        "reference-order" "001"
    }
}
r_cq5 -> r_zone "answered by" {
    properties {
        "reference-order" "002"
    }
}
r_cq5 -> r_land "answered by" {
    properties {
        "reference-order" "003"
    }
}
r_cq6 -> r_creature "answered by" {
    properties {
        "reference-order" "001"
    }
}
r_cq6 -> r_pet_food "answered by" {
    properties {
        "reference-order" "002"
    }
}
r_cq6 -> r_tamed_by "answered by" {
    properties {
        "reference-order" "003"
    }
}
r_cq6 -> r_drops "answered by" {
    properties {
        "reference-order" "004"
    }
}
r_cq7 -> r_item "answered by" {
    properties {
        "reference-order" "001"
    }
}
r_cq7 -> r_item_type "answered by" {
    properties {
        "reference-order" "002"
    }
}
r_cq7 -> r_material "answered by" {
    properties {
        "reference-order" "003"
    }
}
r_cq7 -> r_rarity "answered by" {
    properties {
        "reference-order" "004"
    }
}
r_cq7 -> r_affix "answered by" {
    properties {
        "reference-order" "005"
    }
}
r_cq8 -> r_recipe "answered by" {
    properties {
        "reference-order" "001"
    }
}
r_cq8 -> r_crafting_station "answered by" {
    properties {
        "reference-order" "002"
    }
}
r_cq8 -> r_shop "answered by" {
    properties {
        "reference-order" "003"
    }
}
r_cq8 -> r_formula "answered by" {
    properties {
        "reference-order" "004"
    }
}
r_cq8 -> r_book_of_crafting "answered by" {
    properties {
        "reference-order" "005"
    }
}
r_cq8 -> r_leftovers "answered by" {
    properties {
        "reference-order" "006"
    }
}
r_cq8 -> r_spirit_cube "answered by" {
    properties {
        "reference-order" "007"
    }
}
r_cq8 -> r_adaptation "answered by" {
    properties {
        "reference-order" "008"
    }
}
r_cq9 -> r_ruleset "answered by" {
    properties {
        "reference-order" "001"
    }
}
r_cq9 -> r_skill_tree "answered by" {
    properties {
        "reference-order" "002"
    }
}
r_cq9 -> r_artifact "answered by" {
    properties {
        "reference-order" "004"
    }
}
r_cq9 -> r_region_lock "answered by" {
    properties {
        "reference-order" "005"
    }
}
r_cq9 -> r_lore "answered by" {
    properties {
        "reference-order" "006"
    }
}
r_cq9 -> r_gnome_supplier "answered by" {
    properties {
        "reference-order" "007"
    }
}
r_cq10 -> r_mission_type "answered by" {
    properties {
        "reference-order" "001"
    }
}
r_cq10 -> r_arena "answered by" {
    properties {
        "reference-order" "002"
    }
}
r_cq10 -> r_rewards "answered by" {
    properties {
        "reference-order" "003"
    }
}
r_cq11 -> r_settlement "answered by" {
    properties {
        "reference-order" "001"
    }
}
r_cq11 -> r_district "answered by" {
    properties {
        "reference-order" "002"
    }
}
r_cq11 -> r_building "answered by" {
    properties {
        "reference-order" "003"
    }
}
r_cq11 -> r_npc_role "answered by" {
    properties {
        "reference-order" "004"
    }
}
r_cq11 -> r_shop "answered by" {
    properties {
        "reference-order" "005"
    }
}
r_cq12 -> r_hostility "answered by" {
    properties {
        "reference-order" "001"
    }
}
r_cq12 -> r_ai_behavior "answered by" {
    properties {
        "reference-order" "002"
    }
}
r_cq12 -> r_creature "answered by" {
    properties {
        "reference-order" "003"
    }
}
r_cq12 -> r_threat "answered by" {
    properties {
        "reference-order" "004"
    }
}
r_cq12 -> r_current_target "answered by" {
    properties {
        "reference-order" "005"
    }
}
r_cq13 -> r_status_effect "answered by" {
    properties {
        "reference-order" "001"
    }
}
r_cq13 -> r_applies "answered by" {
    properties {
        "reference-order" "002"
    }
}
r_cq14 -> r_game_clock "answered by" {
    properties {
        "reference-order" "001"
    }
}
r_cq15 -> r_save_data "answered by" {
    properties {
        "reference-order" "001"
    }
}
r_cq15 -> r_world "answered by" {
    properties {
        "reference-order" "002"
    }
}
r_cq15 -> r_player_character "answered by" {
    properties {
        "reference-order" "003"
    }
}
r_cq16 -> r_multiplayer_mode "answered by" {
    properties {
        "reference-order" "001"
    }
}
r_cq16 -> r_slash_command "answered by" {
    properties {
        "reference-order" "002"
    }
}
r_cq17 -> r_hud_element "answered by" {
    properties {
        "reference-order" "001"
    }
}
r_cq17 -> r_input_binding "answered by" {
    properties {
        "reference-order" "002"
    }
}
r_cq17 -> r_option "answered by" {
    properties {
        "reference-order" "003"
    }
}
r_cq18 -> r_ruleset "answered by" {
    properties {
        "reference-order" "001"
    }
}
r_character_class -> r_has_specialization "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_has_specialization -> r_specialization "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_character_class -> r_uses_weapon "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_uses_weapon -> r_weapon_type "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_character_class -> r_wears_material "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_wears_material -> r_material "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_specialization -> r_grants_ability "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_character_class -> r_grants_ability "domain member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_grants_ability -> r_ability "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_ability -> r_unlocks_next "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_unlocks_next -> r_ability "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_ability -> r_invoked_by_control "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_invoked_by_control -> r_control_action "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_control_action -> r_bound_to_input "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_bound_to_input -> r_input_binding "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_controller_profile -> r_has_input_binding "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_has_input_binding -> r_input_binding "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_ability -> r_costs "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_costs -> r_resource "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_ability -> r_applies "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_weapon_type -> r_applies "domain member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_hazard -> r_applies "domain member" {
    properties {
        "member-order" "003"
        "qualifier.state" "empty-cell"
    }
}
r_applies -> r_status_effect "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_weapon_type -> r_has_moveset "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_has_moveset -> r_ability "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "text"
        "qualifier.text" "(basic, special)"
    }
}
r_player_character -> r_knows_recipe "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_knows_recipe -> r_recipe "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_recipe -> r_crafted_at "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_crafted_at -> r_crafting_station "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_recipe -> r_consumes "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_consumes -> r_ingredient "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_consumes -> r_material "range member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_recipe -> r_produces "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_produces -> r_item_type "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_produces -> r_consumable "range member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_ingredient -> r_refines_to "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_refines_to -> r_ingredient "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_flora -> r_yields "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_deposit -> r_yields "domain member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_creature -> r_yields "domain member" {
    properties {
        "member-order" "003"
        "qualifier.state" "empty-cell"
    }
}
r_yields -> r_ingredient "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_creature -> r_spawns_in "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_flora -> r_spawns_in "domain member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_deposit -> r_spawns_in "domain member" {
    properties {
        "member-order" "003"
        "qualifier.state" "empty-cell"
    }
}
r_spawns_in -> r_landscape "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_spawns_in -> r_terrain_feature "range member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_spawns_in -> r_dungeon_type "range member" {
    properties {
        "member-order" "003"
        "qualifier.state" "empty-cell"
    }
}
r_spawns_in -> r_poi_type "range member" {
    properties {
        "member-order" "004"
        "qualifier.state" "empty-cell"
    }
}
r_dungeon_type -> r_placed_in "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_poi_type -> r_placed_in "domain member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_settlement -> r_placed_in "domain member" {
    properties {
        "member-order" "003"
        "qualifier.state" "empty-cell"
    }
}
r_placed_in -> r_landscape "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_creature -> r_tamed_by "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_tamed_by -> r_pet_food "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_creature -> r_member_of_family "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_member_of_family -> r_creature_family "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_creature -> r_descriptive_member_of_family "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_descriptive_member_of_family -> r_creature_family "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_creature -> r_belongs_to_faction "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_npc_role -> r_belongs_to_faction "domain member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_belongs_to_faction -> r_faction "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_dungeon_type -> r_hosts "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_poi_type -> r_hosts "domain member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_hosts -> r_mission_type "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_mission_type -> r_rewards "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_arena -> r_rewards "domain member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_poi_type -> r_rewards "domain member" {
    properties {
        "member-order" "003"
        "qualifier.state" "empty-cell"
    }
}
r_rewards -> r_item_type "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_rewards -> r_key_item "range member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_rewards -> r_artifact "range member" {
    properties {
        "member-order" "003"
        "qualifier.state" "empty-cell"
    }
}
r_rewards -> r_currency "range member" {
    properties {
        "member-order" "004"
        "qualifier.state" "empty-cell"
    }
}
r_rewards -> r_book_of_crafting "range member" {
    properties {
        "member-order" "005"
        "qualifier.state" "empty-cell"
    }
}
r_creature -> r_guards "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "text"
        "qualifier.text" "(boss)"
    }
}
r_guards -> r_artifact "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_guards -> r_key_item "range member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_guards -> r_gnome_supplier "range member" {
    properties {
        "member-order" "003"
        "qualifier.state" "empty-cell"
    }
}
r_guards -> r_magic_crystal "range member" {
    properties {
        "member-order" "004"
        "qualifier.state" "empty-cell"
    }
}
r_creature -> r_drops "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_drops -> r_item "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_drops -> r_spirit_cube "range member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_drops -> r_leftovers "range member" {
    properties {
        "member-order" "003"
        "qualifier.state" "empty-cell"
    }
}
r_drops -> r_currency "range member" {
    properties {
        "member-order" "004"
        "qualifier.state" "empty-cell"
    }
}
r_inventory -> r_holds "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_holds -> r_item "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_entity -> r_equips "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_equips -> r_item "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_entity -> r_threat "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "text"
        "qualifier.text" "(mob)"
    }
}
r_threat -> r_entity "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "text"
        "qualifier.text" "(player-character)"
    }
}
r_entity -> r_current_target "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "text"
        "qualifier.text" "(mob)"
    }
}
r_current_target -> r_entity "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "text"
        "qualifier.text" "(player-character)"
    }
}
r_poi_type -> r_requires_key_item "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_dungeon_type -> r_requires_key_item "domain member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_ability -> r_requires_key_item "domain member" {
    properties {
        "member-order" "003"
        "qualifier.state" "empty-cell"
    }
}
r_requires_key_item -> r_key_item "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_settlement -> r_located_in "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_dungeon -> r_located_in "domain member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_poi -> r_located_in "domain member" {
    properties {
        "member-order" "003"
        "qualifier.state" "empty-cell"
    }
}
r_located_in -> r_land "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_land -> r_owned_by_realm "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_owned_by_realm -> r_realm "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_realm -> r_reveals "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "text"
        "qualifier.text" "(lore 100 %)"
    }
}
r_reveals -> r_artifact "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_item -> r_bound_to_land "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_key_item -> r_bound_to_land "domain member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_leftovers -> r_bound_to_land "domain member" {
    properties {
        "member-order" "003"
        "qualifier.state" "empty-cell"
    }
}
r_bound_to_land -> r_land "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_item -> r_works_in_adjacent "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "text"
        "qualifier.text" "(plus)"
    }
}
r_works_in_adjacent -> r_land "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_gnome_supplier -> r_raises_stock "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_raises_stock -> r_shop "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_shop -> r_sells "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_sells -> r_item_type "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_sells -> r_pet_food "range member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_sells -> r_formula "range member" {
    properties {
        "member-order" "003"
        "qualifier.state" "empty-cell"
    }
}
r_sells -> r_key_item "range member" {
    properties {
        "member-order" "004"
        "qualifier.state" "empty-cell"
    }
}
r_building -> r_offers_service "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_offers_service -> r_npc_role "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_building -> r_contains_station "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_contains_station -> r_crafting_station "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_building -> r_in_district "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_in_district -> r_district "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_settlement -> r_styled_by "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_styled_by -> r_landscape "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_item_type -> r_equips_in "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_equips_in -> r_equipment_slot "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_weapon_type -> r_restricted_to_class "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_material -> r_restricted_to_class "domain member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_restricted_to_class -> r_character_class "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_landscape -> r_has_hazard "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_terrain_feature -> r_has_hazard "domain member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_has_hazard -> r_status_effect "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_status_effect -> r_countered_by "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_countered_by -> r_consumable "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_artifact -> r_raises_stat "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_ability -> r_raises_stat "domain member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_spirit_cube -> r_raises_stat "domain member" {
    properties {
        "member-order" "003"
        "qualifier.state" "empty-cell"
    }
}
r_elixir -> r_raises_stat "domain member" {
    properties {
        "member-order" "004"
        "qualifier.state" "empty-cell"
    }
}
r_raises_stat -> r_stat "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_player_character -> r_mounts "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_mounts -> r_pet "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_player_character -> r_owns "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_owns -> r_pet "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_poi_type -> r_possesses "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "text"
        "qualifier.text" "(demon-portal)"
    }
}
r_possesses -> r_npc_role "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_possesses -> r_creature "range member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_creature -> r_petrifies "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "text"
        "qualifier.text" "(witch boss)"
    }
}
r_petrifies -> r_settlement "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_pet -> r_scales_with "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_scales_with -> r_stat "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "text"
        "qualifier.text" "(weapon-rating, armor-rating)"
    }
}
r_land -> r_adjacent_to "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_adjacent_to -> r_land "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_ability -> r_enabled_by "domain member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
r_item_type -> r_enabled_by "domain member" {
    properties {
        "member-order" "002"
        "qualifier.state" "empty-cell"
    }
}
r_mechanic -> r_enabled_by "domain member" {
    properties {
        "member-order" "003"
        "qualifier.state" "empty-cell"
    }
}
r_enabled_by -> r_ruleset "range member" {
    properties {
        "member-order" "001"
        "qualifier.state" "empty-cell"
    }
}
