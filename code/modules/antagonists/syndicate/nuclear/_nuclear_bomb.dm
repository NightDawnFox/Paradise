/// Whether the station has been nuked itself. TRUE only if the station was actually hit by the nuke, otherwise FALSE
GLOBAL_VAR_INIT(station_was_nuked, FALSE)
/// The source of the last nuke that went off
GLOBAL_VAR(station_nuke_source)
/// Used for pinpointers
GLOBAL_VAR(bomb_set)

/obj/machinery/nuclearbomb
	name = "nuclear fission explosive"
	desc = "Вам, вероятно, не следует находиться рядом с ней."
	icon = 'icons/obj/machines/nuke.dmi'
	icon_state = "nuclearbomb_base"
	density = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	use_power = NO_POWER_USE

	/// What the timer is set to, in seconds
	var/timer_set = 90
	/// What the min value the timer can be, in seconds
	var/minimum_timer_set = 90
	/// What the max value the timer can be, in seconds
	var/maximum_timer_set = 3600
	/// The current input of the numpad on the bomb
	var/numeric_input = ""
	/// What mode the UI currently is in
	var/ui_mode = NUKEUI_AWAIT_DISK
	/// Whether we're currently timing an explosive and counting down
	var/timing = FALSE
	/// Whether the timer has elapsed and we're currently exploding
	var/exploding = FALSE
	/// Whether we've actually fully exploded
	var/exploded = FALSE
	/// world time tracker for when we're going to explode
	var/detonation_timer = null
	/// The code we need to detonate this nuke. Starts as "admin", purposefully un-enterable
	var/r_code = NUKE_CODE_UNSET
	/// If TRUE, the correct code has been entered and we can start the nuke
	var/yes_code = FALSE
	/// Whether the nuke safety is on, can't explode if it is
	var/safety = TRUE
	/// The nuke disk currently inserted into the nuke
	var/obj/item/disk/nuclear/auth
	/// The alert level that was set before the nuke started, so we can revert to the correct level after
	var/previous_level = ""
	/// The nuke core within the nuke, created in initialize
	var/obj/item/nuke_core/plutonium/core = null
	/// The current state of deconstructing / opening up the nuke to access the core
	var/deconstruction_state = NUKESTATE_INTACT
	/// Overlay - flashing lights over the nuke
	var/lights = ""
	/// Overlay - shows the interior of the nuke
	var/interior = ""
	/// if TRUE, this nuke is actually a real nuke, and not a prank or toy
	var/proper_bomb = TRUE //Please
	/// A reference to the countdown that goes up over the nuke
	var/obj/effect/countdown/nuclearbomb/countdown
	/// Cinematic used in explosion
	var/cinematic_type = STATION_NUKE

/obj/machinery/nuclearbomb/syndicate
	cinematic_type = SYNDICATE_NUKE

/obj/machinery/nuclearbomb/selfdestruct
	name = "station self-destruct terminal"
	desc = "На случай крайне чрезвычайных ситуаций."
	icon = 'icons/obj/machines/nuke_terminal.dmi'
	icon_state = "nuclearbomb_base"
	anchored = TRUE //stops it being moved

/obj/machinery/nuclearbomb/selfdestruct/set_anchor()
	return

/obj/machinery/nuclearbomb/get_ru_names()
	return list(
		NOMINATIVE = "ядерная боеголовка",
		GENITIVE = "ядерной боеголовки",
		DATIVE = "ядерной боеголовке",
		ACCUSATIVE = "ядерную боеголовку",
		INSTRUMENTAL = "ядерной боеголовкой",
		PREPOSITIONAL = "ядерной боеголовке",
	)

/obj/machinery/nuclearbomb/Initialize(mapload)
	. = ..()
	previous_level = SSsecurity_level.get_current_level_as_text()
	countdown = new(src)
	core = new /obj/item/nuke_core/plutonium(src)
	STOP_PROCESSING(SSobj, core)
	update_appearance()
	GLOB.poi_list |= src
	AddElement(/datum/element/high_value_item)
	//ADD_TRAIT(core, TRAIT_BLOCK_RADIATION, UNIQUE_TRAIT_SOURCE(src)) //Let us not irradiate the vault by default.
	update_icon(UPDATE_OVERLAYS)

/obj/machinery/nuclearbomb/Destroy()
	safety = FALSE
	if(!exploding)
		// If we're not exploding, set the alert level back to normal
		toggle_nuke_safety()
	QDEL_NULL(countdown)
	QDEL_NULL(core)
	GLOB.poi_list.Remove(src)
	return ..()

