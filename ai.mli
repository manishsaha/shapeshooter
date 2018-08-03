open Types

(* [handle_coll_loc loc1 v loc2] is velocity after adjusting [v] for a collision
 * between entities at [loc1] and [loc2]. *)
val handle_coll_loc : coords -> coords -> coords -> coords

(* [check_struct_colls entity v structs] is the [entity] velocity, after
 * adjusting [v] for collisions in [structs], and a possibly hit structure. *)
val check_struct_colls : entity -> coords -> structure list ->
  coords * structure option

(* [check_enemy_colls entity v enems] is the [entity] velocity, after
 * adjusting [v] for collisions in [enems]. *)
val check_enemy_colls : entity -> coords -> enemy list -> coords

(* [check_bullet_colls st bullet] is the state, after handling collisions
 * between [bullet] and entities in [st], and the possibly remaining bullet. *)
val check_bullet_colls : state -> bullet -> state * bullet option

(* [move_bullet bullet] is Some [bullet] after moving or None if [bullet]
 * reached its maximum range. *)
val move_bullet : bullet -> bullet option

(* [find_target eloc target st] is Some location of the closest [target] in [st]
 * to [eloc] or None if no [target] exists. *)
val find_target :
  coords -> [`All | `Player | `Structure | `Harvester | `Turret | `Enemy] ->
  state -> coords option

(* [enemy_target enemy st] is [find_target] for [enemy] location and all targets
 * in [st], called as needed for each target in the [enemy] target list. *)
val enemy_target : enemy -> state -> coords

(* [enemy_move target enemy st] is [enemy], after moving relative to [target]
 * and adjusting for collisions in [st], and the resulting state. *)
val enemy_move : coords -> enemy -> state -> enemy * state

(* [advance_attack st entity] is [st] with bullets from [entity] attacking. *)
val advance_attack : state -> entity -> state

(* [entity_attack entity st] is [advance_attack st entity] with reset cooldown
 * for [entity] weapon. *)
val entity_attack : entity -> state -> entity * state

(* [entity_passive entity] is Some [entity] after decrementing weapon and
 * invulnerability cooldown or None if [entity] died. *)
val entity_passive : entity -> entity option

(* [calc_struct_dir strct target] is the direction of [strct] after turning
 * towards [target]. *)
val calc_struct_dir : structure -> coords -> float
