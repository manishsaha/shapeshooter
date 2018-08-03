open Types

(* [loop] continuously gets user input, updates the state through
 * calling [State.advance], and draws the updated state before requesting
 * it be called again through [requestAnimationFrame]. *)
val loop: state -> unit
