/////////////////////////Food Reagents////////////////////////////
// Part of the food code. Nutriment is used instead of the old "heal_amt" code. Also is where all the food
// 	condiments, additives, and such go.

/datum/reagent/consumable
	name = "Consumable"
	id = "consumable"
	harmless = TRUE
	taste_description = "generic food"
	taste_mult = 4
	var/nutriment_factor = 1 * REAGENTS_METABOLISM
	var/diet_flags = DIET_OMNI | DIET_HERB | DIET_CARN

/datum/reagent/consumable/on_mob_life(mob/living/M)
	if(ishuman(M) && !M.mind?.has_antag_datum(/datum/antagonist/vampire) && !HAS_TRAIT(M, TRAIT_I_WANT_BRAINS))
		var/mob/living/carbon/human/H = M
		if(H.can_eat(diet_flags))	//Make sure the species has it's dietflag set, otherwise it can't digest any nutrients
			H.adjust_nutrition(nutriment_factor)	// For hunger and fatness
	return ..()

/// Pure nutriment, universally digestable and thus slightly less effective
/datum/reagent/consumable/nutriment
	name = "Nutriment"
	id = "nutriment"
	description = "A questionable mixture of various pure nutrients commonly found in processed foods."
	nutriment_factor = 15 * REAGENTS_METABOLISM
	color = "#664330" // rgb: 102, 67, 48
	var/brute_heal = 1
	var/burn_heal = 0

/datum/reagent/consumable/nutriment/on_mob_life(mob/living/M)
	var/update_flags = STATUS_UPDATE_NONE
	if(ishuman(M) && !M.mind?.has_antag_datum(/datum/antagonist/vampire) && !HAS_TRAIT(M, TRAIT_I_WANT_BRAINS))
		var/mob/living/carbon/human/H = M
		if(H.can_eat(diet_flags))	//Make sure the species has it's dietflag set, otherwise it can't digest any nutrients
			if(prob(50))
				update_flags |= M.adjustBruteLoss(-brute_heal, FALSE)
				update_flags |= M.adjustFireLoss(-burn_heal, FALSE)
	return ..() | update_flags

/datum/reagent/consumable/nutriment/on_new(list/supplied_data)
	// taste data can sometimes be ("salt" = 3, "chips" = 1)
	// and we want it to be in the form ("salt" = 0.75, "chips" = 0.25)
	// which is called "normalizing"
	if(!supplied_data)
		supplied_data = data
	// if data isn't an associative list, this has some WEIRD side effects
	// TODO probably check for assoc list?
	data = counterlist_normalise(supplied_data)

/datum/reagent/consumable/nutriment/on_merge(list/newdata, newvolume)
	if(!islist(newdata) || !length(newdata))
		return
	var/list/taste_amounts = list()
	var/list/other_taste_amounts = newdata.Copy()
	if(data)
		taste_amounts = data.Copy()
	counterlist_scale(taste_amounts, volume)
	counterlist_combine(taste_amounts, other_taste_amounts)
	counterlist_normalise(taste_amounts)
	data = taste_amounts

/// Meat-based protein, digestable by carnivores and omnivores, worthless to herbivores
/datum/reagent/consumable/nutriment/protein
	name = "Protein"
	id = "protein"
	description = "Various essential proteins and fats commonly found in animal flesh and blood."
	diet_flags = DIET_CARN | DIET_OMNI

/// Plant-based biomatter, digestable by herbivores and omnivores, worthless to carnivores
/datum/reagent/consumable/nutriment/plantmatter
	name = "Plant-matter"
	id = "plantmatter"
	description = "Vitamin-rich fibers and natural sugars commonly found in fresh produce."
	diet_flags = DIET_HERB | DIET_OMNI

/datum/reagent/consumable/nutriment/vitamin
	name = "Vitamin"
	id = "vitamin"
	description = "All the best vitamins, minerals, and carbohydrates the body needs in pure form."
	burn_heal = 1

/datum/reagent/consumable/nutriment/vitamin/on_mob_life(mob/living/M)
	if(M.satiety < 600)
		M.satiety += 30
	return ..()

/datum/reagent/consumable/sugar
	name = "Sugar"
	id = "sugar"
	description = "The organic compound commonly known as table sugar and sometimes called saccharose. This white, odorless, crystalline powder has a pleasing, sweet taste."
	color = "#FFFFFF" // rgb: 255, 255, 255
	nutriment_factor = 5 * REAGENTS_METABOLISM
	overdose_threshold = 200 // Hyperglycaemic shock
	taste_description = "sweetness"
	taste_mult = 1.5
	allowed_overdose_process = TRUE

/datum/reagent/consumable/sugar/on_mob_life(mob/living/M)
	var/update_flags = STATUS_UPDATE_NONE
	M.AdjustDrowsy(-10 SECONDS)
	if(current_cycle >= 90)
		M.AdjustJitter(4 SECONDS)
	if(prob(4))
		M.reagents.add_reagent("epinephrine", 1.2)
	return ..() | update_flags

/datum/reagent/consumable/sugar/overdose_start(mob/living/M)
	to_chat(M, "<span class='danger'>You pass out from hyperglycemic shock!</span>")
	M.emote("faint")
	..()

/datum/reagent/consumable/sugar/overdose_process(mob/living/M, severity)
	var/update_flags = STATUS_UPDATE_NONE
	M.Paralyse(6 SECONDS * severity)
	M.Weaken(8 SECONDS * severity)
	if(prob(8))
		update_flags |= M.adjustToxLoss(severity, FALSE)
	return list(0, update_flags)

