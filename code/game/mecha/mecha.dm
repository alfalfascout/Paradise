#define OCCUPANT_LOGGING occupant ? occupant : "empty mech"

/obj/mecha
	name = "Mecha"
	desc = "Exosuit."
	icon = 'icons/mecha/mecha.dmi'

	density = TRUE //Dense. To raise the heat.
	opacity = TRUE ///opaque. Menacing.
	anchored = TRUE //no pulling around.
	resistance_flags = FIRE_PROOF
	layer = MOB_LAYER //icon draw layer
	infra_luminosity = 15 //byond implementation is bugged.
	force = 5
	max_integrity = 300 //max_integrity is base health
	armor = list(melee = 20, bullet = 10, laser = 0, energy = 0, bomb = 0, rad = 0, fire = 100, acid = 75)
	bubble_icon = "machine"
	cares_about_temperature = TRUE
	var/list/facing_modifiers = list(MECHA_FRONT_ARMOUR = 1.5, MECHA_SIDE_ARMOUR = 1, MECHA_BACK_ARMOUR = 0.5)
	var/initial_icon = null //Mech type for resetting icon. Only used for reskinning kits (see custom items)
	var/can_move = 0 // time of next allowed movement
	/// Time it takes to enter the mech
	var/mech_enter_time = 4 SECONDS
	var/mob/living/carbon/occupant = null
	var/step_in = 10 //make a step in step_in/10 sec.
	var/dir_in = 2//What direction will the mech face when entered/powered on? Defaults to South.
	var/normal_step_energy_drain = 10
	var/step_energy_drain = 10
	var/melee_energy_drain = 15
	var/overload_step_energy_drain_min = 100
	var/deflect_chance = 10 //chance to deflect the incoming projectiles, hits, or lesser the effect of ex_act.
	var/obj/item/stock_parts/cell/cell
	var/state = MECHA_MAINT_OFF
	var/list/log = list()
	var/last_message = 0
	var/add_req_access = 1
	var/maint_access = 1
	var/dna	//dna-locking the mech
	var/list/proc_res = list() //stores proc owners, like proc_res["functionname"] = owner reference
	var/datum/effect_system/spark_spread/spark_system = new
	var/lights = FALSE
	var/lights_power = 6
	var/lights_range = 6
	var/lights_power_ambient = LIGHTING_MINIMUM_POWER
	var/lights_range_ambient = MINIMUM_USEFUL_LIGHT_RANGE
	var/frozen = FALSE
	var/repairing = FALSE
	var/emp_proof = FALSE //If it is immune to emps
	var/emag_proof = FALSE //If it is immune to emagging. Used by CC mechs.

	//inner atmos
	var/use_internal_tank = 0
	var/internal_tank_valve = ONE_ATMOSPHERE
	var/obj/machinery/atmospherics/portable/canister/internal_tank
	var/datum/gas_mixture/cabin_air
	var/obj/machinery/atmospherics/unary/portables_connector/connected_port = null

	var/obj/item/radio/radio = null
	var/list/trackers = list()

	var/max_temperature = 25000
	var/internal_damage_threshold = 50 //health percentage below which internal damage is possible
	var/internal_damage = 0 //contains bitflags

	var/list/operation_req_access = list()//required access level for mecha operation
	var/list/internals_req_access = list(ACCESS_ENGINE,ACCESS_ROBOTICS)//required access level to open cell compartment

	var/obj/structure/mecha_wreckage/wreckage = null  // type that the mecha becomes when destroyed

	var/list/equipment = list()
	var/obj/item/mecha_parts/mecha_equipment/selected
	var/max_equip = 3
	var/turf/crashing = null
	var/occupant_sight_flags = 0

	var/stepsound = 'sound/mecha/mechstep.ogg'
	var/turnsound = 'sound/mecha/mechturn.ogg'
	var/nominalsound = 'sound/mecha/nominal.ogg'
	var/zoomsound = 'sound/mecha/imag_enh.ogg'
	var/critdestrsound = 'sound/mecha/critdestr.ogg'
	var/weapdestrsound = 'sound/mecha/weapdestr.ogg'
	var/lowpowersound = 'sound/mecha/lowpower.ogg'
	var/longactivationsound = 'sound/mecha/nominal.ogg'
	var/starting_voice = /obj/item/mecha_modkit/voice
	var/activated = FALSE
	var/power_warned = FALSE

	/// DMI containing greyscale emissive overlays, responsible for what parts of the mech glow in the dark
	var/emissive_appearance_icon = 'icons/mecha/mecha_emissive.dmi'

	var/destruction_sleep_duration = 2 SECONDS //Time that mech pilot is put to sleep for if mech is destroyed

	var/melee_cooldown = 10
	var/mecha_melee_cooldown = FALSE

	/// How many ion thrusters we got on this bad boy
	var/thruster_count = 0

	// Action vars
	var/defence_mode = FALSE
	var/defence_mode_deflect_chance = 35
	var/leg_overload_mode = FALSE
	var/leg_overload_coeff = 100
	var/thrusters_active = FALSE
	var/smoke = 5
	var/smoke_ready = 1
	var/smoke_cooldown = 100
	var/zoom_mode = FALSE
	var/phasing = FALSE
	var/phasing_energy_drain = 200
	var/phase_state = "" //icon_state when phasing
	/// How much speed the mech loses while the buffer is active
	var/buffer_delay = 1
	/// Does it clean the tile under it?
	var/floor_buffer = FALSE

	//Action datums
	var/datum/action/innate/mecha/mech_eject/eject_action = new
	var/datum/action/innate/mecha/mech_toggle_internals/internals_action = new
	var/datum/action/innate/mecha/mech_toggle_lights/lights_action = new
	var/datum/action/innate/mecha/mech_view_stats/stats_action = new
	var/datum/action/innate/mecha/mech_defence_mode/defense_action = new
	var/datum/action/innate/mecha/mech_overload_mode/overload_action = new
	var/datum/action/innate/mecha/mech_toggle_thrusters/thrusters_action = new
	var/datum/effect_system/smoke_spread/smoke_system = new //not an action, but trigged by one
	var/datum/action/innate/mecha/mech_smoke/smoke_action = new
	var/datum/action/innate/mecha/mech_zoom/zoom_action = new
	var/datum/action/innate/mecha/mech_toggle_phasing/phasing_action = new
	var/datum/action/innate/mecha/mech_switch_damtype/switch_damtype_action = new
	var/list/select_actions = list()

	hud_possible = list (DIAG_STAT_HUD, DIAG_BATT_HUD, DIAG_MECH_HUD, DIAG_TRACK_HUD)

/obj/mecha/Initialize(mapload)
	. = ..()
	icon_state += "-open"
	add_radio()
	add_cabin()
	add_airtank()
	spark_system.set_up(2, 0, src)
	spark_system.attach(src)
	smoke_system.set_up(3, FALSE, src)
	smoke_system.attach(src)
	add_cell()
	START_PROCESSING(SSobj, src)
	GLOB.poi_list |= src
	log_message("[src] created.")
	GLOB.mechas_list += src //global mech list
	prepare_huds()
	for(var/datum/atom_hud/data/diagnostic/diag_hud in GLOB.huds)
		diag_hud.add_to_hud(src)
	diag_hud_set_mechhealth()
	diag_hud_set_mechcell()
	diag_hud_set_mechstat()
	diag_hud_set_mechtracking()

	var/obj/item/mecha_modkit/voice/V = new starting_voice(src)
	V.install(src)
	qdel(V)

	set_light(lights_range_ambient, lights_power_ambient)
	update_icon(UPDATE_OVERLAYS)
	AddElement(/datum/element/hostile_machine)

/obj/mecha/update_overlays()
	. = ..()
	underlays.Cut()
	underlays += emissive_appearance(emissive_appearance_icon, "[icon_state]_lightmask")

////////////////////////
////// Helpers /////////
////////////////////////

/obj/mecha/get_cell()
	return cell

/obj/mecha/proc/add_airtank()
	internal_tank = new /obj/machinery/atmospherics/portable/canister/air(src)
	return internal_tank

/obj/mecha/proc/add_cell(obj/item/stock_parts/cell/C=null)
	if(C)
		C.forceMove(src)
		cell = C
		return
	cell = new/obj/item/stock_parts/cell/high/plus(src)

/obj/mecha/proc/add_cabin()
	cabin_air = new
	cabin_air.set_temperature(T20C)
	cabin_air.volume = 200
	cabin_air.set_oxygen(O2STANDARD * cabin_air.volume / (R_IDEAL_GAS_EQUATION * cabin_air.temperature()))
	cabin_air.set_nitrogen(N2STANDARD * cabin_air.volume / (R_IDEAL_GAS_EQUATION * cabin_air.temperature()))
	return cabin_air

