/obj/machinery/computer/robotics
	name = "robotics control console"
	desc = "Used to remotely lockdown or detonate linked Cyborgs."
	icon_keyboard = "tech_key"
	icon_screen = "robot"
	req_access = list(ACCESS_RD)
	circuit = /obj/item/circuitboard/robotics
	var/temp = null

	light_color = LIGHT_COLOR_PURPLE

	var/safety = 1
	STATIC_COOLDOWN_DECLARE(detonate_cooldown)

/obj/machinery/computer/robotics/attack_ai(mob/user as mob)
	return attack_hand(user)

/obj/machinery/computer/robotics/attack_hand(mob/user as mob)
	if(..())
		return
	if(stat & (NOPOWER|BROKEN))
		return
	ui_interact(user)

/obj/machinery/computer/robotics/proc/is_authenticated(mob/user)
	if(!istype(user))
		return FALSE
	if(user.can_admin_interact())
		return TRUE
	if(allowed(user))
		return TRUE
	return FALSE

/**
  * Does this borg show up in the console
  *
  * Returns TRUE if a robot will show up in the console
  * Returns FALSE if a robot will not show up in the console
  * Arguments:
  * * R - The [/mob/living/silicon/robot] to be checked
  */
/obj/machinery/computer/robotics/proc/console_shows(mob/living/silicon/robot/R)
	if(!istype(R))
		return FALSE
	if(isdrone(R))
		return FALSE
	if(R.scrambledcodes)
		return FALSE
	if(!atoms_share_level(get_turf(src), get_turf(R)))
		return FALSE
	return TRUE

/**
  * Check if a user can send a lockdown/detonate command to a specific borg
  *
  * Returns TRUE if a user can send the command (does not guarantee it will work)
  * Returns FALSE if a user cannot
  * Arguments:
  * * user - The [/mob] to be checked
  * * R - The [/mob/living/silicon/robot] to be checked
  * * telluserwhy - Bool of whether the user should be sent a to_chat message if they don't have access
  */
/obj/machinery/computer/robotics/proc/can_control(mob/user, mob/living/silicon/robot/R, telluserwhy = FALSE)
	if(!istype(user))
		return FALSE
	if(!console_shows(R))
		return FALSE
	if(is_ai(user))
		if(R.connected_ai != user)
			if(telluserwhy)
				to_chat(user, "<span class='warning'>AIs can only control cyborgs which are linked to them.</span>")
			return FALSE
	if(isrobot(user))
		if(R != user)
			if(telluserwhy)
				to_chat(user, "<span class='warning'>Cyborgs cannot control other cyborgs.</span>")
			return FALSE
	return TRUE

/// Checks if a user can detonate any cyborgs at all.
/obj/machinery/computer/robotics/proc/can_detonate_any(mob/user, telluserwhy = FALSE)
	if(ispulsedemon(user))
		if(telluserwhy)
			to_chat(user, "<span class='warning'>The console's authentication circuits reject your control!</span>")
		return FALSE
	return TRUE

/// Checks if a user can detonate a specific cyborg, does a can_control check first.
/obj/machinery/computer/robotics/proc/can_detonate(mob/user, mob/living/silicon/robot/R, telluserwhy = FALSE)
	if(!can_control(user, R, telluserwhy))
		return FALSE
	if(!can_detonate_any(user, telluserwhy))
		return FALSE
	return TRUE

/**
  * Check if the user is the right kind of entity to be able to hack borgs
  *
  * Returns TRUE if a user is a traitor AI, or aghost
  * Returns FALSE otherwise
  * Arguments:
  * * user - The [/mob] to be checked
  */
/obj/machinery/computer/robotics/proc/can_hack_any(mob/user)
	if(!istype(user))
		return FALSE
	if(user.can_admin_interact())
		return TRUE
	if(!is_ai(user))
		return FALSE
	return (user.mind.special_role && user.mind.is_original_mob(user))

/**
  * Check if the user is allowed to hack a specific borg
  *
  * Returns TRUE if a user can hack the specific cyborg
  * Returns FALSE if a user cannot
  * Arguments:
  * * user - The [/mob] to be checked
  * * R - The [/mob/living/silicon/robot] to be checked
  */
/obj/machinery/computer/robotics/proc/can_hack(mob/user, mob/living/silicon/robot/R)
	if(!can_hack_any(user))
		return FALSE
	if(!istype(R))
		return FALSE
	if(R.emagged)
		return FALSE
	if(R.connected_ai != user)
		return FALSE
	return TRUE

/obj/machinery/computer/robotics/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/computer/robotics/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RoboticsControlConsole", name)
		ui.open()

/obj/machinery/computer/robotics/ui_data(mob/user)
	var/list/data = list()
	data["auth"] = is_authenticated(user)
	data["can_hack"] = can_hack_any(user)
	data["cyborgs"] = list()
	data["safety"] = safety
	data["detonate_cooldown"] = round(COOLDOWN_TIMELEFT(src, detonate_cooldown) / 10)
	for(var/mob/living/silicon/robot/R in GLOB.mob_list)
		if(!console_shows(R))
			continue
		var/area/A = get_area(R)
		var/turf/T = get_turf(R)
		var/list/cyborg_data = list(
			name = R.name,
			uid = R.UID(),
			locked_down = R.lockcharge,
			locstring = "[A.name] ([T.x], [T.y])",
			status = R.stat,
			health = round(R.health * 100 / R.maxHealth, 0.1),
			charge = R.cell ? round(R.cell.percent()) : null,
			cell_capacity = R.cell ? R.cell.maxcharge : null,
			module = R.module ? R.module.name : "No Module Detected",
			synchronization = R.connected_ai,
			is_hacked =  R.connected_ai && R.emagged && can_hack_any(user),
			hackable = can_hack(user, R),
		)
		data["cyborgs"] += list(cyborg_data)
	data["show_lock_all"] = (data["auth"] && length(data["cyborgs"]) > 0 && ishuman(user))
	return data