/obj/machinery/nuclearbomb/examine(mob/user)
	. = ..()
	if(check_rights(R_ADMIN, FALSE))
		. += span_notice("Код от боеголовки [GLOB.nuke_codes[type]].")

	switch(deconstruction_state)
		if(NUKESTATE_UNSCREWED)
			. += span_notice("Передняя пластина была откручена и её можно <b>снять монтировкой</b>.")
		if(NUKESTATE_PANEL_REMOVED)
			. += span_notice("Внутренняя обшивка не защищена и может быть <b>разварена</b>.")
		if(NUKESTATE_WELDED)
			. += span_notice("Внутренняя обшивка была разварена и её можно <b>снять монтировкой</b>.")
		if(NUKESTATE_CORE_EXPOSED)
			. += span_danger("внутреннее содержимое открыто, и внутри находится [core.declent_ru(NOMINATIVE)]!")
			. += span_notice("Поврежденную внутреннюю обшивку можно заменить с помощью <b>листов металла</b>.")
		if(NUKESTATE_CORE_REMOVED)
			. += span_notice("внутреннее содержимое открыто, однако внутри ничего нет.")
		if(NUKESTATE_INTACT)
			. += span_notice("Передняя пластина закреплена.")

	switch(get_nuke_state())
		if(NUKE_OFF_LOCKED)
			. += span_notice("Боеголовка ждёт ввода кодов запуска.")
		if(NUKE_OFF_UNLOCKED)
			. += span_notice("Боеголовка в полной боевой готовности и готова к активации.")
		if(NUKE_ON_TIMING)
			. += span_danger("До взрыва боеголовки осталось [get_time_left()] секунд[DECL_SEC_MIN(get_time_left())].")
		if(NUKE_ON_EXPLODING)
			. += span_bolddanger("Боеголовка в процессе взрыва. Возможно вам следует обдумать все ваши последние действия.")

/// Checks if the disk inserted is a real nuke disk or not.
/obj/machinery/nuclearbomb/proc/disk_check(obj/item/disk/nuclear/inserted_disk)
	if(inserted_disk.fake)
		atom_say("Ошибка аутенфикации: диск не распознан.")
		return FALSE

	return TRUE

/obj/machinery/nuclearbomb/attackby(obj/item/weapon, mob/user, list/modifiers, list/attack_modifiers)
	if(istype(weapon, /obj/item/disk/nuclear))
		if(!disk_check(weapon))
			return TRUE
		if(!user.drop_transfer_item_to_loc(weapon, src))
			return TRUE
		auth = weapon
		update_ui_mode()
		playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, FALSE)
		add_fingerprint(user)
		return TRUE

	switch(deconstruction_state)
		if(NUKESTATE_INTACT)
			if(istype(weapon, /obj/item/screwdriver/nuke))
				balloon_alert(user, "снятие винтов...")
				if(weapon.use_tool(src, user, 6 SECONDS, volume = 100))
					deconstruction_state = NUKESTATE_UNSCREWED
					balloon_alert(user, "винты сняты!")
					update_appearance()
				return TRUE

		if(NUKESTATE_PANEL_REMOVED)
			if(weapon.tool_behaviour == TOOL_WELDER)
				if(!weapon.tool_start_check(user, amount = 1))
					return TRUE
				balloon_alert(user, "разваривание обшивки...")
				if(weapon.use_tool(src, user, 8 SECONDS, volume = 100))
					balloon_alert(user, "обишвка разварена!")
					deconstruction_state = NUKESTATE_WELDED
					update_appearance()
				return TRUE

		if(NUKESTATE_CORE_EXPOSED)
			if(istype(weapon, /obj/item/nuke_core_container))
				var/obj/item/nuke_core_container/core_box = weapon
				balloon_alert(user, "помещение ядра в контейнер...")
				if(do_after(user, 5 SECONDS, target = src))
					if(core_box.load(core, user))
						balloon_alert(user, "ядро помещено в контейнер!")
						deconstruction_state = NUKESTATE_CORE_REMOVED
						update_appearance()
						core = null
					else
						balloon_alert(user, "не вышло!")
				return TRUE
			if(istype(weapon, /obj/item/stack/sheet/metal))
				if(!weapon.tool_start_check(user, amount = 20))
					return TRUE

				balloon_alert(user, "восстановление обшивки...")
				if(weapon.use_tool(src, user, 10 SECONDS, amount = 20))
					balloon_alert(user, "обишвка восстановлена!")
					deconstruction_state = NUKESTATE_PANEL_REMOVED
					STOP_PROCESSING(SSobj, core)
					update_appearance()
				return TRUE

	return ..()