/obj/mecha/proc/add_radio()
	radio = new(src)
	radio.name = "[src] radio"
	radio.icon = icon
	radio.icon_state = icon_state

/obj/mecha/examine(mob/user)
	. = ..()
	var/integrity = obj_integrity * 100 / max_integrity
	switch(integrity)
		if(85 to 100)
			. += "It's fully intact."
		if(65 to 85)
			. += "It's slightly damaged."
		if(45 to 65)
			. += "It's badly damaged."
		if(25 to 45)
			. += "It's heavily damaged."
		else
			. += "It's falling apart."
	if(equipment && length(equipment))
		. += "It's equipped with:"
		for(var/obj/item/mecha_parts/mecha_equipment/ME in equipment)
			. += "[bicon(ME)] [ME]"

/obj/mecha/hear_talk(mob/M, list/message_pieces)
	if(M == occupant && radio.broadcasting)
		radio.talk_into(M, message_pieces)

/obj/mecha/proc/click_action(atom/target, mob/user, params)
	if(!occupant || occupant != user)
		return
	if(user.incapacitated())
		return
	if(phasing)
		occupant_message("<span class='warning'>Unable to interact with objects while phasing.</span>")
		return
	if(state)
		occupant_message("<span class='warning'>Maintenance protocols in effect.</span>")
		return
	if(!get_charge())
		return
	if(src == target)
		return

	var/dir_to_target = get_dir(src, target)
	if(dir_to_target && !(dir_to_target & dir))//wrong direction
		return

	if(hasInternalDamage(MECHA_INT_CONTROL_LOST))
		target = safepick(view(3,target))
		if(!target)
			return

	var/mob/living/L = user
	if(!target.Adjacent(src))
		if(selected && selected.is_ranged())
			if(HAS_TRAIT(L, TRAIT_PACIFISM) && selected.harmful)
				to_chat(L, "<span class='warning'>You don't want to harm other living beings!</span>")
				return
			if(user.mind?.martial_art?.no_guns)
				to_chat(L, "<span class='warning'>[L.mind.martial_art.no_guns_message]</span>")
				return
			selected.action(target, params)
	else if(selected && selected.is_melee())
		if(isliving(target) && selected.harmful && HAS_TRAIT(L, TRAIT_PACIFISM))
			to_chat(user, "<span class='warning'>You don't want to harm other living beings!</span>")
			return
		selected.action(target, params)
	else
		if(internal_damage & MECHA_INT_CONTROL_LOST)
			target = safepick(oview(1, src))
		if(mecha_melee_cooldown || !isatom(target))
			return
		if(iswallturf(target) || isliving(target) || isobj(target))
			target.mech_melee_attack(src)
			mecha_melee_cooldown = TRUE
			addtimer(VARSET_CALLBACK(src, mecha_melee_cooldown, FALSE), melee_cooldown)

/obj/mecha/proc/mech_toxin_damage(mob/living/target)
	playsound(src, 'sound/effects/spray2.ogg', 50, 1)
	if(target.reagents)
		if(target.reagents.get_reagent_amount("atropine") + force < force*2)
			target.reagents.add_reagent("atropine", force/2)
		if(target.reagents.get_reagent_amount("toxin") + force < force*2)
			target.reagents.add_reagent("toxin", force/2.5)

/obj/mecha/proc/range_action(atom/target)
	return


//////////////////////////////////
////////  MARK: Movement procs
//////////////////////////////////

/obj/mecha/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	. = ..()
	if(.)
		return TRUE
	if(thrusters_active && movement_dir && use_power(step_energy_drain))
		step_in = initial(step_in) / thruster_count
		new /obj/effect/particle_effect/ion_trails(get_turf(src), dir)
		return TRUE

	var/atom/movable/backup = get_spacemove_backup()
	if(backup)
		if(istype(backup) && movement_dir && !backup.anchored)
			if(backup.newtonian_move(turn(movement_dir, 180)))
				if(occupant)
					to_chat(occupant, "<span class='notice'>You push off of [backup] to propel yourself.</span>")
		return TRUE

/obj/mecha/relaymove(mob/user, direction)
	if(!direction || frozen)
		return
	if(user != occupant) //While not "realistic", this piece is player friendly.
		user.forceMove(get_turf(src))
		to_chat(user, "<span class='notice'>You climb out from [src].</span>")
		return FALSE
	if(connected_port)
		if(world.time - last_message > 20)
			occupant_message("<span class='warning'>Unable to move while connected to the air system port!</span>")
			last_message = world.time
		return FALSE
	if(state)
		occupant_message("<span class='danger'>Maintenance protocols in effect.</span>")
		return
	return domove(direction)

/obj/mecha/proc/domove(direction)
	if(can_move >= world.time)
		return FALSE
	if(!Process_Spacemove(direction))
		return FALSE
	if(!has_charge(step_energy_drain))
		return FALSE
	if(defence_mode)
		if(world.time - last_message > 20)
			occupant_message("<span class='danger'>Unable to move while in defence mode.</span>")
			last_message = world.time
		return FALSE
	if(zoom_mode)
		if(world.time - last_message > 20)
			occupant_message("<span class='danger'>Unable to move while in zoom mode.</span>")
			last_message = world.time
		return FALSE

	if(thrusters_active && has_gravity(src))
		thrusters_active = FALSE
		to_chat(occupant, "<span class='notice'>Thrusters automatically disabled.</span>")
		step_in = initial(step_in)
	var/move_result = 0
	var/move_type = 0
	if(internal_damage & MECHA_INT_CONTROL_LOST)
		move_result = mechsteprand()
		move_type = MECHAMOVE_RAND
	else if(dir != direction)
		move_result = mechturn(direction)
		move_type = MECHAMOVE_TURN
	else
		move_result = mechstep(direction)
		move_type = MECHAMOVE_STEP

	if(move_result && move_type)
		aftermove(move_type)
		can_move = world.time + step_in
		return TRUE
	return FALSE

/obj/mecha/proc/aftermove(move_type)
	use_power(step_energy_drain)
	if(move_type & (MECHAMOVE_RAND | MECHAMOVE_STEP) && occupant)
		var/obj/machinery/atmospherics/unary/portables_connector/possible_port = locate(/obj/machinery/atmospherics/unary/portables_connector) in loc
		if(possible_port)
			var/atom/movable/screen/alert/mech_port_available/A = occupant.throw_alert("mechaport", /atom/movable/screen/alert/mech_port_available)
			if(A)
				A.target = possible_port
		else
			occupant.clear_alert("mechaport")
	if(leg_overload_mode)
		log_message("Leg Overload damage.")
		take_damage(1, BRUTE, FALSE, FALSE)
		if(obj_integrity < max_integrity - max_integrity / 3)
			leg_overload_mode = FALSE
			step_in = initial(step_in)
			step_energy_drain = initial(step_energy_drain)
			occupant_message("<font color='red'>Leg actuators damage threshold exceded. Disabling overload.</font>")

/obj/mecha/proc/mechturn(direction)
	dir = direction
	if(turnsound)
		playsound(src,turnsound,40,1)
	return TRUE

/obj/mecha/proc/mechstep(direction)
	. = step(src, direction)
	if(!.)
		if(phasing && get_charge() >= phasing_energy_drain)
			if(can_move < world.time)
				. = FALSE // We lie to mech code and say we didn't get to move, because we want to handle power usage + cooldown ourself
				flick("[initial_icon]-phase", src)
				forceMove(get_step(src, direction))
				use_power(phasing_energy_drain)
				playsound(src, stepsound, 40, 1)
				can_move = world.time + (step_in * 3)
	else if(stepsound)
		playsound(src, stepsound, 40, 1)

/obj/mecha/proc/mechsteprand()
	. = step_rand(src)
	if(. && stepsound)
		playsound(src, stepsound, 40, 1)

