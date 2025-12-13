
//BeanieStation13 Redux

//Plus a bobble hat, lets be inclusive!!

/// Default is white, this is meant to be seen
/obj/item/clothing/head/beanie
	name = "white beanie"
	desc = "A stylish beanie. The perfect winter accessory for those with a keen fashion sense, and those who just can't handle a cold breeze on their heads."
	icon_state = "beanie" //Default white
	icon_monitor = 'icons/mob/clothing/species/machine/monitor/hat.dmi'
	sprite_sheets = list(
		"Vox" = 'icons/mob/clothing/species/vox/head.dmi',
		)
	dyeable = TRUE
	dyeing_key = DYE_REGISTRY_BEANIE

// Sprite sheet needed to keep the beanie from being white in the vendor even when colored
/datum/asset/spritesheet/beanie
	name = "beanie"
	var/obj/item/clothing/head/beanie/current_typepath

/datum/asset/spritesheet/beanie/create_spritesheets()
	// The first sprite we insert is a blank 32x32 icon. This means that when we
	// generate class names for icon state/direction combinations that don't
	// exist, the ones with non-existent class names will instead just point to the
	// first image on the sheet.
	Insert("blank", 'icons/obj/clothing/hats.dmi', "blank")
	for(var/obj/item/clothing/head/beanie/beanie_type in subtypesof(/obj/item/clothing/head/beanie))
		current_typepath = beanie_type
		var/beanie_classname = replace_characters("[beanie_type.name]", list(" " = "_"))
		if(beanie_type::icon_state == "")
			continue
		Insert(
			"[beanie_classname]",
			beanie_type::icon,
			beanie_type::icon_state,
		)

/datum/asset/spritesheet/beanie/ModifyInserted(icon/pre_asset)
	var/icon/parent = ..()
	if(current_typepath && current_typepath::color)
		parent.Blend(current_typepath::color, ICON_MULTIPLY)
	return parent

/obj/item/clothing/head/beanie/black
	name = "black beanie"
	color = "#4A4A4B" //Grey but it looks black

/obj/item/clothing/head/beanie/red
	name = "red beanie"
	color = "#D91414" //Red

/obj/item/clothing/head/beanie/green
	name = "green beanie"
	color = "#5C9E54" //Green

/obj/item/clothing/head/beanie/darkblue
	name = "dark blue beanie"
	color = "#1E85BC" //Blue

/obj/item/clothing/head/beanie/purple
	name = "purple beanie"
	color = "#9557C5" //purple

/obj/item/clothing/head/beanie/yellow
	name = "yellow beanie"
	color = "#E0C14F" //Yellow

/obj/item/clothing/head/beanie/orange
	name = "orange beanie"
	color = "#C67A4B" //orange

/obj/item/clothing/head/beanie/cyan
	name = "cyan beanie"
	color = "#54A3CE" //Cyan (Or close to it)

//Striped Beanies have unique sprites

/obj/item/clothing/head/beanie/christmas
	name = "christmas beanie"
	icon_state = "beaniechristmas"

/obj/item/clothing/head/beanie/striped
	name = "striped beanie"
	icon_state = "beaniestriped"

/obj/item/clothing/head/beanie/stripedred
	name = "red striped beanie"
	icon_state = "beaniestripedred"

/obj/item/clothing/head/beanie/stripedblue
	name = "blue striped beanie"
	icon_state = "beaniestripedblue"

/obj/item/clothing/head/beanie/stripedgreen
	name = "green striped beanie"
	icon_state = "beaniestripedgreen"

/obj/item/clothing/head/beanie/durathread
	name = "durathread beanie"
	desc = "A beanie made from durathread, its resilient fibres provide some protection to the wearer."
	icon_state = "beaniedurathread"
	armor = list(MELEE = 10, BULLET = 5, LASER = 10, ENERGY = 5, BOMB = 5, RAD = 0, FIRE = 20, ACID = 5)

/obj/item/clothing/head/beanie/waldo
	name = "red striped bobble hat"
	desc = "If you're going on a worldwide hike, you'll need some cold protection."
	icon_state = "waldo_hat"

/obj/item/clothing/head/beanie/rasta
	name = "rastacap"
	desc = "Perfect for tucking in those dreadlocks."
	icon_state = "beanierasta"