/datum/reagent/consumable/soysauce
	name = "Soysauce"
	id = "soysauce"
	description = "A salty sauce made from the soy plant."
	reagent_state = LIQUID
	nutriment_factor = 2 * REAGENTS_METABOLISM
	color = "#792300" // rgb: 121, 35, 0
	taste_description = "soy"
	goal_department = "Kitchen"
	goal_difficulty = REAGENT_GOAL_NORMAL

/datum/reagent/consumable/ketchup
	name = "Ketchup"
	id = "ketchup"
	description = "Ketchup, catsup, whatever. It's tomato paste."
	reagent_state = LIQUID
	nutriment_factor = 5 * REAGENTS_METABOLISM
	color = "#731008" // rgb: 115, 16, 8
	taste_description = "ketchup"

/datum/reagent/consumable/mayonnaise
	name = "Mayonnaise"
	id = "mayonnaise"
	description = "A white and oily mixture of mixed egg yolks."
	reagent_state = LIQUID
	color = "#DFDFDF" // rgb: 223, 223, 223
	taste_description = "mayonnaise"
	goal_department = "Kitchen"
	goal_difficulty = REAGENT_GOAL_HARD

/datum/reagent/consumable/peanutbutter
	name = "Peanut Butter"
	id = "peanutbutter"
	description = "A rich, creamy spread made by grinding peanuts."
	reagent_state = LIQUID
	nutriment_factor = 5 * REAGENTS_METABOLISM
	color = "#D9A066" // rgb: 217, 160, 102
	taste_description = "peanuts"

/datum/reagent/consumable/bbqsauce
	name = "BBQ Sauce"
	id = "bbqsauce"
	description = "Sweet, smoky, savory, and gets everywhere. Perfect for grilling."
	nutriment_factor = 5 * REAGENTS_METABOLISM
	reagent_state = LIQUID
	color = "#78280A" // rbg: 120, 40, 10
	taste_mult = 2.5
	taste_description = "smokey sweetness"
	goal_department = "Kitchen"
	goal_difficulty = REAGENT_GOAL_NORMAL

/datum/reagent/consumable/capsaicin
	name = "Capsaicin Oil"
	id = "capsaicin"
	description = "This is what makes chilis hot."
	reagent_state = LIQUID
	color = "#B31008" // rgb: 179, 16, 8
	addiction_chance = 1
	addiction_chance_additional = 10
	addiction_threshold = 2
	minor_addiction = TRUE
	taste_description = "<span class='warning'>HOTNESS</span>"
	taste_mult = 1.5

/datum/reagent/consumable/capsaicin/on_mob_life(mob/living/M)
	switch(current_cycle)
		if(1 to 15)
			M.bodytemperature += 5 * TEMPERATURE_DAMAGE_COEFFICIENT
			if(holder.has_reagent("frostoil"))
				holder.remove_reagent("frostoil", 5)
			if(isslime(M))
				M.bodytemperature += rand(5,20)
		if(15 to 25)
			M.bodytemperature += 10 * TEMPERATURE_DAMAGE_COEFFICIENT
			if(isslime(M))
				M.bodytemperature += rand(10,20)
		if(25 to 35)
			M.bodytemperature += 15 * TEMPERATURE_DAMAGE_COEFFICIENT
			if(isslime(M))
				M.bodytemperature += rand(15,20)
		if(35 to INFINITY)
			M.bodytemperature += 20 * TEMPERATURE_DAMAGE_COEFFICIENT
			if(isslime(M))
				M.bodytemperature += rand(20,25)
	return ..()

/datum/reagent/consumable/condensedcapsaicin
	name = "Condensed Capsaicin"
	id = "condensedcapsaicin"
	description = "This shit goes in pepperspray."
	reagent_state = LIQUID
	color = "#B31008" // rgb: 179, 16, 8
	taste_description = "<span class='userdanger'>PURE FIRE</span>"

/datum/reagent/consumable/condensedcapsaicin/on_mob_life(mob/living/M)
	if(prob(5))
		M.visible_message("<span class='warning'>[M] [pick("dry heaves!","coughs!","splutters!")]</span>")
	return ..()

/datum/reagent/consumable/condensedcapsaicin/reaction_mob(mob/living/M, method=REAGENT_TOUCH, volume)
	if(method == REAGENT_TOUCH)
		if(ishuman(M))
			var/mob/living/carbon/human/victim = M
			var/mouth_covered = victim.is_mouth_covered()
			var/eyes_covered = victim.is_eyes_covered()

			if(!mouth_covered)
				victim.apply_status_effect(STATUS_EFFECT_PEPPERSPRAYED)

			if(!eyes_covered)
				to_chat(victim, "<span class='danger'>Your eyes burns!</span>")
				victim.Stun(0.5 SECONDS)
				victim.EyeBlurry(20 SECONDS)
				victim.EyeBlind(8 SECONDS)

/datum/reagent/consumable/frostoil
	name = "Frost Oil"
	id = "frostoil"
	description = "A special oil that noticably chills the body. Extraced from Icepeppers."
	reagent_state = LIQUID
	color = "#8BA6E9" // rgb: 139, 166, 233
	process_flags = ORGANIC | SYNTHETIC
	taste_description = "<span><font color='lightblue'>cold</font></span>"

