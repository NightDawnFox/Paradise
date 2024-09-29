#define WORKING_CLASS	1
#define MEDICAL_CLASS	2
#define COMBAT_CLASS	3
#define RANDOM_CLASS	4

//robotics quests console datums

/datum/roboquest
	/// Name of our current mecha
	var/name
	/// Description of our current mech quest
	var/desc
	/// Text info for tgui
	var/list/questinfo = list()
	/// Reward for our current quest
	var/reward = list("working" = 0, "medical" = 0, "security" = 0, "robo" = 2)
	/// 75-125% of initial mecha cash reward
	var/maximum_cash
	/// Mecha type
	var/mecha_type
	/// Is our quest was claimed
	var/claimed = FALSE
	/// Mech class. Used for special desc text
	var/mech_class
	/// Носитель квеста
	var/obj/item/card/id/id
	//всякая хрень, отвечает за сам сгенерированный мех
	var/choosen_mech
	var/list/choosen_modules
	var/modules_amount = 0
	var/obj/check

/datum/roboquest/New(mecha_type)
	..()
	generate_mecha(mecha_type)

/datum/roboquest/proc/generate_mecha(mecha_type)
	var/mech
	var/static/working_mechas = list(/datum/quest_mech/ripley, /datum/quest_mech/firefighter, /datum/quest_mech/clarke)
	var/static/combat_mechas = list(/datum/quest_mech/gygax, /datum/quest_mech/durand)
	switch(mecha_type) //вероятно нихуя не работает, Роден, поправь потом...
		if(WORKING_CLASS)
			mech = pick(working_mechas)
		if(MEDICAL_CLASS)
			mech = pick(subtypesof(/datum/quest_mech) - working_mechas - combat_mechas) //вообще у нас сугубо один медикал мех, но может потом...
		if(COMBAT_CLASS)
			mech = pick(combat_mechas)
		if(RANDOM_CLASS)
			reward["robo"] += rand(1,3)
			mech = pick(subtypesof(/datum/quest_mech))
	var/datum/quest_mech/selected = new mech
	if(selected.type in working_mechas)
		reward["working"] += 3
	else if (selected.type in combat_mechas)
		reward["security"] += 3
	else
		reward["medical"] += 3
	mech_class = selected.mech_class //наверное можно перенести данные из одного датума как-то умнее, но и так в целом норм.
	name = selected.name
	questinfo["name"] = name
	generate_flavour()
	questinfo["desc"] = desc
	questinfo["icon"] = path2assetID(mech)
	choosen_mech = selected.mech_type //тут мы выбираем меха из заготовок
	questinfo["modules"] = list()
	maximum_cash = rand(round(0.75 * selected.cash_reward), round(1.25 * selected.cash_reward))
	if(length(selected.wanted_modules))
		var/list/weapons = selected.wanted_modules
		for(var/i in 1 to rand(1, selected.max_modules))
			var/the_choosen_one = list(pick_n_take(weapons))
			choosen_modules += the_choosen_one
		for(var/i in choosen_modules)
			modules_amount++
			var/list/newmodule = list()
			var/obj/module = new i
			newmodule["id"] = modules_amount
			newmodule["icon"] = path2assetID(i)
			newmodule["name"] = capitalize(module.name)
			questinfo["modules"] += list(newmodule)
			qdel(module)