/obj/machinery/computer/robotics/ui_act(action, params)
	if(..())
		return
	. = FALSE
	if(!is_authenticated(usr))
		to_chat(usr, "<span class='warning'>Access denied.</span>")
		return
	if(SSticker.current_state == GAME_STATE_FINISHED)
		to_chat(usr, "<span class='warning'>Access denied, borgs are no longer your station's property.</span>")
		return
	switch(action)
		if("arm") // Arms the muli-lock system
			if(issilicon(usr))
				to_chat(usr, "<span class='danger'>Access Denied (silicon detected)</span>")
				return
			safety = !safety
			to_chat(usr, "<span class='notice'>You [safety ? "disarm" : "arm"] the emergency lockdown system.</span>")
			. = TRUE
		if("masslock") // Locks down all accessible cyborgs if safety is disabled
			if(issilicon(usr))
				to_chat(usr, "<span class='danger'>Access Denied (silicon detected)</span>")
				return
			if(!can_detonate_any(usr, TRUE)) // Uses the same permissions as detonate.
				return
			if(safety)
				to_chat(usr, "<span class='danger'>Emergency lockdown aborted - safety active</span>")
				return
			message_admins("<span class='notice'>[key_name_admin(usr)] locked all cyborgs!</span>")
			log_game("\<span class='notice'>[key_name(usr)] locked all cyborgs!</span>")
			for(var/mob/living/silicon/robot/R in GLOB.mob_list)
				if(isdrone(R))
					continue
				// Ignore antagonistic cyborgs
				if(R.scrambledcodes)
					continue
				to_chat(R, "<span class='danger'>Emergency lockdown received.</span>")
				if(R.connected_ai)
					to_chat(R.connected_ai, "<br><br><span class='alert'>ALERT - Cyborg lockdown detected: [R.name]</span><br>")
				R.SetLockdown(!R.lockcharge)
			. = TRUE
		if("killbot") // destroys one specific cyborg
			if(!COOLDOWN_FINISHED(src, detonate_cooldown))
				to_chat(usr, "<span class='danger'>Detonation Safety Cooldown Active. Please Stand By!</span>")
				return
			var/mob/living/silicon/robot/R = locateUID(params["uid"])
			if(!can_detonate(usr, R, TRUE))
				return
			if(R.mind && R.mmi.syndiemmi && !R.emagged) // Emagging removes your syndie MMI protections.
				to_chat(R, "<span class='danger'>Detonation code received. Self destructing... HARDWARE_OVERRIDE_SYNDICATE: Detonation aborted. Connection to NT systems severed.</span>")
				R.UnlinkSelf()
				. = TRUE
				return
			var/turf/T = get_turf(R)
			message_admins("<span class='notice'>[key_name_admin(usr)] detonated [key_name_admin(R)] ([ADMIN_COORDJMP(T)])!</span>")
			log_game("\<span class='notice'>[key_name(usr)] detonated [key_name(R)]!</span>")
			to_chat(R, "<span class='danger'>Self-destruct command received.</span>")
			if(R.connected_ai)
				to_chat(R.connected_ai, "<br><br><span class='alert'>ALERT - Cyborg detonation detected: [R.name]</span><br>")
			R.self_destruct()
			COOLDOWN_START(src, detonate_cooldown, 60 SECONDS)
			. = TRUE
		if("stopbot") // lock or unlock the borg
			if(isrobot(usr))
				to_chat(usr, "<span class='danger'>Access Denied.</span>")
				return
			var/mob/living/silicon/robot/R = locateUID(params["uid"])
			if(!can_control(usr, R, TRUE))
				return
			message_admins("<span class='notice'>[ADMIN_LOOKUPFLW(usr)] [!R.lockcharge ? "locked down" : "released"] [ADMIN_LOOKUPFLW(R)]!</span>")
			log_game("[key_name(usr)] [!R.lockcharge ? "locked down" : "released"] [key_name(R)]!")
			R.SetLockdown(!R.lockcharge)
			to_chat(R, "[!R.lockcharge ? "<span class='notice'>Your lockdown has been lifted!" : "<span class='alert'>You have been locked down!"]</span>")
			if(R.connected_ai)
				to_chat(R.connected_ai, "[!R.lockcharge ? "<span class='notice'>NOTICE - Cyborg lockdown lifted</span>" : "<span class='alert'>ALERT - Cyborg lockdown detected</span>"]: <a href='byond://?src=[R.connected_ai.UID()];track=[html_encode(R.name)]'>[R.name]</a></span><br>")
			. = TRUE
		if("hackbot") // AIs hacking/emagging a borg
			var/mob/living/silicon/robot/R = locateUID(params["uid"])
			if(!can_hack(usr, R))
				return
			var/choice = alert(usr, "Really hack [R.name]? This cannot be undone.", "Do you want to hack this borg?", "Yes", "No")
			if(choice != "Yes")
				return
			log_game("[key_name(usr)] emagged [key_name(R)] using robotic console!")
			message_admins("<span class='notice'>[key_name_admin(usr)] emagged [key_name_admin(R)] using robotic console!</span>")
			R.emagged = TRUE
			R.module.emag_act(usr)
			R.module.module_type = "Malf"
			R.update_module_icon()
			R.module.rebuild_modules()
			to_chat(R, "<span class='notice'>Failsafe protocols overridden. New tools available.</span>")
			. = TRUE