/datum/reagent/consumable/frostoil/on_mob_life(mob/living/M)
	switch(current_cycle)
		if(1 to 15)
			M.bodytemperature -= 10 * TEMPERATURE_DAMAGE_COEFFICIENT
			if(holder.has_reagent("capsaicin"))
				holder.remove_reagent("capsaicin", 5)
			if(isslime(M))
				M.bodytemperature -= rand(5,20)
		if(15 to 25)
			M.bodytemperature -= 15 * TEMPERATURE_DAMAGE_COEFFICIENT
			if(isslime(M))
				M.bodytemperature -= rand(10,20)
		if(25 to 35)
			M.bodytemperature -= 20 * TEMPERATURE_DAMAGE_COEFFICIENT
			if(prob(1))
				M.emote("shiver")
			if(isslime(M))
				M.bodytemperature -= rand(15,20)
		if(35 to INFINITY)
			M.bodytemperature -= 20 * TEMPERATURE_DAMAGE_COEFFICIENT
			if(prob(1))
				M.emote("shiver")
			if(isslime(M))
				M.bodytemperature -= rand(20,25)
	return ..()

/datum/reagent/consumable/frostoil/reaction_turf(turf/T, volume)
	if(volume >= 5)
		for(var/mob/living/simple_animal/slime/M in T)
			M.adjustToxLoss(rand(15, 30))

/datum/reagent/consumable/sodiumchloride
	name = "Salt"
	id = "sodiumchloride"
	description = "Sodium chloride, common table salt."
	color = "#B1B0B0"
	harmless = FALSE
	overdose_threshold = 100
	taste_mult = 2
	taste_description = "salt"

/datum/reagent/consumable/sodiumchloride/overdose_process(mob/living/M, severity)
	var/update_flags = STATUS_UPDATE_NONE
	if(prob(70))
		update_flags |= M.adjustBrainLoss(1, FALSE)
	return ..() | update_flags

/datum/reagent/consumable/blackpepper
	name = "Black Pepper"
	id = "blackpepper"
	description = "A powder ground from peppercorns. *AAAACHOOO*"
	taste_description = "pepper"

/datum/reagent/consumable/cocoa
	name = "Cocoa Powder"
	id = "cocoa"
	description = "A fatty, bitter paste made from cocoa beans."
	nutriment_factor = 5 * REAGENTS_METABOLISM
	color = "#5F3A13"
	taste_description = "bitter cocoa"

/datum/reagent/consumable/vanilla
	name = "Vanilla"
	id = "vanilla"
	description = "A fatty, bitter paste made from vanilla pods."
	nutriment_factor = 5 * REAGENTS_METABOLISM
	color = "#FEFEFE"
	taste_description = "bitter vanilla"

/datum/reagent/consumable/garlic
	name = "Garlic Juice"
	id = "garlic"
	description = "Crushed garlic. Chefs love it, but it can make you smell bad."
	color = "#FEFEFE"
	taste_description = "garlic"
	metabolization_rate = 0.15 * REAGENTS_METABOLISM

/datum/reagent/consumable/garlic/on_mob_life(mob/living/carbon/M)
	var/update_flags = STATUS_UPDATE_NONE
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.job == "Chef" && prob(20)) //stays in the system much longer than sprinkles/banana juice, so heals slower to partially compensate
			update_flags |= H.adjustBruteLoss(-1, FALSE)
			update_flags |= H.adjustFireLoss(-1, FALSE)
	return ..() | update_flags

/datum/reagent/consumable/sprinkles
	name = "Sprinkles"
	id = "sprinkles"
	description = "Multi-colored little bits of sugar, commonly found on donuts. Loved by cops."
	color = "#FF00FF" // rgb: 255, 0, 255
	taste_description = "crunchy sweetness"

/datum/reagent/consumable/sprinkles/on_mob_life(mob/living/M)
	var/update_flags = STATUS_UPDATE_NONE
	if(ishuman(M) && (M.job in list("Security Officer", "Detective", "Warden", "Head of Security", "Internal Affairs Agent", "Magistrate")))
		update_flags |= M.adjustBruteLoss(-1, FALSE)
		update_flags |= M.adjustFireLoss(-1, FALSE)
	return ..() | update_flags

/datum/reagent/consumable/cornoil
	name = "Corn Oil"
	id = "cornoil"
	description = "An oil derived from various types of corn."
	reagent_state = LIQUID
	nutriment_factor = 20 * REAGENTS_METABOLISM
	color = "#302000" // rgb: 48, 32, 0
	taste_description = "oil"

/datum/reagent/consumable/olivepaste
	name = "Olive Paste"
	id = "olivepaste"
	description = "A mushy pile of freshly ground olives."
	reagent_state = LIQUID
	color = "#adcf77" //rgb: 173, 207, 119
	taste_description = "mushy olives"

/datum/reagent/consumable/oliveoil
	name = "Olive Oil"
	id = "oliveoil"
	description = "A high quality oil derived from olives. Suitable for dishes or mixtures requiring oil."
	reagent_state = LIQUID
	nutriment_factor = 10 * REAGENTS_METABOLISM
	color = "#DBCF5C" //rgb: 219, 207, 92
	taste_description = "olive oil"
	goal_department = "Kitchen"
	goal_difficulty = REAGENT_GOAL_NORMAL

/datum/reagent/consumable/cornoil/reaction_turf(turf/simulated/T, volume)
	if(!istype(T))
		return
	if(volume >= 3)
		T.MakeSlippery()
	T.quench(1000, 2)