/obj/machinery/nuclearbomb/crowbar_act(mob/user, obj/item/tool)
	switch(deconstruction_state)
		if(NUKESTATE_UNSCREWED)
			balloon_alert(user, "снятие панели...")
			if(tool.use_tool(src, user, 30, volume=100))
				balloon_alert(user, "панель снята!")
				deconstruction_state = NUKESTATE_PANEL_REMOVED
				update_appearance()
			return TRUE
		if(NUKESTATE_WELDED)
			balloon_alert(user, "снятие обшивки...")
			if(tool.use_tool(src, user, 30, volume=100))
				balloon_alert(user, "обшивка снята!")
				deconstruction_state = NUKESTATE_CORE_EXPOSED
				update_appearance()
				START_PROCESSING(SSobj, core)
			return TRUE
	return FALSE

/obj/machinery/nuclearbomb/ui_state(mob/user)
	if(HAS_TRAIT(user, TRAIT_CAN_USE_NUKE))
		return GLOB.physical_state

	return ..()

/// Gets the current state of the nuke.
/obj/machinery/nuclearbomb/proc/get_nuke_state()
	if(exploding)
		return NUKE_ON_EXPLODING
	if(timing)
		return NUKE_ON_TIMING
	if(safety)
		return NUKE_OFF_LOCKED
	else
		return NUKE_OFF_UNLOCKED

/obj/machinery/nuclearbomb/update_icon_state()
	if(deconstruction_state != NUKESTATE_INTACT)
		icon_state = "nuclearbomb_base"
		return ..()

	switch(get_nuke_state())
		if(NUKE_OFF_LOCKED, NUKE_OFF_UNLOCKED)
			icon_state = "nuclearbomb_base"
		if(NUKE_ON_TIMING)
			icon_state = "nuclearbomb_timing"
		if(NUKE_ON_EXPLODING)
			icon_state = "nuclearbomb_exploding"

	return ..()

/obj/machinery/nuclearbomb/update_overlays()
	. = ..()

	if(lights)
		cut_overlay(lights)
	cut_overlay(interior)

	switch(deconstruction_state)
		if(NUKESTATE_UNSCREWED)
			interior = "panel-unscrewed"
		if(NUKESTATE_PANEL_REMOVED)
			interior = "panel-removed"
		if(NUKESTATE_WELDED)
			interior = "plate-welded"
		if(NUKESTATE_CORE_EXPOSED)
			interior = "plate-removed"
		if(NUKESTATE_CORE_REMOVED)
			interior = "core-removed"
		if(NUKESTATE_INTACT)
			interior = null

	switch(get_nuke_state())
		if(NUKE_OFF_LOCKED)
			lights = null
		if(NUKE_OFF_UNLOCKED)
			lights = "lights-safety"
		if(NUKE_ON_TIMING)
			lights = "lights-timing"
		if(NUKE_ON_EXPLODING)
			lights = "lights-exploding"

	add_overlay(lights)
	add_overlay(interior)

/obj/machinery/nuclearbomb/process()
	if(!timing || exploding)
		return

	if(detonation_timer < world.time)
		explode()
		return

	var/volume = (get_time_left() <= 20 ? 30 : 5)
	playsound(loc, 'sound/items/timer.ogg', volume, FALSE)

/// Changes what mode the UI is depending on the state of the nuke.
/obj/machinery/nuclearbomb/proc/update_ui_mode()
	if(exploded)
		ui_mode = NUKEUI_EXPLODED
		return

	if(!auth)
		ui_mode = NUKEUI_AWAIT_DISK
		return

	if(timing)
		ui_mode = NUKEUI_TIMING
		return

	if(!safety)
		ui_mode = NUKEUI_AWAIT_ARM
		return

	if(!yes_code)
		ui_mode = NUKEUI_AWAIT_CODE
		return

	ui_mode = NUKEUI_AWAIT_TIMER

/obj/machinery/nuclearbomb/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NuclearBomb", name)
		ui.open()

