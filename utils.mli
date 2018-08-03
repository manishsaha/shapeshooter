open Types

(* [get_enemy ent] casts an entity to an enemy. *)
val get_enemy: entity -> enemy

(* [get_player ent] casts an entity to an player. *)
val get_player: entity -> player

(* [get_struct ent] casts an entity to an structure. *)
val get_struct: entity -> structure

(* [get_bullet ent] casts an entity to an bullet. *)
val get_bullet: entity -> bullet

(* [get_id ent] gets the id of an enemy entity.
 * requires: [ent] is an enemy entity. *)
val get_id: entity -> int

(* [get_hp ent] returns the current health of [ent]. *)
val get_hp: entity -> float

(* [set_hp hp ent] returns [ent] with health [hp], or 0 if below. *)
val set_hp: float -> entity -> entity

(* [get_hitbox ent] returns the hitbox size of [ent]. *)
val get_hitbox: entity -> float

(* [get_loc ent] returns the location of [ent]. *)
val get_loc: entity -> coords

(* [set_loc loc ent] returns [ent] with location [loc]. *)
val set_loc: coords -> entity -> entity

(* [get_invuln ent] gets the invulnerability counter of [ent]. *)
val get_invuln: entity -> int * int

(* [set_invuln invuln ent] returns [ent] with invulnerability [invuln]. *)
val set_invuln: int * int -> entity -> entity

(* [get_some opt1 opt2] returns [opt1] if not None, otherwise [opt2]. *)
val get_some: 'a option -> 'a option -> 'a option

(* [calc_wave_time n] returns the wave duration for wave number [n]. *)
val calc_wave_time: int -> int

(* [pos_mod a b] returns the positive modulus of a and b. *)
val pos_mod: int -> int -> int

(* [pos_mod_float a b] returns the positive float modulus of a and b. *)
val pos_mod_float: float -> float -> float

(* [eq_coords p1 p2] returns whether [p1] and [p2] are equal up to [epsilon]. *)
val eq_coords: coords -> coords -> bool

(* [distance p1 p2] returns the distance between [p1] and [p2]. *)
val distance: coords -> coords -> float

(* [magnitude v] returns the magnitude of [v]. *)
val magnitude: coords -> float

(* [direction v] returns the angle of [v]. *)
val direction: coords -> float

(* [add v1 v2] returns [v1 + v2]. *)
val add: coords -> coords -> coords

(* [subtract v1 v2] returns [v1 - v2]. *)
val subtract: coords -> coords -> coords

(* [dot v1 v2] returns the dot product of [v1] and [v2]. *)
val dot: coords -> coords -> float

(* [scale v c] scales [v] to magnitude [c]. *)
val scale: coords -> float -> coords

(* [normalize v] returns the unit vector parallel to [v], or [v]
 * if [v] is the zero vector. *)
val normalize: coords -> coords

(* [set_mag v c] returns the vector of magnitude [c] parallel to [v]. *)
val set_mag: coords -> float -> coords

(* [rotate v phi] rotates [v] [phi] radians counterclockwise. *)
val rotate: coords -> float -> coords

(* [xy_of_rphi r phi] returns the rectangular form of polar [(r, phi)]. *)
val xy_of_rphi: float -> float -> coords

(* [check_bounds location hitbox] checks if an object at [location] with
 * size [hitbox] is within the bounds of the world. *)
val check_bounds: coords -> float -> bool

(* [canvas_xy_of_world ploc wloc] returns the canvas coordinates of [wloc]
 * for a viewport centered at [ploc]. *)
val canvas_xy_of_world: coords -> coords -> coords

(* [world_xy_of_world ploc cloc] returns the world coordinates of [cloc]
 * for a viewport centered at [ploc]. *)
val world_xy_of_canvas: coords -> coords -> coords

(* [is_coll p1 p2 r1 r2] returns whether two circles centered at [p1 p2] with
 * radii [r1 r2] are overlapping. *)
val is_coll: coords -> coords -> float -> float -> bool

(* [cons_no_dups x xs] returns x :: xs if x is not in xs; otherwise xs. *)
val cons_no_dups: 'a -> 'a list -> 'a list

(* [fold_rev f xs init] is [fold_left] with the arg order of [fold_right]. *)
val fold_rev: ('b -> 'a -> 'a) -> 'b list -> 'a -> 'a

(* [find_index pred xs] finds the first index in [xs] satisfying [pred]. *)
val find_index: ('a -> bool) -> 'a list -> int

(* [equip_of_id id equips] returns the first equip in [equips] with [id].
 * requires: an equip with [id] is in [equips] *)
val equip_of_id: string -> equip list -> equip

(* [upgrade_of_id id upgrades] returns the first upgrade in [upgrades] with [id].
 * requires: an upgrade with [id] is in [upgrades] *)
val upgrade_of_id: string -> upgrade list -> upgrade

(* [equip_at_index i equips] returns the equip at index [i] of [equips].
 * requires: 0 <= i < length equips *)
val equip_at_index: int -> equip list -> equip

(* [equip_id_at_index i equips] returns the equip id at index [i] of [equips].
 * requires: 0 <= i < length equips *)
val equip_id_at_index: int -> equip list -> string

(* [index_of_equip_id id equips] returns the index of [id] in [equips].
 * requires: an equip with [id] is in [equips]. *)
val index_of_equip_id: string -> equip list -> int

(* [update_equip new_equip player] returns [player] with [new_equip]. *)
val update_equip: equip -> player -> player

(* [equip_ids_of_equips equips] returns the ids of [equips]. *)
val equip_ids_of_equips: equip list -> string list

(* [possible_upgrades equips] returns the possible upgrades given [eqiups]. *)
val possible_upgrades: equip list -> upgrade list

(* [get_equip ent] returns the equip of [ent], if it has one. *)
val get_equip: entity -> equip option

(* [set_equip equip_opt ent] returns [ent] with [equip_opt]. *)
val set_equip: equip option -> entity -> entity

(* [enemy_of_species species] returns an enemy with [species]. *)
val enemy_of_species: string -> enemy

(* [check_bitfields loc bitfields] returns whether [loc]
 * is in any of [bitfields]. *)
val check_bitfields: coords -> bitfield list -> bool

(* [build_cost stats] returns the cost to build a structure with [stats]. *)
val build_cost: build_stats -> int