/datum/reagent/consumable/enzyme
	name = "Universal Enzyme"
	id = "enzyme"
	description = "A special catalyst that makes certain culinary chemical reactions happen instantly instead of taking hours or days."
	reagent_state = LIQUID
	color = "#282314" // rgb: 54, 94, 48
	taste_description = "sweetness"
	goal_department = "Kitchen"
	goal_difficulty = REAGENT_GOAL_HARD

/datum/reagent/consumable/dry_ramen
	name = "Dry Ramen"
	id = "dry_ramen"
	description = "Space age food, since August 25, 1958. Contains dried noodles, vegetables, and chemicals that boil in contact with water."
	color = "#302000" // rgb: 48, 32, 0
	taste_description = "dry ramen coated with what might just be your tears"

/datum/reagent/consumable/hot_ramen
	name = "Hot Ramen"
	id = "hot_ramen"
	description = "The noodles are boiled, the flavors are artificial, just like being back in school."
	reagent_state = LIQUID
	nutriment_factor = 5 * REAGENTS_METABOLISM
	color = "#302000" // rgb: 48, 32, 0
	taste_description = "cheap ramen and memories"

/datum/reagent/consumable/hot_ramen/on_mob_life(mob/living/M)
	if(M.bodytemperature < 310)//310 is the normal bodytemp. 310.055
		M.bodytemperature = min(310, M.bodytemperature + (10 * TEMPERATURE_DAMAGE_COEFFICIENT))
	return ..()

/datum/reagent/consumable/hell_ramen
	name = "Hell Ramen"
	id = "hell_ramen"
	description = "The noodles are boiled, the flavors are artificial, just like being back in school...IN HELL"
	reagent_state = LIQUID
	nutriment_factor = 5 * REAGENTS_METABOLISM
	color = "#302000" // rgb: 48, 32, 0
	taste_description = "SPICY ramen"

/datum/reagent/consumable/hell_ramen/on_mob_life(mob/living/M)
	M.bodytemperature += 10 * TEMPERATURE_DAMAGE_COEFFICIENT
	return ..()

/datum/reagent/consumable/flour
	name = "Flour"
	id = "flour"
	description = "This is what you rub all over yourself to pretend to be a ghost."
	color = "#FFFFFF" // rgb: 0, 0, 0
	taste_description = "flour"

/datum/reagent/consumable/flour/reaction_turf(turf/T, volume)
	if(!isspaceturf(T))
		new /obj/effect/decal/cleanable/flour(T)

/datum/reagent/consumable/rice
	name = "Rice"
	id = "rice"
	description = "Enjoy the great taste of nothing."
	nutriment_factor = 3 * REAGENTS_METABOLISM
	color = "#FFFFFF" // rgb: 0, 0, 0
	taste_description = "rice"

/datum/reagent/consumable/cherryjelly
	name = "Cherry Jelly"
	id = "cherryjelly"
	description = "Totally the best. Only to be spread on foods with excellent lateral symmetry."
	reagent_state = LIQUID
	color = "#801E28" // rgb: 128, 30, 40
	taste_description = "cherry jelly"

/datum/reagent/consumable/bluecherryjelly
	name = "Blue Cherry Jelly"
	id = "bluecherryjelly"
	description = "Blue and tastier kind of cherry jelly."
	reagent_state = LIQUID
	color = "#00F0FF"
	taste_description = "the blues"

/datum/reagent/consumable/egg
	name = "Egg"
	id = "egg"
	description = "A runny and viscous mixture of clear and yellow fluids."
	reagent_state = LIQUID
	color = "#F0C814"
	taste_description = "eggs"

/datum/reagent/consumable/egg/on_mob_life(mob/living/M)
	if(prob(3))
		M.reagents.add_reagent("cholesterol", rand(1,2))
	return ..()

/datum/reagent/consumable/corn_starch
	name = "Corn Starch"
	id = "corn_starch"
	description = "The powdered starch of maize, derived from the kernel's endosperm. Used as a thickener for gravies and puddings."
	reagent_state = LIQUID
	color = "#ffeb91"
	taste_description = "flour"

/datum/reagent/consumable/corn_syrup
	name = "Corn Syrup"
	id = "corn_syrup"
	description = "A sweet syrup derived from corn starch that has had its starches converted into maltose and other sugars."
	reagent_state = LIQUID
	color = "#ada537"
	taste_description = "cheap sugar substitute"

/datum/reagent/consumable/corn_syrup/on_mob_life(mob/living/M)
	M.reagents.add_reagent("sugar", 1.2)
	return ..()

/datum/reagent/consumable/vhfcs
	name = "Very-high-fructose corn syrup"
	id = "vhfcs"
	description = "An incredibly sweet syrup, created from corn syrup treated with enzymes to convert its sugars into fructose."
	reagent_state = LIQUID
	color = "#484917"
	taste_description = "diabetes"

/datum/reagent/consumable/vhfcs/on_mob_life(mob/living/M)
	M.reagents.add_reagent("sugar", 2.4)
	return ..()

/datum/reagent/consumable/honey
	name = "Honey"
	id = "honey"
	description = "A sweet substance produced by bees through partial digestion. Bee barf."
	reagent_state = LIQUID
	color = "#d3a308"
	nutriment_factor = 15 * REAGENTS_METABOLISM
	taste_description = "sweetness"

