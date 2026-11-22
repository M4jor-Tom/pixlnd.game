"""Literal current-save facets from the existing validation predicates."""

RAW_INTEGER_MAX = 9223372036854775295
LAST_FLOAT_BELOW_LIMIT = 9223372036854774784.0
NONEMPTY = r"^[\s\S]+$"
INTEGER_SLOTS = {
    "save-character-character-state.yaml": ["skill-investment-points", "character-state-level", "character-state-xp", "character-state-banked", "character-state-coins"],
    "save-character-saved-item.yaml": ["saved-item-level", "saved-item-upgrade-count", "saved-item-modifier", "saved-item-minus-modifier", "saved-item-count"],
    "save-combat-saved-combat.yaml": ["saved-combat-next-order"],
    "save-combat-threat-records.yaml": ["saved-order-order"],
    "save-combat-saved-mob.yaml": ["saved-mob-level", "saved-mob-seed", "saved-mob-cycle"],
    "save-combat-saved-mob-state.yaml": ["saved-mob-room-cycle"],
    "save-world-saved-site.yaml": ["saved-site-cycle"],
    "save-world-saved-site-collections.yaml": ["saved-spirit-level-level", "saved-site-room-levels"],
    "save-world-saved-contents.yaml": ["saved-reward-level"],
    "save-content-saved-vendor.yaml": ["saved-vendor-day", "saved-vendor-level", "saved-vendor-ceiling"],
}


def condition(name, alias, **facets):
    return {name: {"alias": alias, **facets}}


def special_rules():
    active = condition("saved-special-origin", "origin", minimum_cardinality=3, maximum_cardinality=3)
    active.update(condition("saved-special-endpoint", "endpoint", minimum_cardinality=3, maximum_cardinality=3))
    active.update(condition("saved-special-engaged", "engaged", equals_expression="True"))
    active.update(condition("saved-special-target", "target", pattern=NONEMPTY))
    inactive = condition("saved-special-origin", "origin", maximum_cardinality=0)
    inactive.update(condition("saved-special-endpoint", "endpoint", maximum_cardinality=0))
    inactive.update(condition("saved-special-target", "target", equals_string=""))
    return [
        {"preconditions": {"slot_conditions": condition("saved-special-phase", "phase", equals_string_in=["warning", "charge"])},
         "postconditions": {"slot_conditions": active}, "elseconditions": {"slot_conditions": inactive}},
        {"preconditions": {"slot_conditions": condition("saved-special-phase", "phase", equals_string_in=["ready", "warning", "charge"])},
         "postconditions": {"slot_conditions": condition("saved-special-recovery", "recovery", equals_number=0)}},
        {"preconditions": {"slot_conditions": condition("saved-special-phase", "phase", equals_string="charge")},
         "postconditions": {"slot_conditions": condition("saved-special-left", "left", equals_number=0)}},
        {"preconditions": {"slot_conditions": condition("saved-special-phase", "phase", equals_string="cooldown")},
         "postconditions": {"slot_conditions": condition("saved-special-recovery", "recovery", equals_expression="min({recovery}, {left})")}},
    ]


def rubble_rules():
    unbroken = condition("saved-rubble-broken", "broken", equals_expression="False")
    unbroken.update(condition("saved-rubble-restore-at", "restore_at", equals_number=0))
    broken = condition("saved-rubble-broken", "broken", equals_expression="True")
    broken.update(condition("saved-rubble-restore-at", "restore_at", minimum_value=0, none_of=[{"equals_number": 0}]))
    return [{"postconditions": {"any_of": [{"slot_conditions": unbroken}, {"slot_conditions": broken}]}}]


def trap_rules():
    return [{"preconditions": {"slot_conditions": condition("saved-trap-phase", "phase", equals_string_in=["idle", "warning"])},
             "postconditions": {"slot_conditions": condition("saved-trap-hit", "hit", maximum_cardinality=0)}}]


COIN_RULE = {
    "preconditions": {"slot_conditions": condition("saved-item-type", "type", equals_string="coin")},
    "postconditions": {"slot_conditions": {
        **condition("saved-item-subtype", "subtype", equals_string=""),
        **condition("saved-item-material", "material", equals_string=""),
    }},
}
