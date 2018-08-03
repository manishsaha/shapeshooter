open OUnit2
open Types
open State
open Ai
open Constants
open Utils

let pistol = equip_of_id "pistol" default_equips

let struct1 : structure = {
  hp = (50., 50.);
  location = (5., 5.);
  direction = 0.;
  attack = 5.;
  equip = pistol;
  invuln = (10,0);
  hitbox = 1.;
}

let struct2 : structure = {
  hp = (50., 0.);
  location = (0., 0.);
  direction = 0.;
  attack = 5.;
  equip = pistol;
  invuln = (10,0);
  hitbox = 1.;
}

let structs = [struct1; struct2]

let plyr1 = {
  hp = (10., 10.);
  attack = 1.;
  speed = 1.;
  stopped = true;
  equip_index = 1;
  equips = default_equips;
  location = (10., 4.);
  direction = 0.;
  hitbox = 1.;
  invuln = (10, 0);
  bits = 10000;
  upgrades = default_upgrades;
}

let enem1 = {
  id = 1;
  species = "p_seeker";
  hp = (10., 1.);
  targets = [`Player];
  attack = 1.0;
  pattern = MaxDist (1.0, Linear);
  speed = 1.;
  equip = Some pistol;
  stopped = false;
  location = (5., 0.);
  hitbox = 3.;
  direction = 10.
}

let enem2 = {
  id = 2;
  species = "p_seeker";
  hp = (10., 10.);
  targets = [`All];
  attack = 1.0;
  pattern = MaxDist (1.0, Linear);
  speed = 1.;
  equip = Some pistol;
  stopped = false;
  location = (0., 0.);
  hitbox = 3.;
  direction = 0.
}

let enems = [enem1; enem2]

let blt1 = {
  equip_id = "pistol";
  damage = 5.;
  location = (50., 0.);
  piercing = false;
  velocity = (49., 0.);
  origin = origin;
  dist = 100.;
  direction = (-.pi)/.2.;
  hitbox = 5.;
  friendly = true;
  hit_ids = [];
}

let field1 = {
  location = 0., 0.;
  radius = 50.;
  bits = [];
}

let st1 = {
  player = plyr1;
  enemies = enems;
  bullets = [blt1];
  structures = structs;
  bitfields = [field1];
  wave = 1, calc_wave_time 1;
  points = 0;
  enemies_spawned = 2;
  mode = Normal;
  mouse = (0., 0.);
  can_interact = false;
  build_stats = (1,1);
}

let state_tests = [
  (* test movement of player *)
  "adv_moveN" >:: (fun _ -> let (x,y) = plyr1.location in
                    assert_equal (x,y-.plyr1.speed)
                      (advance_move (0.,-1.) st1).player.location);
  "adv_moveS" >:: (fun _ -> let (x,y) = plyr1.location in
                    assert_equal (x,y+.plyr1.speed)
                      (advance_move (0.,1.) st1).player.location);
  "adv_moveE" >:: (fun _ -> let (x,y) = plyr1.location in
                    assert_equal (x+.plyr1.speed,y)
                      (advance_move (1.,0.) st1).player.location);
  "adv_moveW" >:: (fun _ -> let (x,y) = plyr1.location in
                    assert_equal (x-.plyr1.speed,y)
                      (advance_move (-1.,0.) st1).player.location);

  (* test weapon switching *)
  "adv_scr1" >:: (fun  _ -> let eq_ind = plyr1.equip_index in
                   assert_equal (eq_ind+1)
                     (advance_scroll 1 st1).player.equip_index);
  "adv_scr-1" >:: (fun  _ -> let eq_ind = plyr1.equip_index in
                    assert_equal (eq_ind-1)
                      (advance_scroll (-1) st1).player.equip_index);

  (* test bullet advance *)
  "blt_mv" >:: (fun _ -> let blt1a = List.nth (advance_bullets st1).bullets 0 in
                 assert_equal blt1a.location (add blt1.location blt1.velocity));
  "blt_rm" >:: (fun _ -> let st2 = (st1 |> advance_bullets |> advance_bullets) in
                 assert_equal (List.length st2.bullets) 0);

  (* test enemy advance *)
  "enm_move" >:: (fun _ -> let enem = List.nth (advance_enemies st1).enemies 0 in
                    assert (enem.location <> enem1.location));
  "enm_dir" >:: (fun _ -> let enem = List.nth (advance_enemies st1).enemies 0 in
                  assert (enem.direction <> enem1.direction));
  "enm_stop" >:: (fun _ -> let enem = List.nth (advance_enemies st1).enemies 0 in
                   assert_equal enem.stopped true);

  (* test upgrade advance *)
  "upg_eq" >:: (fun _ ->
      let equips = (advance_upgrade "shotgun" st1).player.equips in
      assert_equal (List.length plyr1.equips + 1) (List.length equips));
  "upg_eq" >:: (fun _ ->
      let p = (advance_upgrade "shotgun" st1).player in
      assert_equal (equip_at_index p.equip_index p.equips).id "shotgun");
]

let suite =
  "Shapeshooter test suite"
  >::: state_tests

let _ = run_test_tt_main suite