/datum/reagent/consumable/honey/on_mob_life(mob/living/M)
	var/update_flags = STATUS_UPDATE_NONE
	M.reagents.add_reagent("sugar", 3)
	if(prob(20))
		update_flags |= M.adjustBruteLoss(-3, FALSE)
		update_flags |= M.adjustFireLoss(-1, FALSE)
	return ..() | update_flags

/datum/reagent/consumable/onion
	name = "Concentrated Onion Juice"
	id = "onionjuice"
	description = "A strong tasting substance that can induce partial blindness."
	color = "#c0c9a0"
	taste_description = "pungency"

/datum/reagent/consumable/onion/reaction_mob(mob/living/M, method = REAGENT_TOUCH, volume)
	if(method == REAGENT_TOUCH)
		if(!M.is_mouth_covered() && !M.is_eyes_covered())
			if(!M.get_organ_slot("eyes"))	//can't blind somebody with no eyes
				to_chat(M, "<span class = 'notice'>Your eye sockets feel wet.</span>")
			else
				if(!M.AmountEyeBlurry())
					to_chat(M, "<span class = 'warning'>Tears well up in your eyes!</span>")
				M.EyeBlind(4 SECONDS)
				M.EyeBlurry(10 SECONDS)
	..()

/datum/reagent/consumable/chocolate
	name = "Chocolate"
	id = "chocolate"
	description = "Chocolate is a delightful product derived from the seeds of the theobroma cacao tree."
	reagent_state = LIQUID
	nutriment_factor = 5 * REAGENTS_METABOLISM		//same as pure cocoa powder, because it makes no sense that chocolate won't fill you up and make you fat
	color = "#2E2418"
	drink_icon = "chocolateglass"
	drink_name = "Glass of chocolate"
	drink_desc = "Tasty!"
	taste_description = "chocolate"

/datum/reagent/consumable/chocolate/on_mob_life(mob/living/M)
	M.reagents.add_reagent("sugar", 0.8)
	return ..()

/datum/reagent/consumable/chocolate/reaction_turf(turf/T, volume)
	if(volume >= 5 && !isspaceturf(T))
		new /obj/item/food/choc_pile(T)

/datum/reagent/consumable/mugwort
	name = "Mugwort"
	id = "mugwort"
	description = "A rather bitter herb once thought to hold magical protective properties."
	reagent_state = LIQUID
	color = "#21170E"
	process_flags = ORGANIC | SYNTHETIC
	taste_description = "tea"

/datum/reagent/consumable/mugwort/on_mob_life(mob/living/M)
	var/update_flags = STATUS_UPDATE_NONE
	if(ishuman(M) && M.mind?.special_role == SPECIAL_ROLE_WIZARD)
		update_flags |= M.adjustToxLoss(-1 * REAGENTS_EFFECT_MULTIPLIER, FALSE)
		update_flags |= M.adjustOxyLoss(-1 * REAGENTS_EFFECT_MULTIPLIER, FALSE)
		update_flags |= M.adjustBruteLoss(-1 * REAGENTS_EFFECT_MULTIPLIER, FALSE)
		update_flags |= M.adjustFireLoss(-1 * REAGENTS_EFFECT_MULTIPLIER, FALSE)
		for(var/datum/reagent/R in M.reagents.reagent_list)
			if(!R.harmless)
				M.reagents.remove_reagent(R.id, 5) // purge those meme chems
	return ..() | update_flags

/datum/reagent/consumable/porktonium
	name = "Porktonium"
	id = "porktonium"
	description = "A highly-radioactive pork byproduct first discovered in hotdogs."
	reagent_state = LIQUID
	color = "#AB5D5D"
	metabolization_rate = 0.2
	overdose_threshold = 133
	harmless = FALSE
	taste_description = "bacon"

/datum/reagent/consumable/porktonium/overdose_process(mob/living/M, severity)
	if(prob(15))
		M.reagents.add_reagent("cholesterol", rand(1,3))
	if(prob(8))
		M.reagents.add_reagent("radium", 15)
		M.reagents.add_reagent("cyanide", 10)
	return list(0, STATUS_UPDATE_NONE)

/datum/reagent/consumable/chicken_soup
	name = "Chicken soup"
	id = "chicken_soup"
	description = "An old household remedy for mild illnesses."
	reagent_state = LIQUID
	color = "#B4B400"
	metabolization_rate = 0.2
	nutriment_factor = 2.5 * REAGENTS_METABOLISM
	taste_description = "broth"

/datum/reagent/consumable/cheese
	name = "Cheese"
	id = "cheese"
	description = "Some cheese. Pour it out to make it solid."
	color = "#FFFF00"
	taste_description = "cheese"

/datum/reagent/consumable/cheese/on_mob_life(mob/living/M)
	if(prob(3))
		M.reagents.add_reagent("cholesterol", rand(1,2))
	return ..()

/datum/reagent/consumable/cheese/reaction_turf(turf/T, volume)
	if(volume >= 5 && !isspaceturf(T))
		new /obj/item/food/sliced/cheesewedge(T)

/datum/reagent/consumable/fake_cheese
	name = "Cheese substitute"
	id = "fake_cheese"
	description = "A cheese-like substance derived loosely from actual cheese."
	reagent_state = LIQUID
	color = "#B2B139"
	overdose_threshold = 50
	addiction_chance = 2
	addiction_chance_additional = 10
	addiction_threshold = 5
	minor_addiction = TRUE
	harmless = FALSE
	taste_description = "cheese?"

