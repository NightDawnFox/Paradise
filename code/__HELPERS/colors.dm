#define RANDOM_COLOUR (rgb(rand(0, 255), rand(0, 255), rand(0, 255)))

/**
 * Flashes a color on the screen of a mob or client for a specified duration
 *
 * Arguments:
 * * target - The mob or client to flash the color on
 * * flash_color - The color to flash (default: cult red)
 * * flash_duration - The duration of the flash in seconds (default: 2 seconds)
 */
/proc/flash_color(target, flash_color = COLOR_CULT_RED, flash_duration = 2 SECONDS)
	var/client/target_client
	if(ismob(target))
		var/mob/mob_instance = target
		if(mob_instance.client)
			target_client = mob_instance.client
		else
			return
	else if(isclient(target))
		target_client = target

	if(!istype(target_client))
		return

	target_client.color = flash_color
	spawn(0)
		animate(target_client, color = initial(target_client.color), time = flash_duration)

/// Given a color in the format of "#RRGGBB", will return if the color is dark.
/proc/is_color_dark(color, threshold = 25)
	var/hsl = rgb2num(color, COLORSPACE_HSL)
	return hsl[3] < threshold

GLOBAL_LIST_INIT(hex_characters, list("0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"))

/proc/random_short_color()
	return random_string(3, GLOB.hex_characters)

/proc/random_color()
	return random_string(6, GLOB.hex_characters)

/proc/ready_random_color()
	return "#" + random_string(6, GLOB.hex_characters)

/**
 * Gets a color for a name, will return the same color for a given string consistently within a round.atom
 *
 * Note that this proc aims to produce pastel-ish colors using the HSL colorspace. These seem to be favorable for displaying on the map.
 *
 * Arguments:
 * * name - The name to generate a color for
 * * sat_shift - A value between 0 and 1 that will be multiplied against the saturation
 * * lum_shift - A value between 0 and 1 that will be multiplied against the luminescence
 */
/proc/colorize_string(name, sat_shift = 1, lum_shift = 1)
	// seed to help randomness
	var/static/rseed = rand(1,26)

	// get hsl using the selected 6 characters of the md5 hash
	var/hash = copytext(md5(name + GLOB.round_id), rseed, rseed + 6)
	var/h = hex2num(copytext(hash, 1, 3)) * (360 / 255)
	var/s = (hex2num(copytext(hash, 3, 5)) >> 2) * ((CM_COLOR_SAT_MAX - CM_COLOR_SAT_MIN) / 63) + CM_COLOR_SAT_MIN
	var/l = (hex2num(copytext(hash, 5, 7)) >> 2) * ((CM_COLOR_LUM_MAX - CM_COLOR_LUM_MIN) / 63) + CM_COLOR_LUM_MIN

	// adjust for shifts
	s = clamp(s * sat_shift, 0, 1)
	l = clamp(l * lum_shift, 0, 1)

	// convert to rgb
	var/h_int = round(h/60) // mapping each section of H to 60 degree sections
	var/c = (1 - abs(2 * l - 1)) * s
	var/x = c * (1 - abs((h / 60) % 2 - 1))
	var/m = l - c * 0.5
	x = (x + m) * 255
	c = (c + m) * 255
	m *= 255
	switch(h_int)
		if(0)
			return "#[num2hex(c, 2)][num2hex(x, 2)][num2hex(m, 2)]"
		if(1)
			return "#[num2hex(x, 2)][num2hex(c, 2)][num2hex(m, 2)]"
		if(2)
			return "#[num2hex(m, 2)][num2hex(c, 2)][num2hex(x, 2)]"
		if(3)
			return "#[num2hex(m, 2)][num2hex(x, 2)][num2hex(c, 2)]"
		if(4)
			return "#[num2hex(x, 2)][num2hex(m, 2)][num2hex(c, 2)]"
		if(5)
			return "#[num2hex(c, 2)][num2hex(m, 2)][num2hex(x, 2)]"

/*
 * Generates an HSL color transition matrix filter which nicely paints an object
 * without making it a deep fried blob of color.
 *
 * saturation_behavior determines how we handle color saturation:
 * * SATURATION_MULTIPLY - Multiply pixel's saturation by color's saturation. Paints accents while keeping dim areas dim.
 * * SATURATION_OVERRIDE- Affects original lightness/saturation to ensure that pale objects still get doused in color
 */
/proc/color_transition_filter(new_color, saturation_behavior = SATURATION_MULTIPLY)
	if(islist(new_color))
		new_color = rgb(new_color[1], new_color[2], new_color[3])
	new_color = rgb2num(new_color, COLORSPACE_HSL)
	var/hue = new_color[1] / 360
	var/saturation = new_color[2] / 100
	var/added_saturation = 0
	var/deducted_light = 0
	if(saturation_behavior == SATURATION_OVERRIDE)
		added_saturation = saturation * 0.75
		deducted_light = saturation * 0.5
		saturation = min(saturation, 1 - added_saturation)

	var/list/new_matrix = list(
		0, 0, 0, // Ignore original hue
		0, saturation, 0, // Multiply the saturation by ours
		0, 0, 1 - deducted_light, // If we're highly saturated then remove a bit of lightness to keep some color in
		hue, added_saturation, 0, // And apply our preferred hue and some saturation if we're oversaturated
	)
	return color_matrix_filter(new_matrix, FILTER_COLOR_HSL)

/// Applies a color filter to a hex/RGB list color
/proc/apply_matrix_to_color(color, list/matrix, colorspace = COLORSPACE_HSL)
	if(islist(color))
		color = rgb(color[1], color[2], color[3], color[4])
	color = rgb2num(color, colorspace)
	// Pad alpha if we're lacking it
	if(length(color) < 4)
		color += 255

	// Do we have a constants row?
	var/has_constants = FALSE
	// Do we have an alpha row/parameters?
	var/has_alpha = FALSE

	switch(length(matrix))
		if(9)
			has_constants = FALSE
			has_alpha = FALSE
		if(12)
			has_constants = TRUE
			has_alpha = FALSE
		if(16)
			has_constants = FALSE
			has_alpha = TRUE
		if(20)
			has_constants = TRUE
			has_alpha = TRUE
		else
			CRASH("Matrix of invalid length [length(matrix)] was passed into apply_matrix_to_color!")

	var/list/new_color = list(0, 0, 0, 0)
	var/row_length = 3
	if(has_alpha)
		row_length = 4
	else
		new_color[4] = 255

	for(var/row_index in 1 to (length(matrix) / row_length))
		for(var/row_elem in 1 to row_length)
			var/elem = matrix[(row_index - 1) * row_length + row_elem]
			if(!has_constants || row_index != (length(matrix) / row_length))
				new_color[row_index] += color[row_elem] * elem
				continue

			// Constant values at the end of the list (if we have such)
			if(colorspace != COLORSPACE_HSV && colorspace != COLORSPACE_HCY && colorspace != COLORSPACE_HSL)
				new_color[row_elem] += elem * 255
				continue

			// HSV/HSL/HCY have non-255 maximums for their values
			var/multiplier = 255
			switch(row_elem)
				// Hue goes from 0 to 360
				if(1)
					multiplier = 360
				// Value, luminance, chroma, etc go from 0 to 100
				if(2 to 3)
					multiplier = 100
				// Alpha still goes from 0 to 255
				if(4)
					multiplier = 255
			new_color[row_elem] += elem * multiplier

	var/rgbcolor = rgb(new_color[1], new_color[2], new_color[3], new_color[4], space = colorspace)
	return rgbcolor