/obj/mecha/Bump(atom/obstacle)
	if(throwing) //high velocity mechas in your face!
		var/breakthrough = FALSE
		if(istype(obstacle, /obj/structure/window))
			qdel(obstacle)
			breakthrough = TRUE

		else if(istype(obstacle, /obj/structure/grille/))
			var/obj/structure/grille/G = obstacle
			G.obj_break()
			breakthrough = TRUE

		else if(istype(obstacle, /obj/structure/table))
			var/obj/structure/table/T = obstacle
			qdel(T)
			breakthrough = TRUE

		else if(istype(obstacle, /obj/structure/rack))
			new /obj/item/rack_parts(obstacle.loc)
			qdel(obstacle)
			breakthrough = TRUE

		else if(istype(obstacle, /obj/structure/reagent_dispensers/fueltank))
			obstacle.ex_act(EXPLODE_DEVASTATE)

		else if(isliving(obstacle))
			var/mob/living/L = obstacle
			var/hit_sound = list('sound/weapons/genhit1.ogg','sound/weapons/genhit2.ogg','sound/weapons/genhit3.ogg')
			if(L.flags & GODMODE)
				return
			L.take_overall_damage(5,0)
			if(L.buckled)
				L.buckled = 0
			L.Weaken(10 SECONDS)
			L.apply_effect(STUTTER, 10 SECONDS)
			playsound(src, pick(hit_sound), 50, FALSE, 0)
			breakthrough = TRUE

		else
			if(throwing)
				throwing.finalize(FALSE)
			crashing = null

		..()

		if(breakthrough)
			if(crashing)
				spawn(1)
					throw_at(crashing, 50, throw_speed)
			else
				spawn(1)
					crashing = get_distant_turf(get_turf(src), dir, 3)//don't use get_dir(src, obstacle) or the mech will stop if he bumps into a one-direction window on his tile.
					throw_at(crashing, 50, throw_speed)

	else
		if(..())
			return
		if(isobj(obstacle))
			var/obj/O = obstacle
			if(!O.anchored)
				step(obstacle, dir)
		else if(ismob(obstacle))
			step(obstacle, dir)


///////////////////////////////////
////////  MARK: Internal damage
///////////////////////////////////

/obj/mecha/proc/check_for_internal_damage(list/possible_int_damage, ignore_threshold=null)
	if(!islist(possible_int_damage) || isemptylist(possible_int_damage))
		return
	if(prob(20))
		if(ignore_threshold || obj_integrity*100/max_integrity < internal_damage_threshold)
			for(var/T in possible_int_damage)
				if(internal_damage & T)
					possible_int_damage -= T
			var/int_dam_flag = safepick(possible_int_damage)
			if(int_dam_flag)
				setInternalDamage(int_dam_flag)
	if(prob(5))
		if(ignore_threshold || obj_integrity*100/max_integrity < internal_damage_threshold)
			var/obj/item/mecha_parts/mecha_equipment/ME = safepick(equipment)
			if(ME)
				qdel(ME)

/obj/mecha/proc/hasInternalDamage(int_dam_flag=null)
	return int_dam_flag ? internal_damage&int_dam_flag : internal_damage


/obj/mecha/proc/setInternalDamage(int_dam_flag)
	internal_damage |= int_dam_flag
	log_append_to_last("Internal damage of type [int_dam_flag].",1)
	SEND_SOUND(occupant, sound('sound/machines/warning-buzzer.ogg'))
	diag_hud_set_mechstat()

/obj/mecha/proc/clearInternalDamage(int_dam_flag)
	internal_damage &= ~int_dam_flag
	switch(int_dam_flag)
		if(MECHA_INT_TEMP_CONTROL)
			occupant_message("<span class='notice'>Life support system reactivated.</span>")
		if(MECHA_INT_FIRE)
			occupant_message("<span class='notice'>Internal fire extinquished.</span>")
		if(MECHA_INT_TANK_BREACH)
			occupant_message("<span class='notice'>Damaged internal tank has been sealed.</span>")
	diag_hud_set_mechstat()


////////////////////////////////////////
////////  MARK: Health related procs
////////////////////////////////////////

/obj/mecha/proc/get_armour_facing(relative_dir)
	switch(abs(relative_dir))
		if(180) // BACKSTAB!
			return facing_modifiers[MECHA_BACK_ARMOUR]
		if(0, 45)
			return facing_modifiers[MECHA_FRONT_ARMOUR]
	return facing_modifiers[MECHA_SIDE_ARMOUR] //always return non-0

/obj/mecha/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	. = ..()
	if(. && obj_integrity > 0)
		spark_system.start()
		switch(damage_flag)
			if(FIRE)
				check_for_internal_damage(list(MECHA_INT_FIRE,MECHA_INT_TEMP_CONTROL))
			if(MELEE)
				check_for_internal_damage(list(MECHA_INT_TEMP_CONTROL,MECHA_INT_TANK_BREACH,MECHA_INT_CONTROL_LOST))
			else
				check_for_internal_damage(list(MECHA_INT_FIRE,MECHA_INT_TEMP_CONTROL,MECHA_INT_TANK_BREACH,MECHA_INT_CONTROL_LOST,MECHA_INT_SHORT_CIRCUIT))
		if((. >= 5 || prob(33)) && !(. == 1 && leg_overload_mode)) //If it takes 1 damage and leg_overload_mode is true, do not say TAKING DAMAGE! to the user several times a second.
			occupant_message("<span class='userdanger'>Taking damage!</span>")
		log_message("Took [damage_amount] points of damage. Damage type: [damage_type]")

/obj/mecha/run_obj_armor(damage_amount, damage_type, damage_flag = 0, attack_dir)
	. = ..()
	if(!damage_amount)
		return FALSE
	var/booster_deflection_modifier = 1
	var/booster_damage_modifier = 1
	if(damage_flag == BULLET || damage_flag == LASER || damage_flag == ENERGY)
		for(var/obj/item/mecha_parts/mecha_equipment/antiproj_armor_booster/B in equipment)
			if(B.projectile_react())
				booster_deflection_modifier = B.deflect_coeff
				booster_damage_modifier = B.damage_coeff
				break
	else if(damage_flag == MELEE)
		for(var/obj/item/mecha_parts/mecha_equipment/anticcw_armor_booster/B in equipment)
			if(B.attack_react())
				booster_deflection_modifier *= B.deflect_coeff
				booster_damage_modifier *= B.damage_coeff
				break

	if(attack_dir)
		var/facing_modifier = get_armour_facing(dir2angle(attack_dir) - dir2angle(dir))
		booster_damage_modifier /= facing_modifier
		booster_deflection_modifier *= facing_modifier
	if(prob(deflect_chance * booster_deflection_modifier))
		visible_message("<span class='danger'>[src]'s armour deflects the attack!</span>")
		log_message("Armor saved.")
		return FALSE
	if(.)
		. *= booster_damage_modifier

/obj/mecha/attack_hand(mob/living/user)
	user.changeNext_move(CLICK_CD_MELEE)
	user.do_attack_animation(src, ATTACK_EFFECT_PUNCH)
	playsound(loc, 'sound/weapons/tap.ogg', 40, TRUE, -1)
	user.visible_message("<span class='notice'>[user] hits [name]. Nothing happens</span>", "<span class='notice'>You hit [name] with no visible effect.</span>")
	log_message("Attack by hand/paw. Attacker - [user].")


/obj/mecha/attack_alien(mob/living/user)
	log_message("Attack by alien. Attacker - [user].", TRUE)
	add_attack_logs(user, OCCUPANT_LOGGING, "Alien attacked mech [src]")
	playsound(src.loc, 'sound/weapons/slash.ogg', 100, TRUE)
	attack_generic(user, 15, BRUTE, MELEE, 0)

/obj/mecha/attack_animal(mob/living/simple_animal/user)
	log_message("Attack by simple animal. Attacker - [user].")
	if(!user.melee_damage_upper && !user.obj_damage)
		user.custom_emote(EMOTE_VISIBLE, "[user.friendly] [src].")
		return FALSE
	else
		var/play_soundeffect = TRUE
		var/animal_damage = rand(user.melee_damage_lower,user.melee_damage_upper)
		if(user.obj_damage)
			animal_damage = max(animal_damage, user.obj_damage)
		animal_damage = max(animal_damage, min(20 * user.environment_smash, 40))
		if(animal_damage)
			add_attack_logs(user, OCCUPANT_LOGGING, "Animal attacked mech [src]")
		if(user.environment_smash)
			play_soundeffect = FALSE
			playsound(src, 'sound/effects/bang.ogg', 50, TRUE)
		attack_generic(user, animal_damage, user.melee_damage_type, MELEE, play_soundeffect)
		return TRUE

/obj/mecha/hulk_damage()
	return 15

/obj/mecha/attack_hulk(mob/living/carbon/human/user)
	. = ..()
	if(.)
		log_message("Attack by hulk. Attacker - [user].", 1)
		add_attack_logs(user, OCCUPANT_LOGGING, "Hulk punched mech [src]")

/obj/mecha/blob_act(obj/structure/blob/B)
	log_message("Attack by blob. Attacker - [B].")
	take_damage(30, BRUTE, MELEE, 0, get_dir(src, B))

/obj/mecha/attack_tk()
	return