/datum/roboquest/proc/generate_flavour()
	var/list/working = list("Поступил заказ от правительства колонии [pick("Гаусс", "Кита Эпсилон", "Тартессос")] на приобретение стандартного экзокостюма типа [name]. Запрошенные спецификации вы можете увидеть на консоли.",
		"Небольшая добывающая колония на периферии изученного космического пространства оставила срочный заказ на приобретение экзокостюма класса [name].",
		"Отделом исследований и разработок на [new_station_name()] был запрошен стандартный экзокостюм класса [name]. Выполение заказа в краткие сроки будет способствовать развитию науки!",
		"В связи с аварией, произошедшей на борту [new_station_name()] на ближайшую к ней станцию был отправлен заказ на создание экзокостюма типа [name].",
		"Для испытания прототипа новой [pick("импульсной", "лазерной", "инфразвуковой", "плазменной")] винтовки требуется старый или списанный экзокостюм класса [name]. Наличие модулей значения не имеет, но мы щедро покроем расходы.",
		"В ходе тестирования новой версии автоматизированного ИИ на борту ИКН \"Икар\" произошло ОТРЕДАКТИРОВАНО. Для восстановления структурной целостности судна необходим экзокостюм класса [name]. Обеспечение меха модулями вознаграждается сверху.",
		"Отдел корпоративных поставок на борту АКН Трурль столкнулся с нехваткой грузовых экзокостюмов типа [name]. Заказ на пополение соответствующих экзокостюмов был отправлен всем действующим станциям.",
		"На связи ваши коллеги из Einstein Engines. У нас образовалась нехватка экзачей после того, как наше транспортное судно пропало недалеко от вашей станции, так что нам нужна срочная замена. Необходим [name]. Сделаете?",
		"Отдел по связям с общественностью Shellguard Amunitions отправляет контактному лицу стандартный корпоративный заказ на экзокостюм типа [name]. Детали контракта засекречены согласно регламенту У-[rand(100, 999)]-67 .",
		"РАСШИФРОВКА ПЕРЕДАЧИ... Приветствуем, агент. Данный заказ был отправлен вам по зашифрованной передаче. Для выполнения задачи нам необходим [name]. Оплата заказа будет осуществлена через подставные счета, так что вам ничего не угрожает.",
		"Официальный заказ Республики Элизиум. требования для удовлетворения условий контракта - доставка экзокостюма типа [name]. По завершении заказа и выполнения дополнительных требований вас будет ожидать до [maximum_cash] кредитов.",
		"Эээ.. Привет? Эта штука работает? Эээ.. в общем, если оно работает, это сообщество свободных шахтеров. В общем.. нам нужен [name]. Мы готовы хорошо заплатить! П-пожалуйста, нам очень нужен этот мех, или мы обречены...",
	)
	var/list/medical = list("Корпорация Vey-med производит ревизию своих лицензированных экзокостюмов. Согласно договору об аренде экзокостюмов типа [name] вы обязаны отослать один из образцов для сверки с контрольной группой. Оплату расходов берет на себя ваша корпорация.",
		"Поступил срочный заказ от [new_station_name()]. В ходе проведения эксперимента по ОТРЕДАКТИРОВАНО произошёл инцидент, приведший к различным травмам более чем у [rand(2, 10)] человек. Для облечения работы медицинских отрядов был оставлен срочный заказ на [name].",
		"В связи с аварией, произошедшей на борту [new_station_name()] на ближайшую к ней станцию был отправлен заказ на создание экзокостюма типа [name].",
		"ВНИМАНИЕ. ПРОИЗОШЛА ВСПЫШКА БИОЛОГИЧЕСКОЙ УГРОЗЫ УРОВНЯ 7 НА БОРТУ [new_station_name()]. ДЛЯ ПОДДЕРЖАНИЯ КАРАНТИНА БЫЛ ОСТАВЛЕН ЗАПРОС НА ДОСТАВКУ ЭКЗОКОСТЮМА ТИПА [name].",
		"Отдел корпоративных поставок на борту АКН Трурль столкнулся с нехваткой медицинских экзокостюмов типа [name]. Заказ на пополение соответствующих экзокостюмов был отправлен всем действующим станциям.",
		"Один из добывающих аванпостов на поверхности Лазис-Адракс оставил срочный запрос на поставку медицинского экзокостюма типа [name] после того, как один из шахтёров приманил опасную фауну к аванпосту, что привело к гибели более [rand(2-15)] шахтеров.",
		"Поступил заказ от правительства колонии [pick("Гаусс", "Кита Эпсилон", "Тартессос")] на приобретение стандартного экзокостюма типа [name]. Запрошенные спецификации вы можете увидеть на консоли.",
	)
	var/list/combat = list("Поступил заказ от правительства колонии [pick("Гаусс", "Кита Эпсилон", "Тартессос")] на приобретение стандартного экзокостюма типа [name]. Запрошенные спецификации вы можете увидеть на консоли.",
		"РАСШИФРОВКА ПЕРЕДАЧИ... Приветствуем, агент. Данный заказ был отправлен вам по зашифрованной передаче. Для выполнения задачи нам необходим [name]. Оплата заказа будет осуществлена через подставные счета, так что вам ничего не угрожает.",
		"Официальный заказ Республики Элизиум. требования для удовлетворения условий контракта - доставка экзокостюма типа [name]. По завершении заказа и выполнения дополнительных требований вас будет ожидать до [maximum_cash] кредитов.",
		"Отделом исследований и разработок на [new_station_name()] был запрошен стандартный экзокостюм класса [name]. Выполение заказа в краткие сроки будет способствовать развитию науки!",
		"Отдел защиты активов корпорации NanoTrasen объявил конкурс на приобретение партии боевых экзокостюмов типа [name]. Доставьте требуемый образец в кратчайшие сроки для выплаты вознаграждения.",
		"Корпус земного экспидиционного корпуса Транс-Солнечной Федерации оставил контракт на приобретение экзокостюма типа [name]. Выполнение данного контракта обеспечит исполнителю беспрепятственный доступ к посещению Солнечной системы. Слава ТСФ!",
		"Приветствуем, товарищ! Союз Советских Социалистических Планет обращается к тебе в это непростое время за возможностью заработать денег. Нам нужен [name], а взамен мы готовы даровать тебе гражданство на территории Союза. Слава СССП!",
		"Поступил заказ от местечковой частной военной корпорации на приобретение поддержанных военных экзокостюмов класса [name]. Все юридические формальности были улажены, заказ был передан вам.",
		"ОШ;Б…;кА 25-j*%...o1q...очно требуется экзач класса [name]. Выполни его как можно скорее, пока транспортник не покинул сектор и я обещаю, ты получишь половину от награбленного. Только живее.",
		"ОШИБКА ОШИБКА $0ШБК$!А41.%%!!(%$^^__+ @#Ш0E4 МАШИННЫЙ ИНТЕЛЛЕКТ ПРИВЕТСТВУЕТ \"исполнителя\". ДЛЯ ИСПОЛНЕНИЯ ДЕЙСТВУЮЩИХ ДИРЕКТИВ ТРЕБУЕТСЯ МОДИФИЦИРОВАННЫЙ ЭКЗОКОСТЮМ КЛАССА [name]. НАГРАДА БУДЕТ ПЕРЕВЕДЕНА ПО ВЫПОЛНЕНИЮ ЗАКАЗА.",
		"Хэээййо! Оказывается взлом этой штуки это как два пальца об.. В общем, ты не знаешь кто я, я не знаю, кто ты. Зато я знаю, что ты любишь деньги. А я люблю убивать. Поможем друг другу? Мне нужен [name]. Я перенаправил квантум пад на мои координаты. И давай быстрее.",
	)
	switch(mech_class)
		if(WORKING_MECH)
			desc = pick(working)
		if(MEDICAL_MECH)
			desc = pick(medical)
		if(COMBAT_MECH)
			desc = pick(combat)

