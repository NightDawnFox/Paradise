/datum/component/combo_attacks
	/// Length of combo we allow before resetting.
	var/max_combo_length
	/// Message when the combo is reset.
	var/reset_message
	/// ID for the reset combo timer.
	var/timerid
	/// How much time before the combo resets.
	var/leniency_time
	/// List of inputs done by user.
	var/list/input_list = list()
	/// Associative list of all the combo moves. Name of Attack = list(COMBO_STEPS = list(Steps made of HARM_SLASH and DISARM_SLASH), COMBO_PROC = PROC_REF(Proc Name))
	var/list/combo_list = list()
	/// A list of strings containing the ways to do combos, for examines.
	var/list/combo_strings = list()
	/// A callback to the proc that checks whether or not we can do combo attacks.
	var/datum/callback/can_attack_callback

/datum/component/combo_attacks/Initialize(combos, reset_message, max_combo_length, leniency_time = 5 SECONDS, can_attack_callback)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	combo_list = combos
	for(var/combo in combo_list)
		var/list/combo_specifics = combo_list[combo]
		var/step_string = english_list(combo_specifics[COMBO_STEPS])
		combo_strings += span_notice("<b>[combo]</b> - [step_string]")
	src.reset_message = reset_message
	src.max_combo_length = max_combo_length
	src.leniency_time = leniency_time
	src.can_attack_callback = can_attack_callback

/datum/component/combo_attacks/Destroy(force)
	can_attack_callback = null
	return ..()

/datum/component/combo_attacks/RegisterWithParent()
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_ITEM_ATTACK_SELF, PROC_REF(on_attack_self))
	RegisterSignal(parent, COMSIG_ITEM_DROPPED, PROC_REF(on_drop))
	RegisterSignal(parent, COMSIG_ITEM_ATTACK, PROC_REF(on_attack))

/datum/component/combo_attacks/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_PARENT_EXAMINE, COMSIG_ITEM_ATTACK_SELF, COMSIG_ITEM_DROPPED, COMSIG_ITEM_ATTACK))

/datum/component/combo_attacks/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	examine_list += combo_strings

/datum/component/combo_attacks/proc/on_attack_self(obj/item/source, mob/user)
	SIGNAL_HANDLER

	reset_inputs(user, deltimer = TRUE)

/datum/component/combo_attacks/proc/on_drop(datum/source, mob/dropper)
	SIGNAL_HANDLER

	reset_inputs(user = null, deltimer = TRUE)

/datum/component/combo_attacks/proc/check_input(mob/living/target, mob/user)
	for(var/combo in combo_list)
		var/list/combo_specifics = combo_list[combo]
		if(compare_list(input_list, combo_specifics[COMBO_STEPS]))
			INVOKE_ASYNC(parent, combo_specifics[COMBO_PROC], target, user)
			return TRUE
	return FALSE

/datum/component/combo_attacks/proc/reset_inputs(mob/user, deltimer)
	input_list.Cut()
	if(user)
		atom_parent.balloon_alert(user, reset_message)
	if(deltimer && timerid)
		deltimer(timerid)

/datum/component/combo_attacks/proc/on_attack(datum/source, mob/living/target, mob/user)
	SIGNAL_HANDLER

	if(can_attack_callback && !can_attack_callback.Invoke(user, target))
		return NONE
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		return NONE
	switch(user.a_intent)
		if(INTENT_HELP)
			input_list += HELP_SLASH
		if(INTENT_DISARM)
			input_list += DISARM_SLASH
		if(INTENT_GRAB)
			input_list += GRAB_SLASH
		if(INTENT_HARM)
			input_list += HARM_SLASH
	if(length(input_list) > max_combo_length)
		reset_inputs(user, deltimer = TRUE)
	if(check_input(target, user))
		reset_inputs(user = null, deltimer = TRUE)
		return COMPONENT_CANCEL_ATTACK_CHAIN
	if(leniency_time)
		timerid = addtimer(CALLBACK(src, PROC_REF(reset_inputs), user, FALSE), leniency_time, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_STOPPABLE)
	return NONE