/obj/mecha/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum) //wrapper
	log_message("Hit by [AM].")
	if(isitem(AM))
		var/obj/item/I = AM
		add_attack_logs(locateUID(I.thrownby), OCCUPANT_LOGGING, "threw [AM] at mech [src]")
	. = ..()

/obj/mecha/bullet_act(obj/item/projectile/Proj) //wrapper
	log_message("Hit by projectile. Type: [Proj.name]([Proj.flag]).")
	add_attack_logs(Proj.firer, OCCUPANT_LOGGING, "shot [Proj.name]([Proj.flag]) at mech [src]")
	..()

/obj/mecha/ex_act(severity, target)
	log_message("Affected by explosion of severity: [severity].")
	if(prob(deflect_chance))
		severity++
		log_message("Armor saved, changing severity to [severity]")
	..()
	severity++
	for(var/X in equipment)
		var/obj/item/mecha_parts/mecha_equipment/ME = X
		ME.ex_act(severity)
	for(var/Y in trackers)
		var/obj/item/mecha_parts/mecha_tracking/MT = Y
		MT.ex_act(severity)
	if(occupant)
		occupant.ex_act(severity)

/obj/mecha/handle_atom_del(atom/A)
	if(A == occupant)
		occupant = null
		icon_state = reset_icon(icon_state)+"-open"
		setDir(dir_in)
	if(A in trackers)
		trackers -= A

/obj/mecha/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(occupant)
		occupant.SetSleeping(destruction_sleep_duration)
	go_out()
	for(var/mob/M in src) //Let's just be ultra sure
		if(is_ai(M))
			var/mob/living/silicon/ai/AI = M //AIs are loaded into the mech computer itself. When the mech dies, so does the AI. They can be recovered with an AI card from the wreck.
			AI.gib() //No wreck, no AI to recover
		else
			M.forceMove(loc)
	occupant = null
	selected = null
	for(var/obj/item/mecha_parts/mecha_equipment/E in equipment)
		E.detach(loc)
		qdel(E)
	equipment.Cut()
	QDEL_NULL(cell)
	QDEL_NULL(internal_tank)
	QDEL_NULL(radio)
	GLOB.poi_list.Remove(src)
	var/turf/T = get_turf(src)
	if(T)
		T.blind_release_air(cabin_air)
	else
		qdel(cabin_air)
	cabin_air = null
	connected_port = null
	QDEL_NULL(spark_system)
	QDEL_NULL(smoke_system)
	QDEL_LIST_CONTENTS(trackers)
	remove_from_all_data_huds()
	GLOB.mechas_list -= src //global mech list
	return ..()

//TODO
/obj/mecha/emp_act(severity)
	if(emp_proof)
		return
	if(get_charge())
		use_power((cell.charge/3)/(severity*2))
		take_damage(30 / severity, BURN, ENERGY, 1)
	log_message("EMP detected", 1)
	check_for_internal_damage(list(MECHA_INT_FIRE, MECHA_INT_TEMP_CONTROL, MECHA_INT_CONTROL_LOST, MECHA_INT_SHORT_CIRCUIT), 1)

/obj/mecha/temperature_expose(exposed_temperature, exposed_volume)
	..()
	if(exposed_temperature > max_temperature)
		log_message("Exposed to dangerous temperature.", 1)
		take_damage(5, BURN, 0, 1)
		check_for_internal_damage(list(MECHA_INT_FIRE, MECHA_INT_TEMP_CONTROL))

//////////////////////
////// MARK: AttackBy
//////////////////////

/obj/mecha/attackby__legacy__attackchain(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/mmi))
		if(mmi_move_inside(W,user))
			to_chat(user, "[src]-MMI interface initialized successfuly")
		else
			to_chat(user, "[src]-MMI interface initialization failed.")
		return

	if(istype(W, /obj/item/mecha_parts/mecha_equipment))
		var/obj/item/mecha_parts/mecha_equipment/E = W
		spawn()
			if(E.can_attach(src))
				if(!user.drop_item())
					return
				E.attach(src)
				user.visible_message("[user] attaches [W] to [src].", "<span class='notice'>You attach [W] to [src].</span>")
			else
				to_chat(user, "<span class='warning'>You were unable to attach [W] to [src]!</span>")
		return

	if(W.GetID())
		if(add_req_access || maint_access)
			if(internals_access_allowed(usr))
				var/obj/item/card/id/id_card
				if(istype(W, /obj/item/card/id))
					id_card = W
				else
					var/obj/item/pda/pda = W
					id_card = pda.id
				output_maintenance_dialog(id_card, user)
				return
			else
				to_chat(user, "<span class='warning'>Invalid ID: Access denied.</span>")
		else
			to_chat(user, "<span class='warning'>Maintenance protocols disabled by operator.</span>")

	else if(istype(W, /obj/item/stack/cable_coil))
		if(state == MECHA_OPEN_HATCH && hasInternalDamage(MECHA_INT_SHORT_CIRCUIT))
			var/obj/item/stack/cable_coil/CC = W
			if(CC.get_amount() > 1)
				CC.use(2)
				clearInternalDamage(MECHA_INT_SHORT_CIRCUIT)
				to_chat(user, "You replace the fused wires.")
			else
				to_chat(user, "There's not enough wire to finish the task.")
		return

	else if(istype(W, /obj/item/stock_parts/cell))
		if(state == MECHA_BATTERY_UNSCREW)
			if(!cell)
				if(!user.drop_item())
					return
				to_chat(user, "<span class='notice'>You install the powercell.</span>")
				W.forceMove(src)
				cell = W
				log_message("Powercell installed")
			else
				to_chat(user, "<span class='notice'>There's already a powercell installed.</span>")
		return

	else if(istype(W, /obj/item/mecha_parts/mecha_tracking))
		if(!user.drop_item_to_ground(W))
			to_chat(user, "<span class='notice'>\the [W] is stuck to your hand, you cannot put it in \the [src]</span>")
			return

		// Check if a tracker exists
		var/obj/item/mecha_parts/mecha_tracking/new_tracker = W
		for(var/obj/item/mecha_parts/mecha_tracking/current_tracker in trackers)
			if(new_tracker.type == current_tracker.type)
				to_chat(user, "<span class='warning'>This exosuit already has a [current_tracker].</span>")
				user.put_in_hands(new_tracker)
				return

			trackers -= current_tracker
			to_chat(user, "<span class='notice'>You remove [current_tracker].</span>")
			var/obj/item/mecha_parts/mecha_tracking/duplicate_tracker = new current_tracker.type
			user.put_in_hands(duplicate_tracker)
			qdel(current_tracker)
		new_tracker.forceMove(src)
		trackers += W
		user.visible_message("[user] attaches [new_tracker] to [src].", "<span class='notice'>You attach [new_tracker] to [src].</span>")
		diag_hud_set_mechtracking()
		return

	else if(istype(W, /obj/item/paintkit))
		if(occupant)
			to_chat(user, "You can't customize a mech while someone is piloting it - that would be unsafe!")
			return

		var/obj/item/paintkit/P = W
		var/found = null

		for(var/type in P.allowed_types)
			if(type == initial_icon)
				found = 1
				break

		if(!found)
			to_chat(user, "That kit isn't meant for use on this class of exosuit.")
			return

		user.visible_message("[user] opens [P] and spends some quality time customising [src].")
		if(do_after_once(user, 3 SECONDS, target = src))
			name = P.new_name
			desc = P.new_desc
			initial_icon = P.new_icon
			reset_icon()
			user.drop_item()
			qdel(P)

	else if(istype(W, /obj/item/mecha_modkit))
		if(occupant)
			to_chat(user, "<span class='notice'>You can't access the mech's modification port while it is occupied.</span>")
			return
		var/obj/item/mecha_modkit/M = W
		if(do_after_once(user, M.install_time, target = src))
			M.install(src, user)
		else
			to_chat(user, "<span class='notice'>You stop installing [M].</span>")

	else
		if(W.force)
			add_attack_logs(user, OCCUPANT_LOGGING, "attacked mech '[src]' using [W]")
		return ..()