/datum/reagent/consumable/fake_cheese/overdose_process(mob/living/M, severity)
	var/update_flags = STATUS_UPDATE_NONE
	if(prob(8))
		to_chat(M, "<span class='warning'>You feel something squirming in your stomach. Your thoughts turn to cheese and you begin to sweat.</span>")
		update_flags |= M.adjustToxLoss(rand(1,2), FALSE)
	return list(0, update_flags)

/datum/reagent/consumable/weird_cheese
	name = "Weird cheese"
	id = "weird_cheese"
	description = "Hell, I don't even know if this IS cheese. Whatever it is, it ain't normal. If you want to, pour it out to make it solid."
	color = "#50FF00"
	addiction_chance = 1
	addiction_chance_additional = 10
	addiction_threshold = 5
	minor_addiction = TRUE
	taste_description = "cheeeeeese...?"

/datum/reagent/consumable/weird_cheese/on_mob_life(mob/living/M)
	if(prob(5))
		M.reagents.add_reagent("cholesterol", rand(1,3))
	return ..()

/datum/reagent/consumable/weird_cheese/reaction_turf(turf/T, volume)
	if(volume >= 5 && !isspaceturf(T))
		new /obj/item/food/weirdcheesewedge(T)

/datum/reagent/consumable/cheese_curds
	name = "Cheese Curds"
	id = "cheese_curds"
	description = "Some mushed up cheese curds. You're not quite sure why you did this."
	color = "#FFFF00"
	taste_description = "salty cheese"

/datum/reagent/consumable/yogurt
	name = "yogurt"
	id = "yogurt"
	description = "Some yogurt, produced by bacterial fermentation of milk. Yum."
	reagent_state = LIQUID
	color = "#FFFFFF"
	taste_description = "yogurt"

/datum/reagent/consumable/beans
	name = "Refried beans"
	id = "beans"
	description = "A dish made of mashed beans cooked with lard."
	reagent_state = LIQUID
	color = "#684435"
	taste_description = "burritos"

/datum/reagent/consumable/bread
	name = "Bread"
	id = "bread"
	description = "Bread! Yep, bread."
	color = "#9C5013"
	taste_description = "bread"

/datum/reagent/consumable/soybeanoil
	name = "Space-soybean oil"
	id = "soybeanoil"
	description = "An oil derived from extra-terrestrial soybeans."
	reagent_state = LIQUID
	color = "#B1B0B0"
	taste_description = "oil"

/datum/reagent/consumable/soybeanoil/on_mob_life(mob/living/M)
	if(prob(10))
		M.reagents.add_reagent("cholesterol", rand(1,3))
	if(prob(8))
		M.reagents.add_reagent("porktonium", 5)
	return ..()

/datum/reagent/consumable/hydrogenated_soybeanoil
	name = "Partially hydrogenated space-soybean oil"
	id = "hydrogenated_soybeanoil"
	description = "An oil derived from extra-terrestrial soybeans, with additional hydrogen atoms added to convert it into a saturated form."
	reagent_state = LIQUID
	color = "#B1B0B0"
	metabolization_rate = 0.2
	overdose_threshold = 75
	harmless = FALSE
	taste_description = "oil"
	allowed_overdose_process = TRUE

/datum/reagent/consumable/hydrogenated_soybeanoil/on_mob_life(mob/living/M)
	if(prob(15))
		M.reagents.add_reagent("cholesterol", rand(1,3))
	if(prob(8))
		M.reagents.add_reagent("porktonium", 5)
	if(volume >= 75)
		metabolization_rate = 0.4
	else
		metabolization_rate = 0.2
	return ..()

/datum/reagent/consumable/hydrogenated_soybeanoil/overdose_process(mob/living/M, severity)
	var/update_flags = STATUS_UPDATE_NONE
	if(prob(33))
		to_chat(M, "<span class='warning'>You feel horribly weak.</span>")
	if(prob(10))
		to_chat(M, "<span class='warning'>You cannot breathe!</span>")
		update_flags |= M.adjustOxyLoss(5, FALSE)
	if(prob(5))
		to_chat(M, "<span class='warning'>You feel a sharp pain in your chest!</span>")
		update_flags |= M.adjustOxyLoss(25, FALSE)
		M.Stun(10 SECONDS)
		M.Paralyse(20 SECONDS)
	return list(0, update_flags)

/datum/reagent/consumable/meatslurry
	name = "Meat Slurry"
	id = "meatslurry"
	description = "A paste comprised of highly-processed organic material. Uncomfortably similar to deviled ham spread."
	reagent_state = LIQUID
	color = "#EBD7D7"
	taste_description = "meat?"

/datum/reagent/consumable/meatslurry/on_mob_life(mob/living/M)
	if(prob(4))
		M.reagents.add_reagent("cholesterol", rand(1,3))
	return ..()

/datum/reagent/consumable/meatslurry/reaction_turf(turf/T, volume)
	if(prob(10) && volume >= 5 && !isspaceturf(T))
		new /obj/effect/decal/cleanable/blood/gibs/cleangibs(T)
		playsound(T, 'sound/effects/splat.ogg', 50, TRUE, -3)

/datum/reagent/consumable/mashedpotatoes
	name = "Mashed potatoes"
	id = "mashedpotatoes"
	description = "A starchy food paste made from boiled potatoes."
	color = "#D6D9C1"
	taste_description = "potatoes"