/obj/machinery/nuclearbomb/ui_data(mob/user)
	var/list/data = list()
	data["disk_present"] = auth

	var/hidden_code = (ui_mode == NUKEUI_AWAIT_CODE && numeric_input != "ERROR")

	var/current_code = ""
	if(hidden_code)
		while(length(current_code) < length(numeric_input))
			current_code = "[current_code]*"

	else
		current_code = numeric_input
	while(length(current_code) < 5)
		current_code = "[current_code]-"

	var/first_status
	var/second_status
	switch(ui_mode)
		if(NUKEUI_AWAIT_DISK)
			first_status = "DEVICE LOCKED"
			if(timing)
				second_status = "TIME: [get_time_left()]"
			else
				second_status = "AWAIT DISK"
		if(NUKEUI_AWAIT_CODE)
			first_status = "INPUT CODE"
			second_status = "CODE: [current_code]"
		if(NUKEUI_AWAIT_TIMER)
			first_status = "INPUT TIME"
			second_status = "TIME: [current_code]"
		if(NUKEUI_AWAIT_ARM)
			first_status = "DEVICE READY"
			second_status = "TIME: [get_time_left()]"
		if(NUKEUI_TIMING)
			first_status = "DEVICE ARMED"
			second_status = "TIME: [get_time_left()]"
		if(NUKEUI_EXPLODED)
			first_status = "DEVICE DEPLOYED"
			second_status = "THANK YOU"

	data["status1"] = first_status
	data["status2"] = second_status
	data["anchored"] = anchored

	return data

/obj/machinery/nuclearbomb/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	playsound(src, SFX_TERMINAL_TYPE, 20, FALSE)
	switch(action)
		if("eject_disk")
			if(auth && auth.loc == src)
				playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, FALSE)
				playsound(src, 'sound/items/timer.ogg', 50, FALSE)
				auth.forceMove(get_turf(src))
				auth = null
				. = TRUE
			else
				var/obj/item/item = usr.is_type_in_hands(/obj/item/disk/nuclear)
				if(item && disk_check(item) && usr.drop_transfer_item_to_loc(item, src))
					playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, FALSE)
					playsound(src, 'sound/items/timer.ogg', 50, FALSE)
					auth = item
					. = TRUE
			update_ui_mode()
		if("keypad")
			if(auth)
				var/digit = params["digit"]
				switch(digit)
					if("C")
						if(auth && ui_mode == NUKEUI_AWAIT_ARM)
							toggle_nuke_safety()
							yes_code = FALSE
							playsound(src, 'sound/machines/nuke/confirm_beep.ogg', 50, FALSE)
							update_ui_mode()
						else
							playsound(src, 'sound/items/timer.ogg', 50, FALSE)
						numeric_input = ""
						. = TRUE
					if("E")
						switch(ui_mode)
							if(NUKEUI_AWAIT_CODE)
								if(numeric_input == r_code)
									numeric_input = ""
									yes_code = TRUE
									playsound(src, 'sound/items/timer.ogg', 50, FALSE)
									. = TRUE
								else
									playsound(src, 'sound/machines/nuke/angry_beep.ogg', 50, FALSE)
									numeric_input = "ERROR"
							if(NUKEUI_AWAIT_TIMER)
								var/number_value = text2num(numeric_input)
								if(number_value)
									timer_set = clamp(number_value, minimum_timer_set, maximum_timer_set)
									playsound(src, 'sound/items/timer.ogg', 50, FALSE)
									toggle_nuke_safety()
									. = TRUE
							else
								playsound(src, 'sound/machines/nuke/angry_beep.ogg', 50, FALSE)
						update_ui_mode()
					if("0", "1", "2", "3", "4", "5", "6", "7", "8", "9")
						if(numeric_input != "ERROR")
							numeric_input += digit
							if(length(numeric_input) > 5)
								numeric_input = "ERROR"
							else
								playsound(src,  'sound/items/timer.ogg', 50, FALSE)
							. = TRUE
			else
				playsound(src, 'sound/machines/nuke/angry_beep.ogg', 50, FALSE)
		if("arm")
			if(auth && yes_code && !safety && !exploded)
				playsound(src, 'sound/items/timer.ogg', 50, FALSE)
				toggle_nuke_armed()
				update_ui_mode()
				. = TRUE
			else
				playsound(src, 'sound/machines/nuke/angry_beep.ogg', 50, FALSE)
		if("anchor")
			if(auth && yes_code)
				playsound(src,  'sound/items/timer.ogg', 50, FALSE)
				set_anchor(usr)
			else
				playsound(src, 'sound/machines/nuke/angry_beep.ogg', 50, FALSE)

/// Anchors the nuke, duh. Can only be done if the disk is inside.
/obj/machinery/nuclearbomb/proc/set_anchor(mob/anchorer)
	if(isinspace() && !anchored)
		if(anchorer)
			to_chat(anchorer, span_warning("Тут нельзя закрепиться!"))
		return

	set_anchored(!anchored)

