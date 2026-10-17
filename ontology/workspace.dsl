workspace "Cube World rebuild ontology" {
    !identifiers flat
    !impliedRelationships false
    model {
        !include domain/index.dsl
    }
    views {
        custom "combat-incidence" "Individual entity roles and same-class ability relation" {
            include r_entity r_threat r_current_target r_ability r_unlocks_next r_character_class r_specialization r_grants_ability
            autoLayout lr
        }
        custom "world" "World definitions" {
            include element.tag==World
            autoLayout lr
        }
        custom "entities" "Entities definitions" {
            include element.tag==Entities
            autoLayout lr
        }
        custom "combat" "Combat definitions" {
            include element.tag==Combat
            autoLayout lr
        }
        custom "items" "Items definitions" {
            include element.tag==Items
            autoLayout lr
        }
        custom "progression" "Progression definitions" {
            include element.tag==Progression
            autoLayout lr
        }
        custom "missions" "Missions definitions" {
            include element.tag==Missions
            autoLayout lr
        }
        custom "meta" "Meta definitions" {
            include element.tag==Meta
            autoLayout lr
        }
        custom "relationdefinition" "RelationDefinition definitions" {
            include element.tag==RelationDefinition
            autoLayout lr
        }
        custom "constraint" "Constraint definitions" {
            include element.tag==Constraint
            autoLayout lr
        }
        custom "question" "Question definitions" {
            include element.tag==Question
            autoLayout lr
        }
    }
}
