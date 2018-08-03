open Types

(* [upgrade id] returns an event handler for the given upgrade. *)
val upgrade: string -> Dom_html.mouseEvent Js.t -> bool Js.t

(* [input_state ()] returns the current input state. *)
val input_state: unit -> input_state
