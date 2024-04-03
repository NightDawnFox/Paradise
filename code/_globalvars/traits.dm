/*
 FUN ZONE OF ADMIN LISTINGS
 Try to keep this in sync with __DEFINES/traits.dm
 quirks have it's own panel so we don't need them here.

 USE ALPABETIC ORDER HERE! (please)
*/
GLOBAL_LIST_INIT(traits_by_type, list(
	/atom = list(
		"TRAIT_BLOCK_RADIATION" = TRAIT_BLOCK_RADIATION,
		"TRAIT_CMAGGED" = TRAIT_CMAGGED,
	),
	/atom/movable = list(
		"TRAIT_MOVE_FLOATING" = TRAIT_MOVE_FLOATING,
		"TRAIT_MOVE_FLYING" = TRAIT_MOVE_FLYING,
		"TRAIT_MOVE_GROUND" = TRAIT_MOVE_GROUND,
		"TRAIT_MOVE_PHASING" = TRAIT_MOVE_PHASING,
		"TRAIT_MOVE_UPSIDE_DOWN" = TRAIT_MOVE_UPSIDE_DOWN,
		"TRAIT_MOVE_VENTCRAWLING" = TRAIT_MOVE_VENTCRAWLING,
		"TRAIT_NO_FLOATING_ANIM" = TRAIT_NO_FLOATING_ANIM,
	),
	/mob = list(
		"TRAIT_AI_UNTRACKABLE" = TRAIT_AI_UNTRACKABLE,
		"TRAIT_BLOODCRAWL" = TRAIT_BLOODCRAWL,
		"TRAIT_BLOODCRAWL_EAT" = TRAIT_BLOODCRAWL_EAT,
		"TRAIT_CHUNKYFINGERS" = TRAIT_CHUNKYFINGERS,
		"TRAIT_DEAF" = TRAIT_DEAF,
		"TRAIT_ELITE_CHALLENGER" = TRAIT_ELITE_CHALLENGER,
		"TRAIT_EMOTE_MUTE" = TRAIT_EMOTE_MUTE,
		"TRAIT_FAKEDEATH" = TRAIT_FAKEDEATH,
		"TRAIT_FORCE_DOORS" = TRAIT_FORCE_DOORS,
		"TRAIT_HEALS_FROM_CARP_RIFTS" = TRAIT_HEALS_FROM_CARP_RIFTS,
		"TRAIT_HEALS_FROM_CULT_PYLONS" = TRAIT_HEALS_FROM_CULT_PYLONS,
		"TRAIT_HEALS_FROM_HOLY_PYLONS" = TRAIT_HEALS_FROM_HOLY_PYLONS,
		"TRAIT_IGNOREDAMAGESLOWDOWN" = TRAIT_IGNOREDAMAGESLOWDOWN,
		"TRAIT_IGNORESLOWDOWN" = TRAIT_IGNORESLOWDOWN,
		"TRAIT_JESTER" = TRAIT_JESTER,
		"TRAIT_LASEREYES" = TRAIT_LASEREYES,
		"TRAIT_MUTE" = TRAIT_MUTE,
		"TRAIT_PACIFISM" = TRAIT_PACIFISM,
		"TRAIT_SECDEATH" = TRAIT_SECDEATH,
		"TRAIT_WATERBREATH"	= TRAIT_WATERBREATH,
		"TRAIT_XENO_HOST" = TRAIT_XENO_HOST,
	),
	/obj/item = list(
		"TRAIT_NEEDS_TWO_HANDS" = TRAIT_NEEDS_TWO_HANDS,
		"TRAIT_WIELDED" = TRAIT_WIELDED,
	),
	/turf = list(
		"TRAIT_TURF_COVERED" = TRAIT_TURF_COVERED,
		"TRAIT_TURF_IGNORE_SLOWDOWN" = TRAIT_TURF_IGNORE_SLOWDOWN,
	),
))


/// value -> trait name, list of ALL traits that exist in the game, used for any type of accessing.
GLOBAL_LIST(global_trait_name_map)

/proc/generate_global_trait_name_map()
	. = list()
	for(var/key in GLOB.traits_by_type)
		for(var/tname in GLOB.traits_by_type[key])
			var/val = GLOB.traits_by_type[key][tname]
			.[val] = tname

	return .


GLOBAL_LIST_INIT(movement_type_trait_to_flag, list(
	TRAIT_MOVE_GROUND = GROUND,
	TRAIT_MOVE_FLYING = FLYING,
	TRAIT_MOVE_VENTCRAWLING = VENTCRAWLING,
	TRAIT_MOVE_FLOATING = FLOATING,
	TRAIT_MOVE_PHASING = PHASING,
	TRAIT_MOVE_UPSIDE_DOWN = UPSIDE_DOWN,
))


GLOBAL_LIST_INIT(movement_type_addtrait_signals, set_movement_type_addtrait_signals())
GLOBAL_LIST_INIT(movement_type_removetrait_signals, set_movement_type_removetrait_signals())


/proc/set_movement_type_addtrait_signals(signal_prefix)
	. = list()
	for(var/trait in GLOB.movement_type_trait_to_flag)
		. += SIGNAL_ADDTRAIT(trait)
	return .


/proc/set_movement_type_removetrait_signals(signal_prefix)
	. = list()
	for(var/trait in GLOB.movement_type_trait_to_flag)
		. += SIGNAL_REMOVETRAIT(trait)
	return .

