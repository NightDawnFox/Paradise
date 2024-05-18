/**
  * # Rapid Crate Sender (RCS)
  *
  * Used to teleport crates and closets to cargo telepads.
  *
  * If emagged, it allows you to teleport crates to a random location, and also teleport yourself while inside a locker.
  */
/obj/item/rcs
	name = "rapid-crate-sender (RCS)"
	desc = "A device used to teleport crates and closets to cargo telepads."
	icon = 'icons/obj/telescience.dmi'
	icon_state = "rcs"
	item_state = "rcd"
	flags = CONDUCT
	force = 10.0
	throwforce = 10.0
	throw_speed = 2
	throw_range = 5
	toolspeed = 1
	usesound = 'sound/machines/click.ogg'
	/// Power cell (10000W)
	var/obj/item/stock_parts/cell/high/rcell = null
	/// Selected telepad
	var/obj/machinery/pad = null

	/// Currently teleporting something?
	var/teleporting = FALSE
	/// How much power does each teleport use?
	var/chargecost = 1000
	/// Is emagged?
	var/emagged = FALSE

/obj/item/rcs/get_cell()
	return rcell

/obj/item/rcs/New()
	..()
	rcell = new(src)

/obj/item/rcs/examine(mob/user)
	. = ..()
	. += "<span class='notice'>There are [round(rcell.charge/chargecost)] charge\s left.</span>"

/obj/item/rcs/Destroy()
	QDEL_NULL(rcell)
	return ..()

/**
  * Used to select telepad location.
  */
/obj/item/rcs/attack_self(mob/user)
	if(teleporting)
		user.balloon_alert(user, "Error: [name] is in use.")
		return

	var/list/L = list() // List of avaliable telepads
	var/list/areaindex = list() // Telepad area location
	for(var/obj/machinery/telepad_cargo/R in GLOB.machines)
		if(R.stage)
			continue
		var/turf/T = get_turf(R)
		var/locname = T.loc.name // The name of the turf area. (e.g. Cargo Bay, Experimentation Lab)

		if(areaindex[locname]) // If there's another telepad with the same area, increment the value so as to not override (e.g. Cargo Bay 2)
			locname = "[locname] ([++areaindex[locname]])"
		else // Else, 1
			areaindex[locname] = 1
		L[locname] = R

	if(emagged) // Add an 'Unknown' entry at the end if it's emagged
		L += "**Unknown**"

	var/select = tgui_input_list(user, "Please select a telepad.", "RCS", L)
	if(select == "**Unknown**") // Randomise the teleport location
		pad = random_coords()
	else // Else choose the value of the selection
		pad = L[select]
	playsound(src, 'sound/effects/pop.ogg', 25, TRUE) // And play a sound either way.


/**
  * Returns a random location in a z level
  *
  * Defaults to Z level 1, with a 50% chance of being a different one.
  * Z levels 1 to 4 are excluded from the alternatives.
  * Coordinates are constrained within 50-200 x & y.
  */
/obj/item/rcs/proc/random_coords()
	var/Z = pick(levels_by_trait(STATION_LEVEL)) // Z level
	// Random Coordinates
	var/rand_x = rand(50, 200)
	var/rand_y = rand(50, 200)

	if(prob(50)) // 50% chance of being a different Z level
		var/list/random_space_levels_z = get_all_linked_levels_zpos() //Creates list for space Z-levels
		for(var/check_z in random_space_levels_z)
			if(is_station_level(check_z))
				random_space_levels_z -= check_z //Deletes station lvl, so there's only space
		Z = pick(random_space_levels_z) // Pick a z level

	return locate(rand_x, rand_y, Z)

/obj/item/rcs/emag_act(mob/user)
	if(!emagged)
		add_attack_logs(user, src, "emagged")
		emagged = TRUE
		do_sparks(3, TRUE, src)
		if(user)
			user.balloon_alert(user, "Warning: Safeties disabled.")
		return


/obj/item/rcs/proc/try_send_container(mob/user, obj/structure/closet/C)
	if(teleporting)
		user.balloon_alert(user, "You're already using [src]!")
		return FALSE
	if((!emagged) && (user in C.contents)) // If it's emagged, skip this check.
		C.balloon_alert(user, "Error: User located in container.")
		return FALSE
	if(rcell.charge < chargecost)
		user.balloon_alert(user, "Insufficient charge.")
		return FALSE
	if(!pad)
		user.balloon_alert(user, "Error: No telepad selected.")
		return FALSE
	if(!is_level_reachable(C.z))
		user.balloon_alert(user, "Warning: No telepads in range!")
		return FALSE
	if(C.anchored)
		user.balloon_alert(user, "Error: [C.name] is anchored!")
		return FALSE

	teleport(user, C, pad)
	return TRUE


/obj/item/rcs/proc/teleport(mob/user, obj/structure/closet/C, target)
	user.balloon_alert(user, "Teleporting [C]...")
	playsound(src, usesound, 50, TRUE)
	teleporting = TRUE
	if(!do_after(user, 5 SECONDS * toolspeed * gettoolspeedmod(user), C))
		teleporting = FALSE
		return

	teleporting = FALSE
	rcell.use(chargecost)
	do_sparks(5, TRUE, C)
	do_teleport(C, target)
	user.balloon_alert(user, "success! [round(rcell.charge/chargecost)] charge\s left.")
