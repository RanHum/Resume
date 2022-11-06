-- by Ranhum, with help from safe_ArtefactInformer.script
function artefacts_to_csv()
	local values = {"inv_weight", "cost", "burn_immunity", "strike_immunity", "shock_immunity", "wound_immunity", "radiation_immunity", "telepatic_immunity", "chemical_burn_immunity", "explosion_immunity", "fire_wound_immunity"}
	--таблицы соотношения восстановления параметров арта к параметрам актора
	local artefactRestoreParams={
		[0]="health_restore_speed",
		[1]="radiation_restore_speed",
		[2]="satiety_restore_speed",
		[3]="power_restore_speed",
		[4]="bleeding_restore_speed",
		[5]="additional_weight",
		[6]="inventory_radiation"
	}
	--таблица параметров восстановления актора 
	local actorRestoreParams={
		[0]="satiety_health_v",
		[1]="radiation_v",
		[2]="satiety_v",
		[3]="satiety_power_v",
		[4]="wound_incarnation_v",
		[6]="radiation_v"
	}
	local actorParams={}
	local conditionSection=config:r_string("actor","condition_sect")
	for i,section in pairs(actorRestoreParams) do
		actorParams[i]=config:r_string(conditionSection,section)
	end
	local RestoreFunctions={
		[0]=function (artVal,actorVal) --health_restore_speed satiety_health_v
				return math.round((artVal/actorVal)*100)
			end,
		[1]=function (artVal,actorVal) --radiation_restore_speed radiation_v
				return math.modf(math.round(artVal/actorVal))
			end,
		[2]=function (artVal,actorVal) --satiety_restore_speed satiety_v
				return math.round((artVal/actorVal)*100)
			end,
		[3]=function (artVal,actorVal) --power_restore_speed satiety_power_v
				return math.modf(math.round(artVal/actorVal))
			end,
		[4]=function (artVal,actorVal) --bleeding_restore_speed wound_incarnation_v
				return math.modf(math.round((artVal/actorVal)*-100))
			end,
		[5]=function (artVal,actorVal) --additional_weight
				return artVal
			end,
		[6]=function (artVal,actorVal) --inventory_radiation
				return math.round(tonumber(artVal)/actorVal,2)
			end
	}
	local delim = ";"
	local fs = getFS()
	local arts_config=ini_file([[defines.ltx]])
	arts_config:include_file([[misc\artefacts.ltx]])
	arts_config:include_file([[misc\artefacts_amkzp.ltx]])
	local csv = fs:w_open("Artefacts.csv")
	-- Headers
	local headers = "Section;Inventory Name"
	for _, header in pairs(values) do
		headers = headers..delim..header
	end
	for _, header in pairs(artefactRestoreParams) do
		headers = headers..delim..header
	end
	csv:w_string(headers)
	-- arts
	arts_config:iterate_sections(function(ini_obj,section)
		if arts_config:line_exist(section,"class") then
			local class_value=arts_config:r_string(section,"class")
			if string.sub(section, 1, 3) == "af_" then
				-- Common
				local row = section..delim..translate(config:r_string(section, "inv_name"))
				-- Values
				for _, value in pairs(values) do
					row = row..delim
					if string.find(value, "immunity") then
						prot = tonumber(config:r_string(config:r_string(section, "hit_absorbation_sect"), value))
						row = row..math.round(100-prot*100)
					elseif config:line_exist(section, value) then
						row = row..config:r_string(section, value)
					end
				end
				for i, value in pairs(artefactRestoreParams) do
					row = row..delim
					if config:line_exist(section,value) then
						param = tonumber(config:r_string(section, value))
						row = row..RestoreFunctions[i](param, actorParams[i])
					end
				end
				csv:w_string(row)
			end
		end
	end)
	fs:w_close(csv)
end

-- by Ranhum
function outfits_to_csv()
	local values = {"inv_weight", "cost", "additional_inventory_weight", "additional_inventory_weight2", "burn_protection", "strike_protection", "shock_protection", "wound_protection", "radiation_protection", "telepatic_protection", "chemical_burn_protection", "explosion_protection", "fire_wound_protection", "discharge_moving", "discharge_sprint", "discharge_jump"}
	local delim = ";"
	local fs = getFS()
	local outfits_config=ini_file([[defines.ltx]])
	outfits_config:include_file([[misc\outfit.ltx]])
	local csv = fs:w_open("Outfits.csv")
	-- Headers
	local headers = "Section;Inventory Name"
	for _, header in pairs(values) do
		headers = headers..delim..header
	end
	csv:w_string(headers)
	-- Outfits
	outfits_config:iterate_sections(function(ini_obj,section)
		if outfits_config:line_exist(section,"class") then
			local class_value=outfits_config:r_string(section,"class")
			if class_value == "EQU_EXO" or class_value == "E_STLK" and config:line_exist(section, "inv_name") then
				-- Common
				local row = section..delim..translate(config:r_string(section, "inv_name"))
				-- Values
				for _, value in pairs(values) do
					row = row..delim
					if config:line_exist(section, value) then
						if string.find(value, "protection") then
							row = row..math.round(tonumber(config:r_string(section, value))*100)
						else
							row = row..config:r_string(section, value)
						end
					end
				end
				csv:w_string(row)
			end
		end
	end)
	fs:w_close(csv)
end