/// Toggles the safety of the nuke.
/obj/machinery/nuclearbomb/proc/toggle_nuke_safety()
	safety = !safety

	// We're safe now, so stop any ongoing timers
	if(safety)
		if(timing)
			timing = FALSE
			disarm_nuke()

		detonation_timer = null
		countdown.stop()
	update_appearance(UPDATE_OVERLAYS) //only the lights overlay are affected by safety

/// Arms the nuke, or disarms it if it's already active.
/obj/machinery/nuclearbomb/proc/toggle_nuke_armed()
	if(safety)
		to_chat(usr, span_danger("Предохранитель всё еще запущен."))
		return

	timing = !timing
	if(timing)
		arm_nuke(usr)
	else
		disarm_nuke(usr)

/// Arms the nuke, making it active and triggering all pinpointers to start counting down (+delta alert)
/obj/machinery/nuclearbomb/proc/arm_nuke(mob/armer)
	var/turf/our_turf = get_turf(src)
	message_admins("\The [src] was armed at [ADMIN_VERBOSEJMP(our_turf)] by [armer ? ADMIN_LOOKUPFLW(armer) : "an unknown user"].")
	log_game("armed \the [src].")

	previous_level = SSsecurity_level.get_current_level_as_number()
	detonation_timer = world.time + (timer_set * 10)
	GLOB.bomb_set = TRUE

	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_NUKE_DEVICE_ARMED, src)
	countdown.start()
	SSsecurity_level.set_level(SEC_LEVEL_DELTA)
	notify_ghosts(
		"A nuclear device has been armed in [get_area_name(src)]!",
		source = src,
		action = NOTIFY_FOLLOW,
	)
	SSshuttle?.add_hostile_environment(src)
	update_appearance()

/// Disarms the nuke, reverting all pinpointers and the security level
/obj/machinery/nuclearbomb/proc/disarm_nuke(mob/disarmer)
	var/turf/our_turf = get_turf(src)
	message_admins("\The [src] at [ADMIN_VERBOSEJMP(our_turf)] was disarmed by [disarmer ? ADMIN_LOOKUPFLW(disarmer) : "an unknown user"].")
	if(disarmer)
		log_game("[disarmer] disarmed [src].")

	detonation_timer = null
	SSsecurity_level.set_level(previous_level)

	GLOB.bomb_set = FALSE
	SSshuttle?.remove_hostile_environment(src)

	countdown.stop()
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_NUKE_DEVICE_DISARMED, src)
	update_appearance()

/// If the nuke is active, gets how much time is left until it detonates, in seconds.
/// If the nuke is not active, gets how much time the nuke is set for, in seconds.
/obj/machinery/nuclearbomb/proc/get_time_left()
	if(timing)
		. = round(max(0, detonation_timer - world.time) / 10, 1)
	else
		. = timer_set

/obj/machinery/nuclearbomb/blob_act(obj/structure/blob/attacking_blob)
	if(exploding)
		return
	if(timing)	//boom
		INVOKE_ASYNC(src, PROC_REF(explode))
		return
	//if no boom then we need to let the blob capture our nuke
	var/turf/T = get_turf(src)
	if(!T)
		return
	if(locate(/obj/structure/blob) in T)
		return
	var/obj/structure/blob/special/captured_nuke/nuke = new(T, src)
	nuke.overmind = attacking_blob.overmind
	nuke.update_blob()

/obj/machinery/nuclearbomb/zap_act(power, zap_flags)
	. = ..()
	if(zap_flags & ZAP_MACHINE_EXPLOSIVE)
		qdel(src)//like the singulo, tesla deletes it. stops it from exploding over and over

/**
 * Begins the process of exploding the nuke.
 * [proc/explode] -> [proc/actually_explode] -> [proc/really_actually_explode])
 *
 * Goes through a few timers and plays a cinematic.
 */
/obj/machinery/nuclearbomb/proc/explode()
	if(safety)
		timing = FALSE
		return FALSE

	exploding = TRUE
	yes_code = FALSE
	safety = TRUE
	update_appearance()
	sound_to_playing_players(src,'sound/machines/alarm.ogg', 50, FALSE, 5)

	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_NUKE_DEVICE_DETONATING, src)

	if(SSticker?.mode)
		SSticker.mode.explosion_in_progress = 1
	addtimer(CALLBACK(src, PROC_REF(actually_explode)), 10 SECONDS)
	return TRUE