/datum/reagent/consumable/gravy
	name = "Gravy"
	id = "gravy"
	description = "A savory sauce made from a simple meat-dripping roux and milk."
	reagent_state = LIQUID
	color = "#B4641B"
	taste_description = "gravy"
	goal_department = "Kitchen"
	goal_difficulty = REAGENT_GOAL_NORMAL

/datum/reagent/consumable/wasabi
	name = "Wasabi"
	id = "wasabi"
	description = "A pungent green paste often served with sushi. Consuming too much causes an uncomfortable burning sensation in the nostrils."
	reagent_state = LIQUID
	color = "#80942F"
	taste_description = "pungency"

/datum/reagent/consumable/wasabi/reaction_mob(mob/living/M, method=REAGENT_TOUCH, volume)
	if(method == REAGENT_INGEST)
		if(volume <= 1)
			to_chat(M, "<span class='notice'>Your nostrils tingle briefly.</span>")
		else
			to_chat(M, "<span class='warning'>Your nostrils burn uncomfortably!</span>")
			M.adjustFireLoss(1)

///Food Related, but non-nutritious

/// food poisoning
/datum/reagent/questionmark
	name = "????"
	id = "????"
	description = "A gross and unidentifiable substance."
	reagent_state = LIQUID
	color = "#63DE63"
	taste_description = "burned food"

/datum/reagent/questionmark/reaction_mob(mob/living/carbon/human/H, method = REAGENT_TOUCH, volume)
	if(istype(H) && method == REAGENT_INGEST)
		if(H.dna.species.taste_sensitivity < TASTE_SENSITIVITY_NO_TASTE) // If you can taste it, then you know how awful it is.
			to_chat(H, "<span class='danger'>Ugh! Eating that was a terrible idea!</span>")
			if(!H.HasDisease(/datum/disease/food_poisoning))
				H.fakevomit(no_text = TRUE)
		if(HAS_TRAIT(H, TRAIT_NOHUNGER)) //If you don't eat, then you can't get food poisoning
			return
		H.ForceContractDisease(new /datum/disease/food_poisoning(0))

/datum/reagent/msg
	name = "Monosodium glutamate"
	id = "msg"
	description = "Monosodium Glutamate is a sodium salt known chiefly for its use as a controversial flavor enhancer."
	reagent_state = LIQUID
	color = "#F5F5F5"
	metabolization_rate = 0.2
	taste_description = "excellent cuisine"
	taste_mult = 4

/datum/reagent/msg/on_mob_life(mob/living/M)
	var/update_flags = STATUS_UPDATE_NONE
	if(prob(5))
		if(prob(10))
			update_flags |= M.adjustToxLoss(rand(2,4), FALSE)
		if(prob(7))
			to_chat(M, "<span class='warning'>A horrible migraine overpowers you.</span>")
			M.Stun(rand(4 SECONDS, 10 SECONDS))
	return ..() | update_flags

/datum/reagent/cholesterol
	name = "Cholesterol"
	id = "cholesterol"
	description = "Pure cholesterol. Probably not very good for you."
	reagent_state = LIQUID
	color = "#FFFAC8"
	taste_description = "heart attack"

/datum/reagent/cholesterol/on_mob_life(mob/living/M)
	var/update_flags = STATUS_UPDATE_NONE
	if(volume >= 25 && prob(volume*0.15))
		to_chat(M, "<span class='warning'>Your chest feels [pick("weird","uncomfortable","nasty","gross","odd","unusual","warm")]!</span>")
		update_flags |= M.adjustToxLoss(rand(1,2), FALSE)
	else if(volume >= 45 && prob(volume*0.08))
		to_chat(M, "<span class='warning'>Your chest [pick("hurts","stings","aches","burns")]!</span>")
		update_flags |= M.adjustToxLoss(rand(2,4), FALSE)
		M.Stun(2 SECONDS)
	else if(volume >= 150 && prob(volume*0.01))
		to_chat(M, "<span class='warning'>Your chest is burning with pain!</span>")
		M.Weaken(2 SECONDS)
		M.ForceContractDisease(new /datum/disease/critical/heart_failure(0))
	return ..() | update_flags

/datum/reagent/fungus
	name = "Space fungus"
	id = "fungus"
	description = "Scrapings of some unknown fungus found growing on the station walls."
	reagent_state = LIQUID
	color = "#C87D28"
	taste_description = "mold"

/datum/reagent/fungus/reaction_mob(mob/living/M, method=REAGENT_TOUCH, volume)
	if(method == REAGENT_INGEST)
		var/ranchance = rand(1,10)
		if(ranchance == 1)
			to_chat(M, "<span class='warning'>You feel very sick.</span>")
			M.reagents.add_reagent("toxin", rand(1,5))
		else if(ranchance <= 5)
			to_chat(M, "<span class='warning'>That tasted absolutely FOUL.</span>")
			M.ForceContractDisease(new /datum/disease/food_poisoning(0))
		else
			to_chat(M, "<span class='warning'>Yuck!</span>")

/datum/reagent/ectoplasm
	name = "Ectoplasm"
	id = "ectoplasm"
	description = "A bizarre gelatinous substance supposedly derived from ghosts."
	reagent_state = LIQUID
	color = "#8EAE7B"
	process_flags = ORGANIC | SYNTHETIC		//Because apparently ghosts in the shell
	taste_description = "spooks"