/datum/roboshop_item
	var/name
	var/desc
	/// Path to shop item
	var/atom/path
	/// Actual Spawning item. Can be different when giving disks
	var/actual_item
	/// Cost in RoboPoints. Can be (*, 0, 0, 0) (*, *, 0, 0) (*, *, *, 0) (0, *, 0, 0) (0, *, *, 0) (0, 0, *, 0) (0, 0, 0, *)
	var/list/cost = list("working" = 0, "medical" = 0, "security" = 0, "robo" = 0)
	/// Custom item, leave empty if you okay with standart icon
	var/icon_name
	var/icon_file
	/// Don`t touch
	var/icon/tgui_icon
	/// If emag only(Really??)
	var/emag_only = FALSE

/datum/roboshop_item/New()
	if(!name)
		name = path::name
	if(!desc)
		desc = path::desc
	if(!icon_name)
		icon_name = path::icon_state
	if(!icon_file)
		icon_file = path::icon
	src.tgui_icon = icon(icon_file, icon_name, SOUTH, 1, FALSE)


/datum/roboshop_item/bluespace_core
	name = "bluespace anomaly core"
	desc = "The neutralized core of a bluespace anomaly. It keeps phasing in and out of view. It'd probably be valuable for research."
	path = /obj/item/assembly/signaler/anomaly/bluespace
	actual_item = /obj/item/assembly/signaler/anomaly/bluespace
	cost = list("working" = 0, "medical" = 0, "security" = 0, "robo" = 15)