/obj/machinery/nuclearbomb/proc/actually_explode()
	GLOB.enter_allowed = 0

	var/off_station = 0
	var/turf/bomb_location = get_turf(src)
	if(bomb_location && is_station_level(bomb_location.z))
		if(isspacearea(get_area(bomb_location)))
			off_station = 1
	else
		off_station = 2

	if(SSticker)
		var/obj/docking_port/mobile/syndie_shuttle = SSshuttle.getShuttle("syndicate")
		if(syndie_shuttle)
			SSticker.mode.syndies_didnt_escape = is_station_level(syndie_shuttle.z)
		SSticker.mode.nuke_off_station = off_station
		SSticker.station_explosion_cinematic(off_station, cinematic_type)
		if(SSticker.mode)
			SSticker.mode.explosion_in_progress = 0
			if(off_station == 1)
				to_chat(world, "<b>A nuclear device was set off, but the explosion was out of reach of the station!</b>")
			else if(off_station == 2)
				to_chat(world, "<b>A nuclear device was set off, but the device was not on the station!</b>")
			else
				to_chat(world, "<b>The station was destroyed by the nuclear blast!</b>")

			SSticker.mode.station_was_nuked = (off_station < 2)	//offstation==1 is a draw. the station becomes irradiated and needs to be evacuated.
															//kinda shit but I couldn't  get permission to do what I wanted to do.

			if(!SSticker.mode.check_finished())//If the mode does not deal with the nuke going off so just reboot because everyone is stuck as is
				SSticker.reboot_helper("Station destroyed by Nuclear Device.", "nuke - unhandled ending")
				return
	return

//==========DAT FUKKEN DISK===============
/obj/item/disk/nuclear
	name = "nuclear authentication disk"
	desc = "Better keep this safe."
	icon_state = "nucleardisk"
	max_integrity = 250
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 30, BIO = 0, FIRE = 100, ACID = 100)
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	/// Whether we're a real nuke disk or not.
	var/fake = FALSE

/obj/item/disk/nuclear/unrestricted
	desc = "Seems to have been stripped of its safeties, you better not lose it."

/obj/item/disk/nuclear/New()
	..()
	START_PROCESSING(SSobj, src)
	GLOB.poi_list |= src

/obj/item/disk/nuclear/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/high_value_item)

/obj/item/disk/nuclear/process()
	if(!check_disk_loc())
		var/holder = get(src, /mob)
		var/turf/diskturf = get_turf(src)
		if(holder)
			add_game_logs("lost [src] in [COORD(diskturf)]!", holder)
			to_chat(holder, span_danger("You can't help but feel that you just lost something back there..."))
		add_game_logs("[fingerprintslast] who touched the lost [src] in [COORD(diskturf)].")
		qdel(src)

//station disk is allowed on z1, escape shuttle/pods, CC, and syndicate shuttles/base, reset otherwise
/obj/item/disk/nuclear/proc/check_disk_loc()
	var/turf/T = get_turf(src)
	var/area/A = get_area(src)
	if(is_station_level(T.z))
		return TRUE
	if(A.nad_allowed)
		return TRUE
	return FALSE

/obj/item/disk/nuclear/unrestricted/check_disk_loc()
	return TRUE

/obj/item/disk/nuclear/Destroy(force)
	var/turf/diskturf = get_turf(src)

	if(force)
		message_admins("[src] has been !!force deleted!! in [ADMIN_COORDJMP(diskturf)].")
		add_game_logs("[src] has been !!force deleted!! in [COORD(diskturf)].")
		GLOB.poi_list.Remove(src)
		STOP_PROCESSING(SSobj, src)
		return ..()

	if(length(GLOB.blobstart) > 0)
		GLOB.poi_list.Remove(src)
		var/obj/item/disk/nuclear/NEWDISK = new(pick(GLOB.blobstart))
		transfer_fingerprints_to(NEWDISK)
		message_admins("[src] has been destroyed at [ADMIN_COORDJMP(diskturf)]. Moving it to [ADMIN_COORDJMP(NEWDISK)].")
		add_game_logs("[src] has been destroyed in [COORD(diskturf)]. Moving it to [COORD(NEWDISK)].")
		return QDEL_HINT_HARDDEL_NOW
	else
		error("[src] was supposed to be destroyed, but we were unable to locate a blobstart landmark to spawn a new one.")
	return QDEL_HINT_LETMELIVE // Cancel destruction unless forced.
