open Types

(* [pi] is the fixed ratio between a circle's circumference and its diameter. *)
val pi: float

(* [epsilon] is the float comparison error margin. *)
val epsilon: float

(* [world_size] is the radius, in pixels, of the circular world. *)
val world_size: float

(* [map_size] is the size, in pixels, of the player's viewing square. *)
val map_size: float

(* [half_world_size] is half [world_size]. *)
val half_world_size: float

(* [half_map_size] is half [map_size]. *)
val half_map_size: float

(* [touch_dmg] is the base amount for enemy touch damage. *)
val touch_dmg: float

(* [bit_size] is the size of a bit in a bitfield. *)
val bit_size: float

(* [equip_ui_size] is the size of the current equip in the UI. *)
val equip_ui_size: float

(* [background_line_spacing] is the spacing of the background grid. *)
val background_line_spacing: float

(* [origin] is (0., 0.). *)
val origin: coords

(* [scroll_threshold] is the scroll amount needed to cause a scroll event. *)
val scroll_threshold: int

(* [structure_rotation_speed] is the rotation speed of a structure. *)
val structure_rotation_speed: float

(* [structure_size] is the radius of a structure. *)
val structure_size: float

(* [wave_buffer] is the added number of frames between consecutive waves. *)
val wave_buffer: int

(* [wave_time] is the base number of frames a wave lasts. *)
val wave_time: int

(* [player_health] is the player's maximum health. *)
val player_health: float

(* [dmg_invln] is the number of frames the entity is invulnerable to damage. *)
val dmg_invuln: int

(* [default_equips] is the list of base equips. *)
val default_equips: equip list

(* [default_waves] is the list of base wave names. *)
val default_waves: string list

(* [default_enemies] is the list of base enemies. *)
val default_enemies: enemy list

(* [default_upgrades] is the list of base upgrades. *)
val default_upgrades: upgrade list

(* [default_player] is the base player. *)
val default_player: player
