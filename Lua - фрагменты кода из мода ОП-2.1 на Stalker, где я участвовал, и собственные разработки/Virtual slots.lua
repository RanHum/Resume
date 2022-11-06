-- Ranhum: virtual slots handler
local real_slot_choice = inventory_slots.RIFLE
function virtual_slots(slot)
	if not game_is_running() then return end
	local slots = container:get("virtual_slots", {})
	if has_info("ui_inventory") then -- Memorizing
		if alt_state then -- Reset slots by Alt
			log("Reset virtual slots!")
			container:set("virtual_slots", {})
			return
		elseif shift_state then -- Choosing slot by Shift
			local choices = {inventory_slots.KNIFE, inventory_slots.PISTOL, inventory_slots.SHOTGUN, inventory_slots.RIFLE}
			real_slot_choice = choices[slot]
			log("Real slot "..real_slot_choice.." was chosen for memorizing!")
			return
		end
		local current_obj = db.actor:item_in_slot(real_slot_choice)
		if not current_obj then
			log("There is no weapon in real slot "..real_slot_choice.." to memorize! Move something here beforehand!")
			return
		end
		slots[slot] = {["slot_id"] = real_slot_choice, ["id"] = current_obj:id()}
		log("Memorized "..current_obj:section().." in real slot "..real_slot_choice.." as virtual slot "..slot)
		container:set("virtual_slots", slots)
		real_slot_choice = inventory_slots.RIFLE
	else -- Switching
		if not slots[slot] then
			log("No memorized weapon for virtual slot "..slot.." yet!")
			return
		end
		local current_obj = db.actor:item_in_slot(slots[slot].slot_id)
		if not current_obj or current_obj:id() ~= slots[slot].id then -- Different or no weapon in target slot - switch
			local target_obj = level_object(slots[slot].id)
			if not (target_obj and target_obj:parent() and target_obj:parent():id() == db.actor:id()) then
				log("Can't find requested weapon id for virtual slot "..slot.." in inventory! Real slot was "..slots[slot].slot_id)
				return
			end
			-- log("Activating virtual slot "..slot.." with "..slots[slot].id.." in real slot "..slots[slot].slot_id)
			db.actor:inventory_move_item(target_obj, slots[slot].slot_id, true)
		elseif current_obj and current_obj:id() == slots[slot].id and db.actor:active_slot() == slots[slot].slot_id then -- Same weapon is in target slot and active - hide weapon
			db.actor:activate_slot(inventory_slots.NO_ACT_SLOT)
			return
		end
		db.actor:activate_slot(slots[slot].slot_id)
	end
end