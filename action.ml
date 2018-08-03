open Constants
open Js_utils
open Types
open Utils

(* [cons_no_action_dups] adds [act] to [acts] if the action type is not
 * already in [acts]. *)
let cons_no_action_dups act acts =
  if (List.exists
        (fun a ->
           match (act, a) with
           | (Move _, Move _)
           | (StartInteract, StartInteract)
           | (StopInteract, StopInteract)
           | (Interact _, Interact _)
           | (Hover _, Hover _)
           | (Upgrade _, Upgrade _)
           | (Scroll _, Scroll _)
           | (Builder _, Builder _)
           | (Advance, Advance) -> true
           | _ -> false) acts) then acts else act :: acts

let actions_of_inputs {keys_pressed; keys_held; keys_released;
                       buttons_pressed; buttons_held; buttons_released;
                       mouse; scroll; builder; upgrade} =
  let actions =
    List.fold_left
      (fun acc c ->
         match c with
         | 'Q' -> cons_no_action_dups (Scroll (-1)) acc
         | 'E' -> cons_no_action_dups (Scroll 1) acc
         | 'F' -> cons_no_dups Advance acc
         | _ -> acc) [] keys_pressed in
  let move_dir =
    List.fold_left
      (fun dir c ->
         match c with
         | 'W' -> add (0., -1.) dir
         | 'A' -> add (-1., 0.) dir
         | 'S' -> add (0., 1.) dir
         | 'D' -> add (1., 0.) dir
         | _ -> origin) origin keys_held in
  let actions = Move move_dir :: actions in
  let actions =
    List.fold_left
      (fun acc c ->
         match c with
         | ' ' -> cons_no_action_dups (Interact mouse) acc
         | _ -> acc) actions keys_held in
  let actions =
    List.fold_left
      (fun acc b ->
         match b with
         | Left -> cons_no_action_dups (Interact mouse) acc
         | _ -> acc) actions buttons_held in
  let actions =
    if scroll <> 0
    then cons_no_action_dups (Scroll scroll) actions else actions in
  let actions =
    if List.mem ' ' keys_pressed || List.mem Left buttons_pressed then
      StartInteract :: actions
    else if List.mem ' ' keys_released && not (List.mem Left buttons_held) ||
            List.mem Left buttons_released && not (List.mem ' ' keys_held) then
       StopInteract :: actions
    else actions in
  let actions = Builder builder :: Hover mouse :: actions in
  let actions =
    match upgrade with
    | None -> actions
    | Some id -> Upgrade id :: actions in
  actions