/obj/mecha/crowbar_act(mob/user, obj/item/I)
	if(state != MECHA_BOLTS_UP && state != MECHA_OPEN_HATCH && !(state == MECHA_BATTERY_UNSCREW && occupant))
		return
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = I.tool_volume))
		return
	if(state == MECHA_BOLTS_UP)
		state = MECHA_OPEN_HATCH
		to_chat(user, "You open the hatch to the power unit")
	else if(state == MECHA_OPEN_HATCH)
		state = MECHA_BOLTS_UP
		to_chat(user, "You close the hatch to the power unit")
	else if(ishuman(occupant))
		user.visible_message("<span class='notice'>[user] begins levering out the driver from the [src].</span>", "<span class='notice'>You begin to lever out the driver from the [src].</span>")
		to_chat(occupant, "<span class='warning'>[user] is prying you out of the exosuit!</span>")
		if(I.use_tool(src, user, 8 SECONDS, volume = I.tool_volume))
			user.visible_message("<span class='notice'>[user] pries the driver out of the [src]!</span>", "<span class='notice'>You finish removing the driver from the [src]!</span>")
			go_out()
	else
		// Since having maint protocols available is controllable by the MMI, I see this as a consensual way to remove an MMI without destroying the mech
		user.visible_message("<span class='notice'>[user] begins levering out the MMI from [src].</span>", "<span class='notice'>You begin to lever out the MMI from [src].</span>")
		to_chat(occupant, "<span class='warning'>[user] is prying you out of the exosuit!</span>")
		if(I.use_tool(src, user, 8 SECONDS, volume = I.tool_volume) && pilot_is_mmi())
			user.visible_message("<span class='notice'>[user] pries the MMI out of [src]!</span>", "<span class='notice'>You finish removing the MMI from [src]!</span>")
			go_out()

/obj/mecha/screwdriver_act(mob/user, obj/item/I)
	if(user.a_intent == INTENT_HARM)
		return
	if(!(state == MECHA_OPEN_HATCH && cell) && !(state == MECHA_BATTERY_UNSCREW && cell))
		return
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = I.tool_volume))
		return
	if(hasInternalDamage(MECHA_INT_TEMP_CONTROL))
		clearInternalDamage(MECHA_INT_TEMP_CONTROL)
		to_chat(user, "<span class='notice'>You repair the damaged temperature controller.</span>")
	else if(state == MECHA_OPEN_HATCH && cell)
		cell.forceMove(loc)
		cell = null
		state = MECHA_BATTERY_UNSCREW
		to_chat(user, "<span class='notice'>You unscrew and pry out the powercell.</span>")
		log_message("Powercell removed")
	else if(state == MECHA_BATTERY_UNSCREW && cell)
		state = MECHA_OPEN_HATCH
		to_chat(user, "<span class='notice'>You screw the cell in place.</span>")

/obj/mecha/wrench_act(mob/user, obj/item/I)
	if(state != MECHA_MAINT_ON && state != MECHA_BOLTS_UP)
		return
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = I.tool_volume))
		return
	if(state == MECHA_MAINT_ON)
		state = MECHA_BOLTS_UP
		to_chat(user, "You undo the securing bolts.")
	else
		state = MECHA_MAINT_ON
		to_chat(user, "You tighten the securing bolts.")

/obj/mecha/welder_act(mob/user, obj/item/I)
	if(user.a_intent == INTENT_HARM)
		return
	. = TRUE
	if(!I.tool_use_check(user, 0))
		return
	if((obj_integrity >= max_integrity) && !internal_damage)
		to_chat(user, "<span class='notice'>[src] is at full integrity!</span>")
		return
	if(repairing)
		to_chat(user, "<span class='notice'>[src] is currently being repaired!</span>")
		return
	if(state == MECHA_MAINT_OFF) // If maint protocols are not active, the state is zero
		to_chat(user, "<span class='warning'>[src] can not be repaired without maintenance protocols active!</span>")
		return
	WELDER_ATTEMPT_REPAIR_MESSAGE
	repairing = TRUE
	if(I.use_tool(src, user, 15, volume = I.tool_volume))
		if(internal_damage & MECHA_INT_TANK_BREACH)
			clearInternalDamage(MECHA_INT_TANK_BREACH)
			user.visible_message("<span class='notice'>[user] repairs the damaged gas tank.</span>", "<span class='notice'>You repair the damaged gas tank.</span>")
		else if(obj_integrity < max_integrity)
			user.visible_message("<span class='notice'>[user] repairs some damage to [name].</span>", "<span class='notice'>You repair some damage to [name].</span>")
			obj_integrity += min(10, max_integrity - obj_integrity)
		else
			to_chat(user, "<span class='notice'>[src] is at full integrity!</span>")
	repairing = FALSE

/obj/mecha/mech_melee_attack(obj/mecha/M)
	if(!has_charge(melee_energy_drain))
		return FALSE
	use_power(melee_energy_drain)
	if(M.damtype == BRUTE || M.damtype == BURN)
		add_attack_logs(M.occupant, src, "Mecha-attacked with [M] ([uppertext(M.occupant.a_intent)]) ([uppertext(M.damtype)])")
		. = ..()