/datum/reagent/ectoplasm/on_mob_life(mob/living/M)
	var/spooky_message = pick("You notice something moving out of the corner of your eye, but nothing is there...", "Your eyes twitch, you feel like something you can't see is here...", "You've got the heebie-jeebies.", "You feel uneasy.", "You shudder as if cold...", "You feel something gliding across your back...")
	if(prob(8))
		to_chat(M, "<span class='warning'>[spooky_message]</span>")
	return ..()

/datum/reagent/ectoplasm/reaction_mob(mob/living/M, method=REAGENT_TOUCH, volume)
	if(method == REAGENT_INGEST)
		M.reagents.add_reagent("sodiumchloride", rand(10, 20))	// The salt!
		var/spooky_eat = pick("A wave of seething anger briefly passes over you!", "This is all bullshit!", "You internally seethe and mald.", "You briefly see a dense halo of spirits taunting you!")
		to_chat(M, "<span class='warning'>[spooky_eat]</span>")

/datum/reagent/ectoplasm/reaction_turf(turf/T, volume)
	if(volume >= 10 && !isspaceturf(T))
		new /obj/item/food/ectoplasm(T)

/datum/reagent/consumable/bread/reaction_turf(turf/T, volume)
	if(volume >= 5 && !isspaceturf(T))
		new /obj/item/food/sliced/bread(T)

/datum/reagent/soap
	name = "Soap"
	id = "soapreagent"
	description = "Soap, fit to clean the mouth of a sailor."
	color = "#FFFFFF"
	taste_description = "soap"

/datum/reagent/soap/on_mob_add(mob/living/L)
	ADD_TRAIT(L, TRAIT_SOAPY_MOUTH, id)

/datum/reagent/soap/on_mob_delete(mob/living/L)
	REMOVE_TRAIT(L, TRAIT_SOAPY_MOUTH, id)

		///Vomit///

/datum/reagent/vomit
	name = "Vomit"
	id = "vomit"
	description = "Looks like someone lost their lunch. And then collected it. Yuck."
	reagent_state = LIQUID
	color = "#FFFF00"
	taste_description = "puke"

/datum/reagent/vomit/reaction_turf(turf/T, volume)
	if(volume >= 5 && !isspaceturf(T))
		T.add_vomit_floor()

/datum/reagent/greenvomit
	name = "Green vomit"
	id = "green_vomit"
	description = "Whoa, that can't be natural. That's horrible."
	reagent_state = LIQUID
	color = "#78FF74"
	taste_description = "puke"

/datum/reagent/greenvomit/reaction_turf(turf/T, volume)
	if(volume >= 5 && !isspaceturf(T))
		T.add_vomit_floor(FALSE, TRUE)

////Lavaland Flora Reagents////

/datum/reagent/consumable/entpoly
	name = "Entropic Polypnium"
	id = "entpoly"
	description = "An ichor, derived from a certain mushroom, makes for a bad time."
	color = "#1d043d"
	taste_description = "bitter mushroom"

/datum/reagent/consumable/entpoly/on_mob_life(mob/living/M)
	var/update_flags = STATUS_UPDATE_NONE
	if(current_cycle >= 10)
		M.Paralyse(4 SECONDS)
	if(prob(20))
		M.LoseBreath(8 SECONDS)
		update_flags |= M.adjustBrainLoss(2 * REAGENTS_EFFECT_MULTIPLIER, FALSE)
		update_flags |= M.adjustToxLoss(3 * REAGENTS_EFFECT_MULTIPLIER, FALSE)
		update_flags |= M.adjustStaminaLoss(10 * REAGENTS_EFFECT_MULTIPLIER, FALSE)
		M.EyeBlurry(10 SECONDS)
	return ..() | update_flags

/datum/reagent/consumable/tinlux
	name = "Tinea Luxor"
	id = "tinlux"
	description = "A stimulating ichor which causes luminescent fungi to grow on the skin. "
	color = "#b5a213"
	var/light_activated = FALSE
	taste_description = "tingling mushroom"

/datum/reagent/consumable/tinlux/on_mob_life(mob/living/M)
	if(!light_activated)
		M.set_light(2)
		light_activated = TRUE
	return ..()

/datum/reagent/consumable/tinlux/on_mob_delete(mob/living/M)
	M.set_light(0)

/datum/reagent/consumable/vitfro
	name = "Vitrium Froth"
	id = "vitfro"
	description = "A bubbly paste that heals wounds of the skin."
	color = "#d3a308"
	nutriment_factor = 3 * REAGENTS_METABOLISM
	taste_description = "fruity mushroom"

/datum/reagent/consumable/vitfro/on_mob_life(mob/living/M)
	var/update_flags = STATUS_UPDATE_NONE
	if(prob(80))
		update_flags |= M.adjustBruteLoss(-1 * REAGENTS_EFFECT_MULTIPLIER, FALSE)
		update_flags |= M.adjustFireLoss(-1 * REAGENTS_EFFECT_MULTIPLIER, FALSE)
	return ..() | update_flags

/datum/reagent/consumable/mint
	name = "Mint"
	id = "mint"
	description = "A light green liquid extracted from mint leaves."
	reagent_state = LIQUID
	color = "#A7EE9F"
	taste_description = "mint"

/datum/reagent/consumable/vinegar
	name = "Vinegar"
	id = "vinegar"
	description = "Useful for pickling, or putting on chips."
	taste_description = "vinegar"
	color = "#ffffff"
	goal_department = "Kitchen"
	goal_difficulty = REAGENT_GOAL_NORMAL
