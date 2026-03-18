// PDA apps don't seem to support ui_static_data so we do a bunch of back and
// forth filtering the recipes by category on the BYOND side
/datum/data/pda/app/cookbook
	name = "Recipe Book"
	title = "Chef's Guide to the Galaxy"
	template = "pda_cookbook"
	// Almost positive this is never used anywhere but sure
	update = PDA_APP_NOUPDATE

	var/current_category
	var/list/recipe_list = list()
	var/list/ingredients_list = list()
	var/list/recipe_list_cookable = list()
	var/search_text = ""

/datum/data/pda/app/cookbook/New()
	..()
	for(var/ingredient in GLOB.pcwj_cookbook_by_ingredient)
		ingredients_list[ingredient] = 0

/datum/data/pda/app/cookbook/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui.set_autoupdate(FALSE)

/datum/data/pda/app/cookbook/update_ui(mob/user, list/data)
	data["categories"] = list()
	for(var/category in GLOB.pcwj_cookbook_lookup)
		data["categories"] += category

	data["recipes"] = recipe_list
	data["cookable_recipes"] = recipe_list_cookable
	data["current_category"] = current_category
	data["search_text"] = search_text
	data["ingredients"] = ingredients_list

	return data

/datum/data/pda/app/cookbook/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return

	switch(action)
		if("set_category")
			current_category = params["name"]
			search_text = params["search_text"]
			recipe_list = isnull(current_category) ? list() : GLOB.pcwj_cookbook_lookup[current_category]
			SStgui.update_uis(pda)
		if("change_ingredient_amount")
			update_ingredient(params["ingredient"], params["new_amount"])
			SStgui.update_uis(pda)
		if("make_recipe")
			follow_recipe(params["recipe"])
			SStgui.update_uis(pda)

/// Gets the recipe for making an ingredient
/datum/data/pda/app/cookbook/proc/get_recipe_for_ingredient(ingredient)
	for(var/list/entry in GLOB.pcwj_cookbook_lookup["All"])
		if(entry["name"] == ingredient)
			return entry["datum"]
	return FALSE

/// Changes the amount of an ingredient we have in our app list, and returns a list of recipes that should be checked against the new value.
/datum/data/pda/app/cookbook/proc/update_ingredient(ingredient, new_amount, relative = FALSE, update_now = TRUE)
	if(relative)
		ingredients_list[ingredient] += new_amount
	else
		ingredients_list[ingredient] = new_amount ? new_amount : 0

	if(!update_now)
		return GLOB.pcwj_cookbook_by_ingredient[ingredient]
	for(var/recipe in GLOB.pcwj_cookbook_by_ingredient[ingredient])
		check_recipe_cookability(recipe)
	SStgui.update_uis(pda)

/// Follows the steps of a recipe to
/datum/data/pda/app/cookbook/proc/follow_recipe(datum/cooking/recipe/recipe)
	var/list/recipes_to_update = list()
	for(var/datum/cooking/recipe_step/step in recipe.steps)
		if(istype(step, /datum/cooking/recipe_step/add_item))
			var/datum/cooking/recipe_step/add_item/add_step = step
			recipes_to_update += update_ingredient(add_step.item_type::name, -1, relative = TRUE, update_now = FALSE)
		else if(istype(step, /datum/cooking/recipe_step/add_produce))
			var/datum/cooking/recipe_step/add_produce/add_step = step
			recipes_to_update += update_ingredient(add_step.produce_type::name, -1, relative = TRUE, update_now = FALSE)
		else if(istype(step, /datum/cooking/recipe_step/add_reagent))
			var/datum/cooking/recipe_step/add_reagent/add_step = step
			var/datum/reagent/reagent = GLOB.chemical_reagents_list[add_step.reagent_id]
			recipes_to_update += update_ingredient(reagent::name, -(add_step.amount), relative = TRUE, update_now = FALSE)

	uniqueList_inplace(recipes_to_update)
	for(var/each_recipe in recipes_to_update)
		if(check_recipe_cookability(each_recipe))
			recipe_list_cookable |= each_recipe
		else
			recipe_list_cookable.Remove(each_recipe)
	SStgui.update_uis(pda)