/obj/mecha/emag_act(mob/user)
	if(emag_proof)
		to_chat(user, "<span class='warning'>[src]'s ID slot rejects the card.</span>")
		return
	user.visible_message("<span class='notice'>[user] slides a card through [src]'s id slot.</span>", "<span class='notice'>You slide the card through [src]'s ID slot, resetting the DNA and access locks.</span>")
	playsound(loc, "sparks", 100, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	dna = null
	operation_req_access = list()
	return TRUE



/////////////////////////////////////
//////////// MARK: AI piloting
/////////////////////////////////////

/obj/mecha/attack_ai(mob/living/silicon/ai/user)
	if(!is_ai(user))
		return
	//Allows the Malf to scan a mech's status and loadout, helping it to decide if it is a worthy chariot.
	if(user.can_dominate_mechs)
		examine(user) //Get diagnostic information!
		for(var/obj/item/mecha_parts/mecha_tracking/B in trackers)
			to_chat(user, "<span class='danger'>Warning: Tracking Beacon detected. Enter at your own risk. Beacon Data:")
			to_chat(user, "[B.get_mecha_info_text()]")
			break
		//Nothing like a big, red link to make the player feel powerful!
		to_chat(user, "<a href='byond://?src=[user.UID()];ai_take_control=\ref[src]'><span class='userdanger'>ASSUME DIRECT CONTROL?</span></a><br>")
	else
		examine(user)
		if(occupant)
			to_chat(user, "<span class='warning'>This exosuit has a pilot and cannot be controlled.</span>")
			return
		var/can_control_mech = FALSE
		for(var/obj/item/mecha_parts/mecha_tracking/ai_control/A in trackers)
			can_control_mech = TRUE
			to_chat(user, "<span class='notice'>[bicon(src)] Status of [name]:</span>\n\
				[A.get_mecha_info_text()]")
			break
		if(!can_control_mech)
			to_chat(user, "<span class='warning'>You cannot control exosuits without AI control beacons installed.</span>")
			return
		to_chat(user, "<a href='byond://?src=[user.UID()];ai_take_control=\ref[src]'><span class='boldnotice'>Take control of exosuit?</span></a><br>")

/obj/mecha/transfer_ai(interaction, mob/user, mob/living/silicon/ai/AI, obj/item/aicard/card)
	if(!..())
		return

 //Transfer from core or card to mech. Proc is called by mech.
	switch(interaction)
		if(AI_TRANS_TO_CARD) //Upload AI from mech to AI card.
			if(!maint_access) //Mech must be in maint mode to allow carding.
				to_chat(user, "<span class='warning'>[name] must have maintenance protocols active in order to allow a transfer.</span>")
				return
			AI = occupant
			if(!AI || !is_ai(occupant)) //Mech does not have an AI for a pilot
				to_chat(user, "<span class='warning'>No AI detected in the [name] onboard computer.</span>")
				return
			if(AI.mind.special_role) //Malf AIs cannot leave mechs. Except through death.
				to_chat(user, "<span class='boldannounceic'>ACCESS DENIED.</span>")
				return
			AI.aiRestorePowerRoutine = 0//So the AI initially has power.
			AI.control_disabled = TRUE
			AI.aiRadio.disabledAi = TRUE
			AI.forceMove(card)
			occupant = null
			AI.controlled_mech = null
			AI.remote_control = null
			icon_state = reset_icon(icon_state)+"-open"
			to_chat(AI, "You have been downloaded to a mobile storage device. Wireless connection offline.")
			to_chat(user, "<span class='boldnotice'>Transfer successful</span>: [AI.name] ([rand(1000,9999)].exe) removed from [name] and stored within local memory.")

		if(AI_MECH_HACK) //Called by AIs on the mech
			AI.linked_core = new /obj/structure/ai_core/deactivated(AI.loc)
			if(AI.can_dominate_mechs)
				if(occupant) //Oh, I am sorry, were you using that?
					to_chat(AI, "<span class='warning'>Pilot detected! Forced ejection initiated!")
					to_chat(occupant, "<span class='danger'>You have been forcibly ejected!</span>")
					go_out(1) //IT IS MINE, NOW. SUCK IT, RD!
			ai_enter_mech(AI, interaction)

		if(AI_TRANS_FROM_CARD) //Using an AI card to upload to a mech.
			AI = locate(/mob/living/silicon/ai) in card
			if(!AI)
				to_chat(user, "<span class='warning'>There is no AI currently installed on this device.</span>")
				return
			else if(AI.stat || !AI.client)
				to_chat(user, "<span class='warning'>[AI.name] is currently unresponsive, and cannot be uploaded.</span>")
				return
			else if(occupant || dna) //Normal AIs cannot steal mechs!
				to_chat(user, "<span class='warning'>Access denied. [name] is [occupant ? "currently occupied" : "secured with a DNA lock"].")
				return
			AI.control_disabled = FALSE
			AI.aiRadio.disabledAi = FALSE
			to_chat(user, "<span class='boldnotice'>Transfer successful</span>: [AI.name] ([rand(1000,9999)].exe) installed and executed successfully. Local copy has been removed.")
			ai_enter_mech(AI, interaction)

//Hack and From Card interactions share some code, so leave that here for both to use.
/obj/mecha/proc/ai_enter_mech(mob/living/silicon/ai/AI, interaction)
	var/mob/camera/eye/hologram/hologram_eye = AI.remote_control
	if(istype(hologram_eye))
		hologram_eye.release_control()
		qdel(hologram_eye)
	AI.aiRestorePowerRoutine = 0
	AI.forceMove(src)
	occupant = AI
	icon_state = reset_icon(icon_state)
	update_icon(UPDATE_OVERLAYS)
	playsound(src, 'sound/machines/windowdoor.ogg', 50, 1)
	if(!hasInternalDamage())
		SEND_SOUND(occupant, sound(nominalsound, volume = 50))
	AI.cancel_camera()
	AI.controlled_mech = src
	AI.remote_control = src
	AI.reset_perspective(src)
	AI.can_shunt = FALSE //ONE AI ENTERS. NO AI LEAVES.
	to_chat(AI, "[AI.can_dominate_mechs ? "<span class='boldnotice'>Takeover of [name] complete! You are now permanently loaded onto the onboard computer. Do not attempt to leave the station sector!</span>" \
	: "<span class='notice'>You have been uploaded to a mech's onboard computer."]")
	to_chat(AI, "<span class='boldnotice'>Use Middle-Mouse to activate mech functions and equipment. Click normally for AI interactions.</span>")
	if(interaction == AI_TRANS_FROM_CARD)
		GrantActions(AI, FALSE)
	else
		GrantActions(AI, !AI.can_dominate_mechs)

/////////////////////////////////////
////////  MARK: Atmospheric stuff
/////////////////////////////////////

/obj/mecha/return_obj_air()
	RETURN_TYPE(/datum/gas_mixture)
	if(use_internal_tank)
		return cabin_air
	return null

/obj/mecha/return_analyzable_air()
	if(use_internal_tank)
		return cabin_air
	return null

/obj/mecha/proc/connect(obj/machinery/atmospherics/unary/portables_connector/new_port)
	//Make sure not already connected to something else
	if(connected_port || !istype(new_port) || new_port.connected_device)
		return FALSE

	//Make sure are close enough for a valid connection
	if(new_port.loc != loc)
		return FALSE

	//Perform the connection
	connected_port = new_port
	connected_port.connected_device = src
	connected_port.parent.reconcile_air()

	if(occupant)
		occupant.clear_alert("mechaport")
		occupant.throw_alert("mechaport_d", /atom/movable/screen/alert/mech_port_disconnect)

	log_message("Connected to gas port.")
	return TRUE

/obj/mecha/proc/disconnect()
	if(!connected_port)
		return FALSE

	connected_port.connected_device = null
	connected_port = null
	log_message("Disconnected from gas port.")
	if(occupant)
		occupant.clear_alert("mechaport_d")
	return TRUE

/obj/mecha/portableConnectorReturnAir()
	return internal_tank.return_obj_air()

/obj/mecha/proc/toggle_lights(show_message = TRUE)
	lights = !lights
	if(lights)
		set_light(lights_range, lights_power)
	else
		set_light(lights_range_ambient, lights_power_ambient)
	if(show_message)
		occupant_message("Toggled lights [lights ? "on" : "off"].")
		log_message("Toggled lights [lights ? "on" : "off"].")

/obj/mecha/extinguish_light(force)
	if(!lights)
		return
	toggle_lights(show_message = FALSE)

/obj/mecha/proc/toggle_internal_tank()
	use_internal_tank = !use_internal_tank
	occupant_message("Now taking air from [use_internal_tank ? "internal airtank" : "environment"].")
	log_message("Now taking air from [use_internal_tank ? "internal airtank" : "environment"].")

/obj/mecha/MouseDrop_T(mob/M, mob/user)
	if(frozen)
		to_chat(user, "<span class='warning'>Do not enter Admin-Frozen mechs.</span>")
		return TRUE
	if(user.incapacitated())
		return
	if(user != M)
		return
	log_message("[user] tries to move in.")
	if(occupant)
		to_chat(user, "<span class='warning'>[src] is already occupied!</span>")
		log_append_to_last("Permission denied.")
		return TRUE
	var/passed
	if(dna)
		if(ishuman(user))
			if(user.dna.unique_enzymes == dna)
				passed = TRUE
	else if(operation_allowed(user))
		passed = TRUE
	if(!passed)
		to_chat(user, "<span class='warning'>Access denied.</span>")
		log_append_to_last("Permission denied.")
		return TRUE
	if(user.buckled)
		to_chat(user, "<span class='warning'>You are currently buckled and cannot move.</span>")
		log_append_to_last("Permission denied.")
		return TRUE
	if(user.has_buckled_mobs()) //mob attached to us
		to_chat(user, "<span class='warning'>You can't enter the exosuit with other creatures attached to you!</span>")
		return TRUE

	visible_message("<span class='notice'>[user] starts to climb into [src]")
	INVOKE_ASYNC(src, TYPE_PROC_REF(/obj/mecha, put_in), user)
	return TRUE

/obj/mecha/proc/put_in(mob/user) // need this proc to use INVOKE_ASYNC in other proc. You're not recommended to use that one
	if(do_after(user, mech_enter_time, target = src))
		if(obj_integrity <= 0)
			to_chat(user, "<span class='warning'>You cannot get in the [name], it has been destroyed!</span>")
		else if(occupant)
			to_chat(user, "<span class='danger'>[occupant] was faster! Try better next time, loser.</span>")
		else if(user.buckled)
			to_chat(user, "<span class='warning'>You can't enter the exosuit while buckled.</span>")
		else if(user.has_buckled_mobs())
			to_chat(user, "<span class='warning'>You can't enter the exosuit with other creatures attached to you!</span>")
		else
			moved_inside(user)
	else
		to_chat(user, "<span class='warning'>You stop entering the exosuit!</span>")

/obj/mecha/proc/moved_inside(mob/living/carbon/human/H as mob)
	if(H && H.client && (H in range(1)))
		occupant = H
		H.stop_pulling()
		H.forceMove(src)
		add_fingerprint(H)
		GrantActions(H, human_occupant = 1)
		forceMove(loc)
		log_append_to_last("[H] moved in as pilot.")
		icon_state = reset_icon()
		dir = dir_in
		playsound(src, 'sound/machines/windowdoor.ogg', 50, 1)
		if(!activated)
			SEND_SOUND(occupant, sound(longactivationsound, volume = 50))
			activated = TRUE
		else if(!hasInternalDamage())
			SEND_SOUND(occupant, sound(nominalsound, volume = 50))
		if(state)
			H.throw_alert("locked", /atom/movable/screen/alert/mech_maintenance)
		if(connected_port)
			H.throw_alert("mechaport_d", /atom/movable/screen/alert/mech_port_disconnect)
		update_icon(UPDATE_OVERLAYS)
		return TRUE
	else
		return FALSE

/obj/mecha/proc/mmi_move_inside(obj/item/mmi/mmi_as_oc as obj,mob/user as mob)
	if(!mmi_as_oc.brainmob || !mmi_as_oc.brainmob.client)
		to_chat(user, "<span class='warning'>Consciousness matrix not detected!</span>")
		return FALSE
	else if(mmi_as_oc.brainmob.stat)
		to_chat(user, "<span class='warning'>Beta-rhythm below acceptable level!</span>")
		return FALSE
	else if(occupant)
		to_chat(user, "<span class='warning'>Occupant detected!</span>")
		return FALSE
	else if(dna && dna != mmi_as_oc.brainmob.dna.unique_enzymes)
		to_chat(user, "<span class='warning'>Access denied. [name] is secured with a DNA lock.</span>")
		return FALSE
	else if(!operation_allowed(user))
		to_chat(user, "<span class='warning'>Access denied. [name] is secured with an ID lock.</span>")
		return FALSE

	if(do_after(user, 4 SECONDS, target = src))
		if(!occupant)
			return mmi_moved_inside(mmi_as_oc,user)
		else
			to_chat(user, "<span class='warning'>Occupant detected!</span>")
	else
		to_chat(user, "<span class='notice'>You stop inserting the MMI.</span>")
	return FALSE

/obj/mecha/proc/mmi_moved_inside(obj/item/mmi/mmi_as_oc, mob/user)
	if(mmi_as_oc && (user in range(1)))
		if(!mmi_as_oc.brainmob || !mmi_as_oc.brainmob.client)
			to_chat(user, "Consciousness matrix not detected.")
			return FALSE
		else if(mmi_as_oc.brainmob.stat)
			to_chat(user, "Beta-rhythm below acceptable level.")
			return FALSE
		if(!user.drop_item_to_ground(mmi_as_oc))
			to_chat(user, "<span class='notice'>\the [mmi_as_oc] is stuck to your hand, you cannot put it in \the [src]</span>")
			return FALSE
		var/mob/living/brain/brainmob = mmi_as_oc.brainmob
		brainmob.reset_perspective(src)
		occupant = brainmob
		brainmob.forceMove(src) //should allow relaymove
		if(istype(mmi_as_oc, /obj/item/mmi/robotic_brain))
			var/obj/item/mmi/robotic_brain/R = mmi_as_oc
			if(R.imprinted_master)
				to_chat(brainmob, "<span class='biggerdanger'>Your imprint to [R.imprinted_master] has been temporarily disabled. You should help the crew and not commit harm.</span>")
		mmi_as_oc.loc = src
		mmi_as_oc.mecha = src
		Entered(mmi_as_oc)
		Move(loc)
		icon_state = reset_icon()
		dir = dir_in
		update_icon(UPDATE_OVERLAYS)
		log_message("[mmi_as_oc] moved in as pilot.")
		if(!hasInternalDamage())
			SEND_SOUND(occupant, sound(nominalsound, volume = 50))
		GrantActions(brainmob)
		return TRUE
	else
		return FALSE

/obj/mecha/proc/pilot_is_mmi()
	var/atom/movable/mob_container
	if(isbrain(occupant))
		var/mob/living/brain/brain = occupant
		mob_container = brain.container
	if(istype(mob_container, /obj/item/mmi))
		return TRUE
	return FALSE

/obj/mecha/proc/pilot_mmi_hud(mob/living/brain/pilot)
	return

/obj/mecha/Exited(atom/movable/M, direction)
	var/new_loc = get_step(M, direction)
	if(occupant && occupant == M) // The occupant exited the mech without calling go_out()
		if(!is_ai(occupant)) //This causes carded AIS to gib, so we do not want this to be called during carding.
			go_out(1, new_loc)

/obj/mecha/proc/go_out(forced, atom/newloc = loc)
	if(!occupant)
		return
	var/atom/movable/mob_container
	occupant.clear_alert("charge")
	occupant.clear_alert("locked")
	occupant.clear_alert("mech damage")
	occupant.clear_alert("mechaport")
	occupant.clear_alert("mechaport_d")
	if(ishuman(occupant))
		mob_container = occupant
		RemoveActions(occupant, human_occupant = 1)
	else if(isbrain(occupant))
		var/mob/living/brain/brain = occupant
		RemoveActions(brain)
		mob_container = brain.container
	else if(is_ai(occupant))
		var/mob/living/silicon/ai/AI = occupant
		if(forced)//This should only happen if there are multiple AIs in a round, and at least one is Malf.
			RemoveActions(occupant)
			occupant.gib()  //If one Malf decides to steal a mech from another AI (even other Malfs!), they are destroyed, as they have nowhere to go when replaced.
			occupant = null
			return
		else
			if(!AI.linked_core || QDELETED(AI.linked_core))
				to_chat(AI, "<span class='userdanger'>Inactive core destroyed. Unable to return.</span>")
				AI.linked_core = null
				return
			to_chat(AI, "<span class='notice'>Returning to core...</span>")
			AI.controlled_mech = null
			if(istype(AI.eyeobj))
				AI.remote_control = AI.eyeobj
				AI.reset_perspective(AI.eyeobj)
			else
				AI.eyeobj = new /mob/camera/eye/ai(loc, AI.name, AI, AI)
			RemoveActions(occupant, 1)
			mob_container = AI
			newloc = get_turf(AI.linked_core)
			AI.eyeobj?.set_loc(newloc)
			qdel(AI.linked_core)
	else
		return
	var/mob/living/L = occupant
	occupant = null //we need it null when forceMove calls Exited().
	if(mob_container.forceMove(newloc))//ejecting mob container
		log_message("[mob_container] moved out.")
		L << browse(null, "window=exosuit")

		if(istype(mob_container, /obj/item/mmi))
			var/obj/item/mmi/mmi = mob_container
			if(mmi.brainmob)
				L.forceMove(mmi)
				L.reset_perspective()
			mmi.mecha = null
			mmi.update_icon()
			if(istype(mmi, /obj/item/mmi/robotic_brain))
				var/obj/item/mmi/robotic_brain/R = mmi
				if(R.imprinted_master)
					to_chat(L, "<span class='notice'>Imprint re-enabled, you are once again bound to [R.imprinted_master]'s commands.</span>")
		icon_state = reset_icon(icon_state)+"-open"
		dir = dir_in

	if(L && L.client)
		L.client.RemoveViewMod("mecha")
		zoom_mode = FALSE

	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		H.regenerate_icons() // workaround for 14457
	update_icon(UPDATE_OVERLAYS)

/obj/mecha/force_eject_occupant(mob/target)
	go_out()

// Called when a shuttle lands on top of the mech. Prevents the mech from just dropping the pilot unharmed inside the shuttle when destroyed.
/obj/mecha/proc/get_out_and_die()
	var/mob/living/pilot = occupant
	pilot.visible_message(
		"<span class='warning'>[src] is hit by a hyperspace ripple!</span>",
		"<span class='userdanger'>You feel an immense crushing pressure as the space around you ripples.</span>"
	)
	go_out(TRUE)
	if(iscarbon(pilot))
		pilot.gib()
	qdel(src)

/////////////////////////
////// MARK: Access stuff
/////////////////////////

/obj/mecha/proc/operation_allowed(mob/living/carbon/human/H)
	if(!ishuman(H))
		return 0
	for(var/ID in list(H.get_active_hand(), H.wear_id, H.belt, H.wear_pda))
		if(check_access(ID, operation_req_access))
			return TRUE
	return FALSE


/obj/mecha/proc/internals_access_allowed(mob/living/carbon/human/H)
	for(var/atom/ID in list(H.get_active_hand(), H.wear_id, H.belt, H.wear_pda))
		if(check_access(ID, internals_req_access))
			return TRUE
	return FALSE


/obj/mecha/check_access(obj/item/card/id/I, list/access_list)
	if(!istype(access_list))
		return TRUE
	if(!length(access_list)) //no requirements
		return TRUE
	I = I?.GetID()
	if(!istype(I) || !I.access) //not ID or no access
		return FALSE
	if(access_list==operation_req_access)
		for(var/req in access_list)
			if(!(req in I.access)) //doesn't have this access
				return FALSE
	else if(access_list==internals_req_access)
		for(var/req in access_list)
			if(req in I.access)
				return TRUE
	return TRUE

///////////////////////
///// MARK: Power stuff
///////////////////////

/obj/mecha/proc/has_charge(amount)
	return (get_charge()>=amount)

/obj/mecha/proc/get_charge()
	for(var/obj/item/mecha_parts/mecha_equipment/tesla_energy_relay/R in equipment)
		var/relay_charge = R.get_charge()
		if(relay_charge)
			return relay_charge
	if(cell)
		return max(0, cell.charge)

/obj/mecha/proc/use_power(amount)
	if(get_charge())
		cell.use(amount)
		if(occupant)
			update_cell()
		return TRUE
	return FALSE

/obj/mecha/proc/give_power(amount)
	if(!isnull(get_charge()))
		cell.give(amount)
		if(occupant)
			update_cell()
		return TRUE
	return FALSE

/obj/mecha/proc/update_cell()
	if(cell)
		var/cellcharge = cell.charge/cell.maxcharge
		switch(cellcharge)
			if(0.75 to INFINITY)
				occupant.clear_alert("charge")
			if(0.5 to 0.75)
				occupant.throw_alert("charge", /atom/movable/screen/alert/mech_lowcell, 1)
			if(0.25 to 0.5)
				occupant.throw_alert("charge", /atom/movable/screen/alert/mech_lowcell, 2)
				if(power_warned)
					power_warned = FALSE
			if(0.01 to 0.25)
				occupant.throw_alert("charge", /atom/movable/screen/alert/mech_lowcell, 3)
				if(!power_warned)
					SEND_SOUND(occupant, sound(lowpowersound, volume = 50))
					power_warned = TRUE
			else
				occupant.throw_alert("charge", /atom/movable/screen/alert/mech_emptycell)
	else
		occupant.throw_alert("charge", /atom/movable/screen/alert/mech_nocell)

/obj/mecha/proc/reset_icon()
	if(initial_icon)
		icon_state = initial_icon
	else
		icon_state = reset_icon(icon_state)
	return icon_state

//////////////////////////////////////////
////////  MARK: Mecha global iterators
//////////////////////////////////////////

/obj/mecha/process()
	process_internal_damage()
	regulate_temp()
	give_air()
	update_huds()

/obj/mecha/proc/process_internal_damage()
	if(!internal_damage)
		return

	if(internal_damage & MECHA_INT_FIRE)
		if(!(internal_damage & MECHA_INT_TEMP_CONTROL) && prob(5))
			clearInternalDamage(MECHA_INT_FIRE)
		if(internal_tank)
			var/datum/gas_mixture/int_tank_air = internal_tank.return_obj_air()
			if(int_tank_air.return_pressure() > internal_tank.maximum_pressure && !(internal_damage & MECHA_INT_TANK_BREACH))
				setInternalDamage(MECHA_INT_TANK_BREACH)

			if(int_tank_air && int_tank_air.return_volume() > 0)
				int_tank_air.set_temperature(min(6000 + T0C, cabin_air.temperature() + rand(10, 15)))

			if(cabin_air && cabin_air.return_volume() > 0)
				cabin_air.set_temperature(min(6000 + T0C, cabin_air.temperature() + rand(10, 15)))
				if(cabin_air.temperature() > max_temperature / 2)
					take_damage(4 / round(max_temperature / cabin_air.temperature(), 0.1), BURN, 0, 0)

	if(internal_damage & MECHA_INT_TANK_BREACH) //remove some air from internal tank
		if(internal_tank)
			var/datum/gas_mixture/int_tank_air = internal_tank.return_obj_air()
			var/datum/gas_mixture/leaked_gas = int_tank_air.remove_ratio(0.10)
			var/turf/T = get_turf(src)
			if(T)
				T.blind_release_air(leaked_gas)
			else
				qdel(leaked_gas)

	if(internal_damage & MECHA_INT_SHORT_CIRCUIT)
		if(get_charge())
			spark_system.start()
			cell.charge -= min(20,cell.charge)
			cell.maxcharge -= min(20,cell.maxcharge)

/obj/mecha/proc/release_gas(datum/gas_mixture/environment, datum/gas_mixture/leaked_gas)
	// Any proc that wants MILLA to be synchronous should not sleep.
	SHOULD_NOT_SLEEP(TRUE)

	environment.merge(leaked_gas)

/obj/mecha/proc/regulate_temp()
	if(internal_damage & MECHA_INT_TEMP_CONTROL)
		return

	if(cabin_air && cabin_air.return_volume() > 0)
		var/delta = cabin_air.temperature() - T20C
		cabin_air.set_temperature(cabin_air.temperature() - max(-10, min(10, round(delta / 4, 0.1))))

/obj/mecha/proc/give_air()
	if(!internal_tank)
		return

	var/datum/gas_mixture/tank_air = internal_tank.return_obj_air()

	var/release_pressure = internal_tank_valve
	var/cabin_pressure = cabin_air.return_pressure()
	var/pressure_delta = min(release_pressure - cabin_pressure, (tank_air.return_pressure() - cabin_pressure)/2)
	var/transfer_moles = 0
	if(pressure_delta > 0) //cabin pressure lower than release pressure
		if(tank_air.temperature() > 0)
			transfer_moles = pressure_delta*cabin_air.return_volume() / (cabin_air.temperature() * R_IDEAL_GAS_EQUATION)
			var/datum/gas_mixture/removed = tank_air.remove(transfer_moles)
			cabin_air.merge(removed)
	else if(pressure_delta < 0) //cabin pressure higher than release pressure
		var/datum/gas_mixture/active_tank_air = return_obj_air()
		pressure_delta = cabin_pressure - release_pressure
		if(active_tank_air)
			pressure_delta = min(cabin_pressure - active_tank_air.return_pressure(), pressure_delta)
		if(pressure_delta > 0) //if location pressure is lower than cabin pressure
			transfer_moles = pressure_delta * cabin_air.return_volume() / (cabin_air.temperature() * R_IDEAL_GAS_EQUATION)
			var/datum/gas_mixture/removed = cabin_air.remove(transfer_moles)
			if(active_tank_air)
				active_tank_air.merge(removed)
			else
				var/turf/T = get_turf(src)
				if(T)
					T.blind_release_air(removed)
				else
					qdel(removed)

/obj/mecha/proc/update_huds()
	diag_hud_set_mechhealth()
	diag_hud_set_mechcell()
	diag_hud_set_mechstat()
	diag_hud_set_mechtracking()


/obj/mecha/speech_bubble(bubble_state = "", bubble_loc = src, list/bubble_recipients = list())
	var/image/I = image('icons/mob/talk.dmi', bubble_loc, bubble_state, FLY_LAYER)
	I.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(flick_overlay), I, bubble_recipients, 30)

/obj/mecha/update_remote_sight(mob/living/user)
	if(occupant_sight_flags)
		if(user == occupant)
			user.sight |= occupant_sight_flags

	..()

/obj/mecha/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!no_effect)
		if(selected)
			used_item = selected
		else if(!visual_effect_icon)
			visual_effect_icon = ATTACK_EFFECT_SMASH
			if(damtype == BURN)
				visual_effect_icon = ATTACK_EFFECT_MECHFIRE
			else if(damtype == TOX)
				visual_effect_icon = ATTACK_EFFECT_MECHTOXIN
	..()