-- by Ranhum, with help from armor_manager.script
-- v2
function weapons_to_csv()
	local weapon_types = {
		["Пистолеты, Винтовки, Автоматы, Дробовики"] = {
			["WP_AK74"]=true,
			["WP_BINOC"]=true,
			["WP_BM16"]=true,
			["WP_GROZA"]=true,
			["WP_HPSA"]=true,
			["WP_LR300"]=true,
			["WP_PM"]=true,
			["WP_SHOTG"]=true,
			["WP_SVD"]=true,
			["WP_SVU"]=true,
			["WP_USP45"]=true,
			["WP_VAL"]=true,
			["WP_VINT"]=true,
			["WP_WALTH"]=true
		}
		-- , ["Гранатометы"] = {
			-- ["WP_RG6"]=true,
			-- ["WP_RPG7"]=true,
		-- }, ["Ножи"] = {
			-- ["WP_KNIFE"]=true
		-- }, ["Гранаты"] = {
			-- ["G_F1"]=true,
			-- ["G_RGD5"]=true,
			-- ["G_RPG7"]=true,
			-- ["G_FAKE"]=true
			-- ["A_OG7B"]=true,
			-- ["A_M209"]=true,
			-- ["A_VOG25"]=true
		-- }
	}
	local values = {"slot", "inv_weight", "cost", "ammo_class", "grenade_class", "ammo_mag_size", "fire_modes", "fire_dispersion_base", "condition_shot_dec", "hit_power", "C_hit_1", "C_disp_1", "C_disp_1_scope", "C_hit_2", "C_disp_2", "C_disp_2_scope", "C_hit_3", "C_disp_3", "C_disp_3_scope", "C_hit_4", "C_disp_4", "C_disp_4_scope", "C_hit_5", "C_disp_5", "C_disp_5_scope", "bullet_speed", "silencer_hit_power", "silencer_bullet_speed", "rpm"}
	local addons = {"scope", "silencer", "grenade_launcher"}
	local delim = ";"

	local get = function(section, param)
		if config:line_exist(section, param) then
			return config:r_float(section, param)
		end
		return 1
	end

	local ammos_sorted = function (section)
		ammos = string.explode(config:r_string(section, "ammo_class"), ",", true)
		table.sort(ammos, function (a1,a2)
				return get(a1, "k_hit")*config:r_u32(a1, "buck_shot") < get(a2, "k_hit")*config:r_u32(a2, "buck_shot")
		end)
		return ammos
	end

	local fs = getFS()
	local weapons_config=ini_file([[defines.ltx]])
	weapons_config:include_file([[weapons\weapons.ltx]])
	for typename, clsid in pairs(weapon_types) do
		local csv = fs:w_open(typename..".csv")
		-- Headers
		local headers = "Section;Inventory Name"
		for _, header in pairs(values) do
			headers = headers..delim..header
		end
		for _, header in pairs(addons) do
			headers = headers..delim..header
		end
		csv:w_string(headers)
		-- Weapons
		weapons_config:iterate_sections(function(ini_obj,section)
			if section:sub(1,4) == "wpn_" and weapons_config:line_exist(section,"class") then
				local class_value=weapons_config:r_string(section,"class")
				if clsid[class_value] then
					-- Common
					local row = section..delim..translate(config:r_string(section, "inv_name"))
					-- Values
					for _, value in pairs(values) do
						row = row..delim
						if value:sub(1,2) == "C_" then -- Calculated values
							if string.find(value, "hit") then
								local ammos = ammos_sorted(section)
								local needed = tonumber(value:sub(7,7))
								if needed <= #ammos then
									local ammo = ammos[needed]
									row = row..math.round(get(ammo, "k_hit")*get(section, "hit_power")*config:r_u32(ammo, "buck_shot"), 2)
								end
							elseif string.find(value, "disp") then
								local ammos = ammos_sorted(section)
								local needed = tonumber(value:sub(8,8))
								if needed <= #ammos then
									local ammo = ammos[needed]
									local disp = get(section, "fire_dispersion_base")*get(ammo, "k_disp")
									if string.find(value, "scope") then
										disp = disp + get("actor", "disp_aim")
									else
										disp = disp + get("actor", "disp_base")*get(section, "PDM_disp_base")
									end
									row = row..math.round(disp, 4)
								end
							end
						elseif value == "ammo_class" then -- always sorting our ammos
							row = row..table.concat(ammos_sorted(section), ", ")
						else -- Native values
							if config:line_exist(section, value) then
								row = row..config:r_string(section, value)
							end
						end
					end
					-- Addons translated
					for _, addon in pairs(addons) do
						row = row..delim..weapon_addon(section, addon)
					end
					csv:w_string(row)
				end
			end
		end)
		fs:w_close(csv)
	end
end

-- slightly modified from descriptors.script
function weapon_addon(section, addon_name)
	local zoom = {
		[100] = 1,
		[93] = 1.2,
		[75] = 1.5,
		[70] = 1.6,
		[65] = 1.8,
		[56] = 2,
		[45] = 2.5,
		[37] = 3,
		[32] = 3.5,
		[28] = 4,
		[25] = 4.5,
		[22] = 5,
		[20] = 5.5,
		[18] = 6,
		[16] = 7,
		[14] = 8,
		[12] = 9,
		[11] = 10,
		[10] = 11,
		[9] = 12,
		[8] = 14,
		[7] = 16,
		[6] = 18,
		[5] = 22
	}
	local addon = config:r_u32(section, addon_name.."_status")
	local txt = ""

	if addon == 1 then		-- интегрированный
		txt = txt..translate("ui_integrated").." "..translate(addon_name)
		
		if addon_name == "scope" then
			local zoom_factor = config:r_u32(section, "scope_zoom_factor")
			txt = txt..(zoom[zoom_factor] and " "..zoom[zoom_factor].."x" or "")
		end

	elseif addon == 2 then	-- съемный
		--txt = txt.."\\n Х "..translate("ui_"..addon_name).." "..translate(config:r_string(config:r_string(section, addon_name.."_name"), "inv_name"))
		txt = txt..translate(config:r_string(config:r_string(section, addon_name.."_name"), "inv_name"))
	end

	return txt
end