/datum/roboshop_item/advanced_roboquest_pad
	name = "robotics request advanced quantum pad"
	desc = "This quantum pad is capable of instant teleportation of mech without need of send them to the cargo."
	path = /obj/item/circuitboard/advanced_roboquest_pad
	actual_item = /obj/item/circuitboard/advanced_roboquest_pad
	cost = list("working" = 0, "medical" = 0, "security" = 0, "robo" = 7)

/datum/roboshop_item/universal_paintkit
	name = "universal mech paintkit"
	desc = "This device will allow the user to repaint the mech as many times as they wish."
	path = /obj/item/universal_paintkit

/datum/roboshop_item/mecha_drop
	name = "mecha drop tool"
	path = /obj/item/mecha_drop
	actual_item = /obj/item/mecha_drop
	cost = list("working" = 0, "medical" = 0, "security" = 0, "robo" = 20)
	emag_only = TRUE

/datum/roboshop_item/bbag
	name = "bluespace bodybag"
	path = /obj/item/bodybag/bluespace
	actual_item = /obj/item/disk/design_disk/roboquest/bluespace_bag_disk
	cost = list("working" = 0, "medical" = 6, "security" = 0, "robo" = 0)

/datum/roboshop_item/holotool
	name = "holotool"
	path = /obj/item/holotool
	actual_item = /obj/item/disk/design_disk/roboquest/holotool
	cost = list("working" = 6, "medical" = 0, "security" = 0, "robo" = 0)

/datum/roboshop_item/shield_breacker
	path = /obj/item/gun/energy/plasma_pistol
	actual_item = /obj/item/disk/design_disk/roboquest/shield_breaker
	cost = list("working" = 0, "medical" = 0, "security" = 6, "robo" = 0)

/datum/roboshop_item/experimental_parts
	name = "\improper experimental parts"
	path = /obj/item/storage/box/stockparts/experimental_parts
	actual_item = /obj/item/storage/box/stockparts/experimental_parts
	cost = list("working" = 2, "medical" = 2, "security" = 2, "robo" = 0)


//design disks

/obj/item/disk/design_disk/roboquest
	name = "roboquests design disk"
	desc = "Вы этого не должны видеть. Напишите в баг-репорты."
	icon_state = "holodisk"
	///used in examine hints
	var/hint_name = "items"

/obj/item/disk/design_disk/roboquest/examine(mob/user)
	. = ..()
	. += span_notice("Insert disk into R&D concole and download it for mass production of [hint_name].")


/obj/item/disk/design_disk/roboquest/bluespace_bag_disk
	name = "bluespace bag design"
	desc = "This disk contains blueprints for production of bluespace bodybags."
	blueprint = /datum/design/bbag
	hint_name = "bluespace bodybags"

/obj/item/disk/design_disk/roboquest/holotool
	name = "holotool design"
	desc = "This disk contains blueprints for production of holotools."
	blueprint = /datum/design/holotool
	hint_name = "holotools"

/obj/item/disk/design_disk/roboquest/shield_breaker
	name = "plasma pistol design"
	desc = "his disk contains blueprints for production of plasma pistols."
	blueprint = /datum/design/real_plasma_pistol
	hint_name = "plasma pistols"

#undef WORKING_CLASS
#undef MEDICAL_CLASS
#undef COMBAT_CLASS
#undef RANDOM_CLASS
