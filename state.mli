open Types

(* [initial_state ()] prepares the state for gameplay. *)
val initial_state: unit -> state

(* [advance_move dir st] is the state after player has moved. *)
val advance_move: coords -> state -> state

(* [advance_enemies st] is the state after enemies have advanced one frame. *)
val advance_enemies: state -> state

(* [advance_bullets st] is the state after bullets have advanced one frame. *)
val advance_bullets: state -> state

(* [advance_upgrade id st] is the state after player has upgraded their equip. *)
val advance_upgrade: string -> state -> state

(* [advance_scroll n st] is the state after player has switched their equip. *)
val advance_scroll: int -> state -> state

(* [advance st acts] returns the result of applying [acts] to state [st]. *)
val advance: action list -> state -> bool -> state
