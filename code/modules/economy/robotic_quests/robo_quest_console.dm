#define NO_SUCCESS 0
#define CORRECT_MECHA 1
#define SOME_CORRECT_MODULES 2
#define ALL_CORRECT_MODULES 3

/obj/machinery/computer/roboquest
	name = "RoboQuest console"
	icon_screen = "rdcomp"
	icon_keyboard = "rd_key"
	light_color = LIGHT_COLOR_FADEDPURPLE
	var/canSend = FALSE
	var/canCheck = FALSE
	var/success
	var/checkMessage = ""
	var/obj/item/card/id/currentID
	var/obj/machinery/roboquest_pad/pad
	var/difficult


/obj/machinery/computer/roboquest/Destroy()
	for(var/obj/item/I in contents)
		I.forceMove(get_turf(src))
	pad = null
	currentID = null
	. = ..()

/obj/machinery/computer/roboquest/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/card/id))
		currentID = O
		user.drop_item_ground(O)
		O.forceMove(src)
	if(istype(O, /obj/item/multitool))
		var/obj/item/multitool/M = O
		if(M.buffer)
			add_fingerprint(user)
			if(istype(M.buffer, /obj/machinery/roboquest_pad))
				pad = M.buffer
				if(pad.console)
					pad.console.pad = null
				pad.console = src
				canCheck = TRUE
				M.buffer = null

/obj/machinery/computer/roboquest/proc/check_pad()
	var/obj/mecha/M
	var/needed_mech = currentID.robo_bounty.choosen_mech
	var/list/needed_modules = currentID.robo_bounty.choosen_modules
	var/amount = 0
	if(locate(/obj/mecha) in get_turf(pad))
		M = (locate(/obj/mecha) in get_turf(pad))
		if(M.type == needed_mech)
			for(var/i in (needed_modules))
				for(var/obj/item/mecha_parts/mecha_equipment/weapon in M.equipment)
					if(i == weapon.type)
						amount++
			if(amount == currentID.robo_bounty.modules_amount)
				success = ALL_CORRECT_MODULES
				canSend = TRUE
				return	amount
			if(amount == 0)
				success = CORRECT_MECHA
				canSend = TRUE
				return amount
			success = SOME_CORRECT_MODULES
			canSend = TRUE
			return	amount
	success = NO_SUCCESS
	canSend = FALSE

/obj/machinery/computer/roboquest/proc/clear_checkMessage()
	checkMessage = ""

/obj/machinery/computer/roboquest/attack_hand(mob/user)
	if(..())
		return TRUE
	ui_interact(user)

/obj/machinery/computer/roboquest/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = TRUE, datum/tgui/master_ui = null, datum/ui_state/state = GLOB.default_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "RoboQuest", name, 800, 475, master_ui, state)
		ui.open()

/obj/machinery/computer/roboquest/ui_data(mob/user)
	var/list/data = list()
	if(istype(currentID))
		data["hasID"] = TRUE
		data["name"] = currentID.registered_name
		if(currentID.robo_bounty)
			data["questInfo"] = currentID.robo_bounty.questinfo
			data["hasTask"] = TRUE
		else
			data["questInfo"] = "None"
			data["hasTask"] = FALSE
	else
		data["hasID"] = FALSE
		data["name"] = "None"
		data["questInfo"] = "None"
		data["hasTask"] = FALSE
	data["canCheck"] = canCheck
	data["canSend"] = canSend
	data["checkMessage"] = checkMessage
	return data

/obj/machinery/computer/roboquest/ui_act(action, list/params)
	switch(action)
		if("RemoveID")
			currentID.forceMove(get_turf(src))
			currentID = null
		if("GetTask")
			difficulty = tgui_input_list(usr, "Select event type.", "Select", list("easy", "medium", "hard"))
			if(!difficulty)
				return
			pick_mecha(difficulty)
		if("Check")
			if(!pad)
				to_chat(usr, span_userdanger("There is no linked robotic quantum pad!"))
			else
				var/amount = check_pad()
				switch(success)
					if(NO_SUCCESS)
						checkMessage = span_userdanger("Мех отсутствует или не соответствует заказу")
					if(CORRECT_MECHA)
						checkMessage = span_notice("Мех соответствует заказу, но не имеет заказанных модулей. Награда Будет сильно урезана")
					if(SOME_CORRECT_MODULES)
						checkMessage = span_notice("Мех соответствует заказу, но имеет лишь [amount]/[currentID.robo_bounty.modules_amount] модулей. Награда будет слегка урезана.")
					if(ALL_CORRECT_MODULES)
						checkMessage = span_notice("Мех и модули полностью соответствуют заказу. Награда будет максимальной.")
				addtimer(CALLBACK(src, PROC_REF(clear_checkMessage)), 15 SECONDS)
		if("SendMech")
			check_pad()
			to_chat(usr, span_notice("Вы отправили меха с оценкой успеха [success] из трех"))

/obj/machinery/computer/roboquest/proc/pick_mecha(difficulty)
	currentID.robo_bounty = new /datum/roboquest(difficulty)

//roboquest pad

/obj/machinery/roboquest_pad
	name = "RoboQuest pad"
	icon = 'icons/obj/machines/recycling.dmi'
	icon_state = "separator-A1" //ультра WIP
	var/obj/machinery/computer/roboquest/console

/obj/machinery/roboquest_pad/Destroy()
	console.pad = null
	console.canSend = FALSE
	console = null
	. = ..()

/obj/machinery/roboquest_pad/New()
	RegisterSignal(src, COMSIG_MOVABLE_UNCROSSED, PROC_REF(ismechgone))
	. = ..()

/obj/machinery/roboquest_pad/proc/ismechgone(datum/source, atom/movable/exiting)
	if(ismecha(exiting) && console)
		console.canSend = FALSE

/obj/machinery/roboquest_pad/multitool_act(mob/living/user, obj/item/I)
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = I.tool_volume))
		return
	if(!I.multitool_check_buffer(user))
		return
	var/obj/item/multitool/M = I
	M.set_multitool_buffer(user, src)


#undef NO_SUCCESS
#undef CORRECT_MECHA
#undef SOME_CORRECT_MODULES
#undef ALL_CORRECT_MODULES
