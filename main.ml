open Action
open Canvas
open Input
open State
open Types
open Utils

let frame_advance = false

let rec loop st =
  let ins = input_state () in
  let acts = actions_of_inputs ins in
  let st' = advance acts st frame_advance in
  draw_st st';
  if st.mode <> Dead then
    (Dom_html.window##requestAnimationFrame
       (Js.wrap_callback (fun _ -> loop st')))
    |> ignore
  

let _ =
  Random.self_init ();
  loop (initial_state ())
