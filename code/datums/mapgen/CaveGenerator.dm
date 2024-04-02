/datum/map_generator/cave_generator
	var/name = "Cave Generator"
	///Weighted list of the types that spawns if the turf is simulated
	var/simulated_turf_types = list(/turf/simulated/floor/plating/asteroid = 1)
	///Weighted list of the types that spawns if the turf is a wall
	var/wall_turf_types =  list(/turf/simulated/mineral/random/volcanic = 1)


	///Weighted list of extra features that can spawn in the area, such as geysers.
	var/list/feature_spawn_list
	///Weighted list of mobs that can spawn in the area.
	var/list/mob_spawn_list
	///Weighted list of flora that can spawn in the area.
	var/list/flora_spawn_list
	// Weighted list of Megafauna that can spawn in the caves
	var/list/megafauna_spawn_list

	///Base chance of spawning a mob
	var/mob_spawn_chance = 6
	///Base chance of spawning flora
	var/flora_spawn_chance = 2
	///Base chance of spawning features
	var/feature_spawn_chance = 0.1
	///Unique ID for this spawner
	var/string_gen

	///Chance of cells starting closed
	var/initial_closed_chance = 45
	///Amount of smoothing iterations
	var/smoothing_iterations = 20
	///How much neighbours does a dead cell need to become alive
	var/birth_limit = 4
	///How little neighbours does a alive cell need to die
	var/death_limit = 3

/datum/map_generator/cave_generator/New()
	. = ..()
	if(!megafauna_spawn_list)
		megafauna_spawn_list  = GLOB.megafauna_spawn_list

/datum/map_generator/cave_generator/generate_terrain(list/turfs)
	var/start_time = REALTIMEOFDAY
	string_gen = rustg_cnoise_generate("[initial_closed_chance]", "[smoothing_iterations]", "[birth_limit]", "[death_limit]", "[world.maxx]", "[world.maxy]") //Generate the raw CA data

	for(var/i in turfs) //Go through all the turfs and generate them
		var/turf/gen_turf = i

		var/area/A = gen_turf.loc
		if(!(A.generate_caves))
			continue

		var/closed = text2num(string_gen[world.maxx * (gen_turf.y - 1) + gen_turf.x])

		/*
		var/stored_flags
		if(gen_turf.flags_1 & NO_RUINS_1)
			stored_flags |= NO_RUINS_1
		*/
		var/turf/new_turf = pickweight(closed ? wall_turf_types : simulated_turf_types)
		new_turf = gen_turf.ChangeTurf(new_turf)

		if(!closed)//Open turfs have some special behavior related to spawning flora and mobs.

			var/turf/simulated/new_open_turf = new_turf

			///Spawning isn't done in procs to save on overhead on the 60k turfs we're going through.

			//FLORA SPAWNING HERE
			var/atom/spawned_flora
			if(flora_spawn_list && prob(flora_spawn_chance))
				var/can_spawn = TRUE

				if(!(A.generate_flora))
					can_spawn = FALSE

				if(can_spawn)
					spawned_flora = pickweight(flora_spawn_list)
					spawned_flora = new spawned_flora(new_open_turf)

			//FEATURE SPAWNING HERE

			var/atom/spawned_feature
			if(feature_spawn_list && prob(feature_spawn_chance))
				var/can_spawn = TRUE

				if(!(A.generate_flora)) //checks the same flag because lol dunno
					can_spawn = FALSE

				var/atom/picked_feature = pickweight(feature_spawn_list)

				for(var/obj/structure/F in range(7, new_open_turf))
					if(istype(F, picked_feature))
						can_spawn = FALSE

				if(can_spawn)
					spawned_feature = new picked_feature(new_open_turf)


			//MOB SPAWNING HERE

			if(mob_spawn_list && !spawned_flora  && !spawned_feature && prob(mob_spawn_chance))
				var/can_spawn = TRUE

				if(!(A.generate_fauna))
					can_spawn = FALSE

				var/atom/picked_mob = pickweight(mob_spawn_list)

				if(picked_mob == SPAWN_MEGAFAUNA)
					if((A.generate_megafauna) && megafauna_spawn_list?.len) //this is danger. it's boss time.
						picked_mob = pickweight(megafauna_spawn_list)
					else //this is not danger, don't spawn a boss, spawn something else
						picked_mob = pickweight(mob_spawn_list - SPAWN_MEGAFAUNA) //What if we used 100% of the brain...and did something (slightly) less shit than a while loop?

				for(var/thing in urange(12, new_open_turf)) //prevents mob clumps
					if(!ishostile(thing) && !istype(thing, /obj/structure/spawner))
						continue
					if((ispath(picked_mob, /mob/living/simple_animal/hostile/megafauna) || ismegafauna(thing)) && get_dist(new_open_turf, thing) <= 7)
						can_spawn = FALSE //if there's a megafauna within standard view don't spawn anything at all
						break
					if(ispath(picked_mob, /mob/living/simple_animal/hostile/asteroid) || istype(thing, /mob/living/simple_animal/hostile/asteroid))
						can_spawn = FALSE //if the random is a standard mob, avoid spawning if there's another one within 12 tiles
						break
					if((ispath(picked_mob, /obj/structure/spawner/lavaland) || istype(thing, /obj/structure/spawner/lavaland)) && get_dist(new_open_turf, thing) <= 2)
						can_spawn = FALSE //prevents tendrils spawning in each other's collapse range
						break

				if(can_spawn)
					if(ispath(picked_mob, /mob/living/simple_animal/hostile/megafauna/bubblegum)) //there can be only one bubblegum, so don't waste spawns on it
						megafauna_spawn_list.Remove(picked_mob)
					if(ispath(picked_mob, /mob/living/simple_animal/hostile/megafauna/ancient_robot)) //same as above, we do not want multiple of these robots
						megafauna_spawn_list.Remove(picked_mob)

					new picked_mob(new_open_turf)
		CHECK_TICK
	var/message = "[name] finished in [(REALTIMEOFDAY - start_time)/10]s!"
	to_chat(world, "<span class='boldannounce'>[message]</span>")
	log_world(message)