/obj/mecha/obj_destruction()
	if(wreckage)
		var/mob/living/silicon/ai/AI
		if(is_ai(occupant))
			AI = occupant
			occupant = null
		var/obj/structure/mecha_wreckage/WR = new wreckage(loc, AI)
		WR.icon_state = "[reset_icon(loc, AI)]-broken"
		for(var/obj/item/mecha_parts/mecha_equipment/E in equipment)
			if(E.salvageable && prob(30))
				WR.crowbar_salvage += E
				E.detach(WR) //detaches from src into WR
				E.equip_ready = 1
			else
				E.detach(loc)
				qdel(E)
		if(cell)
			WR.crowbar_salvage += cell
			cell.forceMove(WR)
			cell.charge = rand(0, cell.charge)
			cell = null
		if(internal_tank)
			WR.crowbar_salvage += internal_tank
			internal_tank.forceMove(WR)
			internal_tank = null
	. = ..()

/obj/mecha/CtrlClick(mob/living/L)
	if(occupant != L || !istype(L))
		return ..()

	var/list/choices = list("Cancel / No Change" = mutable_appearance(icon = 'icons/mob/screen_gen.dmi', icon_state = "x"))
	var/list/choices_to_refs = list()

	for(var/obj/item/mecha_parts/mecha_equipment/MT in equipment)
		if(!MT.selectable || selected == MT)
			continue
		var/mutable_appearance/clean/MA = mutable_appearance(MT.icon, MT.icon_state, MT.layer)
		choices[MT.name] = MA
		choices_to_refs[MT.name] = MT

	var/choice = show_radial_menu(L, L, choices, radius = 48, custom_check = CALLBACK(src, PROC_REF(check_menu), L))
	if(!check_menu(L) || choice == "Cancel / No Change")
		return

	var/obj/item/mecha_parts/mecha_equipment/new_sel = LAZYACCESS(choices_to_refs, choice)
	if(istype(new_sel))
		selected = new_sel
		occupant_message("<span class='notice'>You switch to [selected].</span>")
		visible_message("[src] raises [selected]")
		send_byjax(occupant, "exosuit.browser", "eq_list", get_equipment_list())

/obj/mecha/proc/check_menu(mob/living/L)
	if(L != occupant || !istype(L))
		return FALSE
	if(L.incapacitated())
		return FALSE
	return TRUE

#undef OCCUPANT_LOGGING
