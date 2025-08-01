GLOBAL_LIST_EMPTY(message_servers)

/datum/data_pda_msg
	var/recipient = "Unspecified" //name of the person
	var/sender = "Unspecified" //name of the sender
	var/message = "Blank" //transferred message

/datum/data_pda_msg/New(param_rec = "", param_sender = "", param_message = "")

	if(param_rec)
		recipient = param_rec
	if(param_sender)
		sender = param_sender
	if(param_message)
		message = param_message

/datum/data_rc_msg
	var/rec_dpt = "Unspecified" //name of the person
	var/send_dpt = "Unspecified" //name of the sender
	var/message = "Blank" //transferred message
	var/stamp = "Unstamped"
	var/id_auth = "Unauthenticated"
	var/priority = "Normal"

/datum/data_rc_msg/New(param_rec = "", param_sender = "", param_message = "", param_stamp = "", param_id_auth = "", param_priority)
	if(param_rec)
		rec_dpt = param_rec
	if(param_sender)
		send_dpt = param_sender
	if(param_message)
		message = param_message
	if(param_stamp)
		stamp = param_stamp
	if(param_id_auth)
		id_auth = param_id_auth
	if(param_priority)
		switch(param_priority)
			if(1)
				priority = "Normal"
			if(2)
				priority = "High"
			if(3)
				priority = "Extreme"
			else
				priority = "Undetermined"

/obj/machinery/message_server
	name = "Messaging Server"
	desc = "A machine that processes and routes PDA and request console messages."
	icon = 'icons/obj/machines/telecomms.dmi'
	icon_state = "message_server"
	density = TRUE
	anchored = TRUE
	idle_power_consumption = 10
	active_power_consumption = 100

	var/list/datum/data_pda_msg/pda_msgs = list()
	var/list/datum/data_rc_msg/rc_msgs = list()
	var/active = TRUE
	var/decryptkey = "password"

/obj/machinery/message_server/Initialize(mapload)
	. = ..()
	GLOB.message_servers += src
	decryptkey = GenerateKey()
	send_pda_message("System Administrator", "system", "This is an automated message. The messaging system is functioning correctly.")

/obj/machinery/message_server/Destroy()
	GLOB.message_servers -= src
	QDEL_LIST_CONTENTS(pda_msgs)
	QDEL_LIST_CONTENTS(rc_msgs)
	return ..()

/obj/machinery/message_server/process()
	if(active && (stat & (BROKEN | NOPOWER)))
		active = FALSE
		update_icon(UPDATE_ICON_STATE)
		return
	if(prob(3))
		playsound(loc, "computer_ambience", 10, TRUE, ignore_walls = FALSE)

/obj/machinery/message_server/proc/send_pda_message(recipient = "", sender = "", message = "")
	pda_msgs += new/datum/data_pda_msg(recipient,sender,message)

/obj/machinery/message_server/proc/send_rc_message(recipient = "", sender = "", message = list(), stamp = "Not stamped", id_auth = "Not verified", priority = RQ_NORMALPRIORITY)
	if(!islist(message))
		message = list(message)
	rc_msgs += new/datum/data_rc_msg(recipient,sender,message,stamp,id_auth)
	for(var/C in GLOB.allRequestConsoles)
		var/obj/machinery/requests_console/RC = C
		if(ckey(RC.department) == ckey(recipient))
			var/title
			switch(priority)
				if(RQ_HIGHPRIORITY)
					title = "PRIORITY Alert from [sender]"
				else
					title = "Message from [sender]"
			RC.createMessage(sender, title, message, priority, verified = id_auth, stamped = stamp)

/obj/machinery/message_server/attack_hand(user as mob)
	to_chat(user, "You toggle PDA message passing from [active ? "On" : "Off"] to [active ? "Off" : "On"]")
	active = !active
	update_icon(UPDATE_ICON_STATE)

/obj/machinery/message_server/update_icon_state()
	icon_state = "[initial(icon_state)][panel_open ? "_o" : null][active ? null : "_off"]"

/obj/machinery/blackbox_recorder
	icon_state = "blackbox"
	name = "Blackbox Recorder"
	density = TRUE
	anchored = TRUE
	idle_power_consumption = 10
	active_power_consumption = 100
