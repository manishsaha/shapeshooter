open Types
open Utils
open Constants

let handle_coll_loc loc1 v loc2 =
  let rad = subtract loc2 loc1 in
  let mag = (dot v rad) /. (dot rad rad) in
  let proj = scale rad mag in
  subtract v proj

(* [cap_vector] is a shortened [v] to keep [loc] distance [r] from [target]. *)
let cap_vector v loc target r towards =
  let mag = magnitude (subtract loc target) in
  let cap = (if towards then mag -. r else r -. mag) in
  set_mag v cap

(* [handle_entity_dmg ent dmg] is the entity [ent] with adjusted hp after it
 * has taken damage [dmg]. *)
let handle_entity_dmg entity dmg =
  let (per, cool) = get_invuln entity in
  if cool <> 0 then entity
  else entity |> set_hp (get_hp entity -. dmg) |> set_invuln (per, per)

let check_struct_colls entity v structs =
  let loc = get_loc entity in
  let check_obst (v', obst) (strct: structure) =
    let loc' = add loc v' in
    if is_coll loc' strct.location (get_hitbox entity) strct.hitbox
    then let v' = handle_coll_loc loc v strct.location in
      (v', Some strct)
    else (v', obst) in
  List.fold_left check_obst (v, None) structs

let check_enemy_colls entity v enems =
  let loc = get_loc entity in
  let check_enem v' (enemy: enemy) =
    let loc' = add loc v' in
    if get_id entity <> enemy.id &&
       is_coll loc' enemy.location (get_hitbox entity) enemy.hitbox
    then handle_coll_loc loc v' enemy.location
    else v' in
  List.fold_left check_enem v enems

(* [check_player_coll entity v player] is the [entity] velocity, after
 * adjusting [v] for collisions with [player], and the possibly hit player. *)
let check_player_coll entity v (player: player) =
  let loc = get_loc entity in
  if is_coll (add loc v) player.location (get_hitbox entity) player.hitbox
  then let v' = handle_coll_loc loc v player.location in
    (v', Some player)
  else (v, None)

let check_bullet_colls st (bullet: bullet) =
  let check_enem (blt_opt, enems) (enem: enemy) =
    match blt_opt with
    | None -> (None, enem::enems)
    | Some (bullet: bullet) ->
      if is_coll bullet.location enem.location bullet.hitbox enem.hitbox
      then if not bullet.friendly then (Some bullet, enem::enems)
        else let blt_opt =
               if not bullet.piercing then None
               else Some {bullet with hit_ids = enem.id::bullet.hit_ids} in
          let enemy_ent =
            if List.mem enem.id bullet.hit_ids then Enemy enem
            else handle_entity_dmg (Enemy enem) bullet.damage in
          (blt_opt, (get_enemy enemy_ent)::enems)
      else (Some bullet, enem::enems) in

  let check_struct (blt_opt, structs) (strct: structure) =
    match blt_opt with
    | None -> (None, strct::structs)
    | Some (bullet: bullet) ->
      if is_coll bullet.location strct.location bullet.hitbox strct.hitbox
         || not (check_bounds bullet.location bullet.hitbox)
      then let blt_opt =
             if bullet.equip_id = "laser" then Some bullet else None in
        let struct_ent =
          if bullet.friendly then Structure strct
          else handle_entity_dmg (Structure strct) bullet.damage in
        (blt_opt, (get_struct struct_ent)::structs)
      else (Some bullet, strct::structs) in

  let check_plyr blt_opt (player: player) =
    match blt_opt with
    | None -> (None, player)
    | Some (bullet: bullet) ->
      if is_coll bullet.location player.location bullet.hitbox player.hitbox
      then if bullet.friendly then (Some bullet, player)
        else let blt_opt =
               if not bullet.piercing then None
               else Some {bullet with hit_ids = -1::bullet.hit_ids} in
          let player_ent =
            if List.mem (-1) bullet.hit_ids then Player player
            else handle_entity_dmg (Player player) bullet.damage in
          (blt_opt, get_player player_ent)
      else (Some bullet, player) in

  let add_explosion blt_opt' blt_opt st =
    let check_explosion (blt_opt:bullet option) st =
      match blt_opt with
      | Some b when b.equip_id = "rocket" ->
        let bullet = {equip_id = "flamethrower"; damage = 0.3 *. b.damage;
                      location = b.location; velocity = b.velocity;
                      piercing = true; origin = b.location; dist = 100.;
                      direction = b.direction; hitbox = 3.;
                      friendly = b.friendly; hit_ids = []} in
        let angles =
          List.init 500
            (fun _ -> let r = Random.float 2. -. 1. in r *. pi) in
        let all_bullets =
          List.map
            (fun phi -> let (vx, vy) = rotate bullet.velocity phi in
              let d = Random.float 25. +. 75. in
              let mag = (1. /. 30.) *. d in
              let v = set_mag (vx, vy) mag in
              {bullet with dist = d; velocity = v; direction = atan2 vy vx})
            angles in
        {st with bullets = all_bullets @ st.bullets}
      | _ -> st in
    if blt_opt' = None then check_explosion blt_opt st else st in

  let (blt_opt, enems) =
    List.fold_left check_enem (Some bullet, []) st.enemies in
  let st = add_explosion blt_opt (Some bullet) st in
  let (blt_opt', structs) =
    List.fold_left check_struct (blt_opt, []) st.structures in
  let st = add_explosion blt_opt' blt_opt st in
  let (blt_opt'', player) =
    check_plyr blt_opt' st.player in
  let st = add_explosion blt_opt'' blt_opt' st in

  ({st with enemies = enems; structures = structs; player = player}, blt_opt'')

let move_bullet (bullet: bullet) =
  let loc = add bullet.location bullet.velocity in
  if distance bullet.origin loc < bullet.dist
  then Some {bullet with location = loc}
  else None

let find_target eloc target st =
  let closest loc_opt loc =
    match loc_opt with
    | None -> Some loc
    | Some loc_acc ->
      if distance eloc loc < distance eloc loc_acc
      then Some loc else Some loc_acc in
  let c_plyr loc_opt (player: player) = closest loc_opt player.location in
  let c_struct loc_opt (strct: structure) = closest loc_opt strct.location in
  let c_harv loc_opt (strct: structure) =
    if strct.equip.id <> "harvester" then loc_opt
    else closest loc_opt strct.location in
  let c_turr loc_opt (strct: structure) =
    if strct.equip.id = "harvester" then loc_opt
    else closest loc_opt strct.location in
  let c_enem loc_opt (enemy: enemy) = closest loc_opt enemy.location in
  match target with
  | `All -> (* specific to enemies, so only includes friendly targets *)
    let loc_opt = c_plyr None st.player in
    List.fold_left c_struct loc_opt st.structures
  | `Player -> c_plyr None st.player
  | `Structure -> List.fold_left c_struct None st.structures
  | `Harvester -> List.fold_left c_harv None st.structures
  | `Turret -> List.fold_left c_turr None st.structures
  | `Enemy -> List.fold_left c_enem None st.enemies

let enemy_target (enemy: enemy) st =
  let rec target_loc targets =
    match targets with
    | [] -> failwith "Enemy must be assigned a target"
    | h::t ->
      match find_target enemy.location h st with
      | None -> target_loc t
      | Some loc -> loc in
  target_loc enemy.targets

(* [calc_enem_v enemy obst plyr v st] is the adjusted [enemy] velocity [v] after
 * potentially colliding with an enemy, [obst], or [plyr] in [st]. *)
let rec calc_enem_v (enemy: enemy) obst plyr v st =
  let (v', hit_obst) = check_struct_colls (Enemy enemy) v st.structures in
  let v' = check_enemy_colls (Enemy enemy) v' st.enemies in
  let (v', plyr_opt) = check_player_coll (Enemy enemy) v' st.player in
  let obst = get_some hit_obst obst and plyr = get_some plyr_opt plyr in
  if not (eq_coords v v') then calc_enem_v enemy obst plyr v' st
  else (v', obst, plyr)

(* [enemy_ptrn enemy target rad towards ptrn st] is [enemy] after moving with
 * [ptrn] and maintaining distance [rad] from [target], if moving [towards] it,
 * and the resulting [st]. *)
let enemy_ptrn (enemy: enemy) target rad towards ptrn st =
  let structs = st.structures and eloc = enemy.location in
  let dir = (if towards then subtract target eloc else subtract eloc target) in
  let comp = (if towards then (>) else (<)) in
  match ptrn with
  | Linear ->
    let v =
      let v = set_mag dir enemy.speed in
      if comp rad (distance target (add eloc v))
      then cap_vector v eloc target rad towards else v in
    let (v, hit_obst, plyr_opt) = calc_enem_v enemy None None v st in
    let enemy =
      let eloc = add enemy.location v in
      if comp (distance eloc target) (distance enemy.location target)
      then enemy else {enemy with location = eloc} in
    let dmg = enemy.attack *. touch_dmg in
    let structs =
      match hit_obst with
      | None -> structs
      | Some obst ->
        let obst_ent = handle_entity_dmg (Structure obst) dmg in
        let structs = List.filter (fun s -> s <> obst) structs in
        (get_struct obst_ent)::structs in
    let player =
      match plyr_opt with
      | None -> st.player
      | Some player ->
        let player_ent = handle_entity_dmg (Player player) dmg in
        get_player player_ent in
    (enemy, {st with structures = structs; player = player})
  | Oscillate
  | Dodge -> failwith "Unimplemented"

let enemy_move target (enemy: enemy) st =
  let eloc = enemy.location in
  let dist = distance eloc target in
  match enemy.pattern with
  | MaxDist (rad, ptrn) ->
    let enemy = {enemy with stopped = (dist <= rad)} in
    if not enemy.stopped
    then enemy_ptrn enemy target rad true ptrn st
    else (enemy, st)
  | ConstDist (rad, ptrn) ->
    if not enemy.stopped
    then if dist > rad
      then enemy_ptrn enemy target rad true ptrn st
      else enemy_ptrn enemy target rad false ptrn st
    else failwith "ConstDist enemy should never be stopped"

(* [fire_bullets] is [st] after firing bullets with the parameters as stats *)
let fire_bullets st enloc attack eq speed stopped direction size ent =
  let {player; bitfields; bullets} = st in
  match eq with
  | Some equip -> begin
      let {id; power; bullet_speed; bullet_size = hitbox; bullet_dist = dist;
           piercing; cooldown = (max_cd, _)} = equip in
      let (vx, vy) =
        add
          (xy_of_rphi bullet_speed direction)
          (if stopped then origin
           else xy_of_rphi speed direction) in
      let startloc = add enloc (xy_of_rphi (size +. hitbox) direction) in
      let friendly = match ent with
        | Player _ -> true
        | Enemy _ -> false
        | Structure _ -> true
        | Bullet _ -> failwith "Bullets cannot fire bullets" in
      let bullet = {equip_id = id; damage = power *. attack;
                    location = startloc; velocity = (vx, vy);
                    piercing; origin = startloc; dist; direction;
                    hitbox; friendly = friendly; hit_ids = []} in
      let st =
        match id with
        | "shotgun" ->
          let angles =
            List.init 20
              (fun _ -> let r = Random.float 2. -. 1. in r *. pi /. 12.) in
          let all_bullets =
            List.map
              (fun phi -> let (vx, vy) = rotate bullet.velocity phi in
                 {bullet with velocity = (vx, vy); direction = atan2 vy vx})
              angles in
          {st with bullets = all_bullets @ bullets}
        | "pistol" | "sniper" | "machine" | "rocket" | "blackhole" ->
          {st with bullets = bullet :: st.bullets}
        | "impulse" ->
          let n = 300 in
          let angles =
            List.init n
              (fun i -> 2. *. pi *. float_of_int i /. float_of_int n) in
          let all_bullets =
            List.map
              (fun phi ->
                 let (vx, vy) = rotate bullet.velocity phi in
                 let l = add enloc (xy_of_rphi (size +. hitbox) phi) in
                 {bullet with
                  origin = l; location = l; velocity = (vx, vy);
                  direction = atan2 vy vx; equip_id = "flamethrower"})
              angles in
          {st with bullets = all_bullets @ bullets}
        | "flamethrower" ->
          let angles =
            List.init 15
              (fun _ -> let r = Random.float 2. -. 1. in r *. pi /. 12.) in
          let all_bullets =
            List.map
              (fun phi -> let (vx,vy) = rotate bullet.velocity phi in
                {bullet with velocity = (vx,vy); direction = atan2 vy vx})
              angles in
          {st with bullets = all_bullets @ bullets}
        | "laser" ->
          let rec get_locations loc dist dir t acc =
            let bloc = add loc (scale (xy_of_rphi dist dir) (float_of_int t)) in
            if not (check_bounds bloc 0.) then acc
            else get_locations loc dist dir (t + 1) (bloc :: acc) in
          let locations = get_locations startloc 5. direction 1 [] in
          let all_bullets =
            List.map
              (fun bloc -> {bullet with origin = bloc; location = bloc;
                                        dist = 0.2;})
              locations in
          {st with bullets = all_bullets @ bullets}
        | "harvester" ->
          {st with player = {player with bits = player.bits + 5}}
        | _ -> st in
      match ent with
      | Player _ ->
        {st with
         player =
           update_equip {equip with cooldown = (max_cd, max_cd)} st.player}
      | Enemy _ -> st
      | _ -> st (* this will never execute *)
    end
  | None -> st

let advance_attack st entity =
  match get_equip entity with
  | None -> st
  | Some equip ->
    if snd equip.cooldown = 0
    then match entity with
      | Player p ->
        let {attack; location = ploc; equips; equip_index; speed;
             direction; stopped; hitbox = psize} = p in
        let equip = equip_at_index equip_index equips in
        fire_bullets st ploc attack (Some equip) speed stopped direction psize
          (Player p)
      | Enemy e ->
        let {attack; location = eloc; equip; speed;
             direction; stopped; hitbox = esize} = e in
        fire_bullets st eloc attack equip speed stopped direction esize
          (Enemy e)
      | Structure s ->
        let {attack; location = sloc; equip;
             direction; hitbox = ssize}: structure = s in
        fire_bullets st sloc attack (Some equip) 0. true direction ssize
          (Structure s)
      | Bullet _ -> st (* this will never execute *)
    else st

let entity_attack entity st =
  let st = advance_attack st entity in
  match get_equip entity with
  | Some equip when snd equip.cooldown = 0 ->
    (set_equip (Some {equip with cooldown = (fst equip.cooldown,
                                             fst equip.cooldown)}) entity, st)
  | _ -> (entity, st)

let entity_passive entity =
  if get_hp entity <= 0. then None
  else
    let entity =
      match get_equip entity with
      | Some equip when snd equip.cooldown <> 0 ->
        set_equip (Some {equip with cooldown = (fst equip.cooldown,
                                                snd equip.cooldown - 1)}) entity
      | _ -> entity in
    Some
      (match get_invuln entity with
      | (per, cool) when cool <> 0 ->
        set_invuln (per, cool - 1) entity
      | _ -> entity)

let calc_struct_dir ({direction = cur_dir; location}: structure) target =
  let max_rot = structure_rotation_speed in
  let target_dir = direction (subtract target location) in
  let diff = (pos_mod_float target_dir (2. *. pi)) -.
             (pos_mod_float cur_dir (2. *. pi)) in
  let rotate =
    if (diff >= 0. && diff <= pi) || (diff <= -.pi && diff >= -2. *. pi)
    then min diff max_rot else max diff (-.max_rot) in
  cur_dir +. rotate