/// Fakes following a recipe for the purpose of checking cookable recipes that might have ingredient conflicts
/datum/data/pda/app/cookbook/proc/simulate_follow_recipe(datum/cooking/recipe/recipe, ingredients_possessed, multiplier = 1)
	for(var/datum/cooking/recipe_step/step in recipe.steps)
		if(istype(step, /datum/cooking/recipe_step/add_item))
			var/datum/cooking/recipe_step/add_item/add_step = step
			ingredients_possessed[add_step.item_type::name] -= multiplier
		else if(istype(step, /datum/cooking/recipe_step/add_produce))
			var/datum/cooking/recipe_step/add_produce/add_step = step
			ingredients_possessed[add_step.produce_type::name] -= multiplier
		else if(istype(step, /datum/cooking/recipe_step/add_reagent))
			var/datum/cooking/recipe_step/add_reagent/add_step = step
			var/datum/reagent/reagent = GLOB.chemical_reagents_list[add_step.reagent_id]
			ingredients_possessed[reagent::name] -= add_step.amount * multiplier

	return ingredients_possessed

/// Checks if you can cook a recipe with ingredients that you have.
/datum/data/pda/app/cookbook/proc/check_recipe_cookability(datum/cooking/recipe/recipe, list/ingredients_possessed = null, multiplier = 1)
	if(!ingredients_possessed)
		ingredients_possessed = ingredients_list.Copy()
	var/list/ingredients_needed = list()

	// discover all the ingredients we need by going through recipe steps
	for(var/datum/cooking/recipe_step/step in recipe.steps)
		var/ingredient_name = ""
		var/ingredient_amount = multiplier

		if(istype(step, /datum/cooking/recipe_step/add_item))
			var/datum/cooking/recipe_step/add_item/add_step = step
			ingredient_name = add_step.item_type::name

		else if(istype(step, /datum/cooking/recipe_step/add_produce))
			var/datum/cooking/recipe_step/add_produce/add_step = step
			ingredient_name = add_step.produce_type::name

		else if(istype(step, /datum/cooking/recipe_step/add_reagent))
			var/datum/cooking/recipe_step/add_reagent/add_step = step
			var/datum/reagent/reagent = GLOB.chemical_reagents_list[add_step.reagent_id]
			ingredient_name = reagent::name
			ingredient_amount = add_step.amount * multiplier

		// not an ingredient, skip it
		else
			continue

		// add each identified ingredient to the list of ones we need
		if(!(ingredient_name in ingredients_needed))
			ingredients_needed[ingredient_name] = 0
		ingredients_needed[ingredient_name] += ingredient_amount

	// compare each ingredient to our ingredient stores
	for(var/ingredient in ingredients_needed)
		// we don't have the ingredient exactly
		if(ingredients_possessed[ingredient] < ingredients_needed[ingredient])
			// check if there's a recipe for the ingredient
			var/datum/cooking/recipe/ingredient_recipe = get_recipe_for_ingredient(ingredient)
			// if there isn't, we can't make it.
			if(!ingredient_recipe)
				qdel(ingredients_possessed)
				return FALSE
			// how many times we'd need to make the ingredient recipe to make up the difference
			var/ingredient_multiplier = ceil(multiplier / (ingredient_recipe.reagent_amount ? ingredient_recipe.reagent_amount : ingredient_recipe.product_count)) - ingredients_possessed[ingredient]
			if(ingredient_multiplier < 1)
				message_admins("Got an invalid ingredient multiplier [ingredient_multiplier] when trying to check cookability of [ingredient_recipe] for [multiplier] [recipe].")
			// if the number of times we can make the ingredient recipe plus the ingredients we have doesn't make the grade, we can't make this
			if(!check_recipe_cookability(ingredient_recipe, ingredients_possessed, ingredient_multiplier))
				qdel(ingredients_possessed)
				return FALSE
			ingredients_possessed = simulate_follow_recipe(ingredient_recipe, ingredients_possessed, ingredient_multiplier)
			ingredients_possessed[ingredient] = 0
		// we do have the ingredient and we're using it now
		else
			ingredients_possessed[ingredient] -= ingredients_needed[ingredient]
	return TRUE