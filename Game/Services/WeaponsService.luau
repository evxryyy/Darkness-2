local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Zone = require(ReplicatedStorage.Packages.Zone)
local WeaponsComponent = require(ServerScriptService.Game.Utils.WeaponsComponent)

local module = Knit.CreateService({
	Name = "WeaponsService";
	Client = {
		WeaponsDamageAnimation = Knit.CreateSignal();
		MagnecticBlastRaySignal = Knit.CreateSignal();
		BeastKilledPlayerSignal = Knit.CreateSignal();
		NVBatteryClaimedSignal = Knit.CreateSignal();
		ClaimDroppedWeapons = Knit.CreateSignal();
	};
	InitComponents = {};
	stats = {};
})


function module:ConstructUserWeapon(player,ref)
	if(not ref and not player) then return end
	if(self.InitComponents[player.Name]) then return end
	local character = player.Character or player.CharacterAdded:Wait()
	if(ref == "survivor") then
		local findProfile = Knit.GetService("ProfileStoreService"):GetProfile(player)
		local weapon = WeaponsComponent:LoadWeapon(character)
		local data = {}
		if(findProfile) then
			if(findProfile.Data.Products.health) then
				data["health_item"] = WeaponsComponent:LoadHeathItem()
				data["weapon"] = weapon
				self.InitComponents[player.Name] = data
				findProfile.Data.Products.health = nil
			else
				self.InitComponents[player.Name] = weapon
			end
		else
			self.InitComponents[player.Name] = weapon
		end
		return self.InitComponents[player.Name]
	elseif(ref == "juggernaut") then
		local findProfile = Knit.GetService("ProfileStoreService"):GetProfile(player)
		local data = {
			["pistol"] = WeaponsComponent:LoadWeapon(character);
			["random_art"] = WeaponsComponent:GetRandomWeapon(character);
			["health_item"] = WeaponsComponent:LoadHeathItem();
			["FF Unit"] = ServerStorage.Weapons["FF Unit"].Name
		}
		self.InitComponents[player.Name] = data
		return self.InitComponents[player.Name]	
	elseif(ref == "beast") then
		local scythe = WeaponsComponent:GetScythe()
		self.InitComponents[player.Name] = scythe
		return self.InitComponents[player.Name]
	end
end

function module:SetParent(player,parent)
	if(not player) then return end
	if(not self.InitComponents[player.Name]) then return end
	if(not parent) then parent = player.Backpack end
	local data = self.InitComponents[player.Name]
	if(type(data) == "table") then
		for j,weapon in pairs(data) do
			local search_packages = nil
			if(ServerStorage.Weapons:FindFirstChild(weapon)) then
				search_packages = ServerStorage.Weapons
			elseif(ServerStorage.Resources:FindFirstChild(weapon)) then
				search_packages = ServerStorage.Resources
			end
			local clone = search_packages:FindFirstChild(weapon):Clone()
			clone.Parent = parent
			self.InitComponents[player.Name][j] = clone
		end
	else
		local search_packages = nil
		if(ServerStorage.Weapons:FindFirstChild(data)) then
			search_packages = ServerStorage.Weapons
		elseif(ServerStorage.Resources:FindFirstChild(data)) then
			search_packages = ServerStorage.Resources
		end
		local clone = search_packages:FindFirstChild(data):Clone()
		clone.Parent = parent
		self.InitComponents[player.Name] = clone
	end
	return self.InitComponents[player.Name]
end

function module:copyWeaponStats(player)
	if(not player) then return end
	if(not self.stats[player]) then
		self.stats[player] = WeaponsComponent.WeaponsStats
		if(table.isfrozen(self.stats[player])) then
			return self.stats[player]
		else
			return table.freeze(self.stats[player])
		end
	else
		if(table.isfrozen(self.stats[player])) then
			return self.stats[player]
		else
			return table.freeze(self.stats[player])
		end
	end
end

function module:GetRaycast(player, posA, posB, weapon_name)
	if not player then return end
	if not posA or not posB then return end
	if not weapon_name then return end

	local GameService = Knit.GetService("GameService")

	if weapon_name == "Scythe" then
		-- Play sound at position
		local function play_sound_at_position()
			local copyWeaponHandle = ServerStorage.Resources.Scythe.Handle:Clone()
			copyWeaponHandle.Parent = workspace
			copyWeaponHandle.Position = posA
			copyWeaponHandle.Anchored = true
			copyWeaponHandle.Transparency = 1
			copyWeaponHandle.CanCollide = false
			local play_sound = copyWeaponHandle.Swing
			play_sound:Play()
			Debris:AddItem(copyWeaponHandle, 0.7)
		end

		play_sound_at_position()

		-- Raycast logic
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Blacklist
		overlapParams.FilterDescendantsInstances = player.Character:GetChildren()
		local RaycastResult = WeaponsComponent:RaycastHitbox(posA, overlapParams)

		if not RaycastResult then return end

		if RaycastResult.Instance then
			if RaycastResult.Instance.Parent:FindFirstChild("Shield") then
				local getCurrentShieldHealth = RaycastResult.Instance.Parent:FindFirstChild("Shield"):GetAttribute("ShieldHealth")
				if(not getCurrentShieldHealth) then return end
				RaycastResult.Instance.Parent:FindFirstChild("Shield"):SetAttribute("ShieldHealth",getCurrentShieldHealth-25)
				return
			end

			local billboard_clone = ServerStorage.Resources.DamageSign:Clone()
			billboard_clone.Parent = RaycastResult.Instance.Parent:FindFirstChild("Head")
			local label = WeaponsComponent:SetDamageLabel(
				WeaponsComponent.WeaponsStats.AbilityWeapon.Scythe.Damage,
				billboard_clone
			)
			self.Client.WeaponsDamageAnimation:Fire(player, label)
			Debris:AddItem(billboard_clone, 3)

			if RaycastResult.Instance.Health <= 0 then
				return
			end

			RaycastResult.Instance:TakeDamage(WeaponsComponent.WeaponsStats.AbilityWeapon.Scythe.Damage)
			GameService:UpdatePlayerProfile(player, { damage = WeaponsComponent.WeaponsStats.AbilityWeapon.Scythe.Damage })

			if RaycastResult.Instance.Health <= 0 then
				self.Client.BeastKilledPlayerSignal:Fire(player)
			end
		end
	elseif weapon_name == "FF Unit" then
		-- Create the shield
		local ball = Instance.new("Part", player.Character)
		ball.Shape = "Ball"
		ball.Anchored = false
		ball.CanCollide = false
		ball.Size = Vector3.new(8, 8, 8)
		ball.Color = Color3.fromRGB(0, 255, 255)
		ball.Transparency = 0.7
		ball.TopSurface = "Smooth"
		ball.Name = "Shield"
		ball.BottomSurface = "Smooth"
		ball.CFrame = player.Character.Head.CFrame * CFrame.new(0, -0.2, 0)

		-- Attach the shield to the player
		local weld = Instance.new("WeldConstraint", ball)
		weld.Part0 = player.Character.Head
		weld.Part1 = ball

		-- Add health to the shield
		ball:SetAttribute("ShieldHealth", WeaponsComponent.WeaponsStats["FF Unit"].ShieldHealth)

		-- Add a visual indicator for the shield
		local shieldSign = ServerStorage.Resources.ShieldSign:Clone()
		shieldSign.Parent = player.Character.Head

		--Zone data
		local mkZone = Zone.new(ball)
		mkZone.playerEntered:Connect(function(player)
			if(not player) then return end
			local character = player.Character or player.CharacterAdded:Wait()
			if(not character) then return end
			if(character:FindFirstChild("mode_selector")) then
				local currentHealth = ball:GetAttribute("ShieldHealth")
				if(currentHealth) then
					currentHealth -= 0 -- Adjust this value for damage dealt
					ball:SetAttribute("ShieldHealth", currentHealth)
					if(currentHealth < 0) then
						ball:Destroy()
						shieldSign:Destroy()
					end
					if(ball) then
						ball.Transparency = 0.4
						task.delay(.3,function()
							ball.Transparency = 0.2
						end)
					end
				end
			end
		end)

		-- Remove FF Unit from inventory after activation
		local inventory = player.Backpack
		local ffUnit = inventory:FindFirstChild("FF Unit")
		if(ffUnit) then
			ffUnit:Destroy() -- Remove the FF Unit from the backpack
		else
			local ffunit = player.Character:FindFirstChild("FF Unit")
			ffunit:Destroy()
		end
	else -- NORMAL WEAPONS RAYCAST HERE DONT DELETED PLEASE !
		-- Play sound at position
		local function play_sound_at_position()
			local copyWeaponHandle = ServerStorage.Weapons:FindFirstChild(weapon_name).Handle:Clone()
			copyWeaponHandle.Parent = workspace
			copyWeaponHandle.Position = posA
			copyWeaponHandle.Anchored = true
			copyWeaponHandle.Transparency = 1
			copyWeaponHandle.CanCollide = false
			local play_sound = copyWeaponHandle.Fire
			play_sound:Play()
			Debris:AddItem(copyWeaponHandle, 0.7)
		end

		play_sound_at_position()

		-- Raycast logic
		local overlapParams = RaycastParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Blacklist
		overlapParams.FilterDescendantsInstances = player.Character:GetChildren()
		local RaycastResult = WeaponsComponent:Raycast(posA,posB, overlapParams)
		if(RaycastResult) then
			if(RaycastResult.Instance.Parent:FindFirstChild("Humanoid") and RaycastResult.Instance.Parent:FindFirstChild("mode_selector")) then
				local humanoid = RaycastResult.Instance.Parent:FindFirstChild("Humanoid")
				if(not humanoid) then return end
				if(humanoid.Health <= 0) then return end
				
				local humanoidRootPart = RaycastResult.Instance.Parent:FindFirstChild("HumanoidRootPart")
				local label = WeaponsComponent:SetDamageLabel(
					WeaponsComponent:GetWeaponDamage(weapon_name),
					RaycastResult.Instance.Parent:FindFirstChild("Head"):FindFirstChildOfClass("BillboardGui")
				)
				self.Client.WeaponsDamageAnimation:FireAll(label)
				RaycastResult.Instance.Parent:FindFirstChildOfClass("Humanoid"):TakeDamage(WeaponsComponent:GetWeaponDamage(weapon_name))	
				GameService:UpdatePlayerProfile(player,{damage = WeaponsComponent:GetWeaponDamage(weapon_name)})
			end
		end	
	
	end
end



function module:MagnecticBlastAbility(player,posA,posB)
	if(not player) then return end
	if(not posA or not posB) then return end
	local GameService = Knit.GetService("GameService")
	local params = RaycastParams.new()
	local blackListInstance = {}
	for i,character_part in pairs(player.Character:GetChildren()) do
		if(character_part:IsA("BasePart")) then
			table.insert(blackListInstance,character_part)
		end
	end
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = blackListInstance
	local part = Instance.new("Part",workspace)
	part.Shape = Enum.PartType.Block
	part.Color = Color3.fromRGB(85, 170, 0)
	part.Material = "Neon"
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Size = Vector3.new(1,1,1)
	part.FrontSurface = Enum.SurfaceType.Hinge
	part.CFrame = player.Character:FindFirstChild("HumanoidRootPart").RootAttachment.WorldCFrame * CFrame.new(0,0,-150)
	local ray,intersection,distance = WeaponsComponent:Raycast(
		player.Character:FindFirstChild("HumanoidRootPart").Position,
		part.Position,
		params
	)
	if(ray) then
		local function play_sound_at_position()
			local copyWeaponHandle = ServerStorage.Resources.Scythe.Handle:Clone()
			copyWeaponHandle.Parent = workspace
			copyWeaponHandle.Position = posA
			copyWeaponHandle.Anchored = true
			copyWeaponHandle.Transparency = 1
			copyWeaponHandle.CanCollide = false
			local play_sound = copyWeaponHandle.Beam
			play_sound:Play()
			Debris:AddItem(copyWeaponHandle,2)
		end
		play_sound_at_position()
		part:Destroy()
		if(ray.Instance.Parent:FindFirstChild("Humanoid") and ray.Instance.Parent:FindFirstChild("mode_selector") == nil) then
			if(ray.Instance.Parent:FindFirstChild("Shield")) then
				local getCurrentShieldHealth = ray.Instance.Parent:FindFirstChild("Shield"):GetAttribute("ShieldHealth")
				if(not getCurrentShieldHealth) then return end
				ray.Instance.Parent:FindFirstChild("Shield"):SetAttribute("ShieldHealth",getCurrentShieldHealth-25)
				return
			end
			local billboard_clone = ServerStorage.Resources.DamageSign:Clone()
			billboard_clone.Parent = ray.Instance.Parent:FindFirstChild("Head")
			local label = WeaponsComponent:SetDamageLabel(
				WeaponsComponent.WeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.Damage,
				billboard_clone
			)
			self.Client.WeaponsDamageAnimation:Fire(player,label)
			Debris:AddItem(billboard_clone,3)
			if(ray.Instance.Parent:FindFirstChild("Humanoid").Health <= 0) then
				return
			end
			ray.Instance.Parent:FindFirstChild("Humanoid"):TakeDamage(WeaponsComponent.WeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.Damage)
			GameService:UpdatePlayerProfile(player,{damage = WeaponsComponent.WeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.Damage})
			if(ray.Instance.Parent:FindFirstChild("Humanoid").Health <= 0) then
				self.Client.BeastKilledPlayerSignal:Fire(player)
			end	
		end
		self.Client.MagnecticBlastRaySignal:FireAll({origin = player.Character:FindFirstChild("HumanoidRootPart").Position,interpolation = intersection,direction = distance})
	end
end

function module:DaggersRaycastAbility(player,posA,posB)
	if(not player) then return end
	if(not posA or not posB) then return end
	local GameService = Knit.GetService("GameService")
	local params = RaycastParams.new()
	local blackListInstance = {}
	for i,character_part in pairs(player.Character:GetChildren()) do
		if(character_part:IsA("BasePart")) then
			table.insert(blackListInstance,character_part)
		end
	end
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = blackListInstance
	local part = Instance.new("Part",workspace)
	part.Shape = Enum.PartType.Block
	part.Color = Color3.fromRGB(85, 170, 0)
	part.Material = "Neon"
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Size = Vector3.new(1,1,1)
	part.FrontSurface = Enum.SurfaceType.Hinge
	part.CFrame = player.Character:FindFirstChild("HumanoidRootPart").RootAttachment.WorldCFrame * CFrame.new(0,0,-150)
	local ray,intersection,distance = WeaponsComponent:Raycast(
		player.Character:FindFirstChild("HumanoidRootPart").Position,
		part.Position,
		params
	)
	if(ray) then
		local function play_sound_at_position()
			local copyWeaponHandle = ServerStorage.Resources.Scythe.Handle:Clone()
			copyWeaponHandle.Parent = workspace
			copyWeaponHandle.Position = posA
			copyWeaponHandle.Anchored = true
			copyWeaponHandle.Transparency = 1
			copyWeaponHandle.CanCollide = false
			local play_sound = copyWeaponHandle.Dagger
			play_sound:Play()
			Debris:AddItem(copyWeaponHandle,0.7)
		end
		play_sound_at_position()
		part:Destroy()
		if(ray.Instance.Parent:FindFirstChild("Humanoid") and ray.Instance.Parent:FindFirstChild("mode_selector") == nil) then
			if(ray.Instance.Parent:FindFirstChild("Shield")) then
				local getCurrentShieldHealth = ray.Instance.Parent:FindFirstChild("Shield"):GetAttribute("ShieldHealth")
				if(not getCurrentShieldHealth) then return end
				ray.Instance.Parent:FindFirstChild("Shield"):SetAttribute("ShieldHealth",getCurrentShieldHealth-25)
				return
			end
			local billboard_clone = ServerStorage.Resources.DamageSign:Clone()
			billboard_clone.Parent = ray.Instance.Parent:FindFirstChild("Head")
			local label = WeaponsComponent:SetDamageLabel(
				WeaponsComponent.WeaponsStats.AbilityWeapon.Scythe.Daggers.Damage,
				billboard_clone
			)
			self.Client.WeaponsDamageAnimation:Fire(player,label)
			Debris:AddItem(billboard_clone,3)
			if(ray.Instance.Parent:FindFirstChild("Humanoid").Health <= 0) then
				return
			end	
			ray.Instance.Parent:FindFirstChild("Humanoid"):TakeDamage(WeaponsComponent.WeaponsStats.AbilityWeapon.Scythe.Daggers.Damage)
			GameService:UpdatePlayerProfile(player,{damage = WeaponsComponent.WeaponsStats.AbilityWeapon.Scythe.Daggers.Damage})
			if(ray.Instance.Parent:FindFirstChild("Humanoid").Health <= 0) then
				self.Client.BeastKilledPlayerSignal:Fire(player)
			end	
		end
	end
end

function module:DestroyPlayerComponent(player)
	if(not player) then return end
	if(not self.InitComponents[player.Name]) then return end
	if(#player.Backpack:GetChildren() > 0) then
		for i,tool in pairs(player.Backpack:GetChildren()) do
			if(tool) then
				tool:Destroy()
			end
		end
	else
		for i,tool in pairs(player.Character:GetChildren()) do
			if(tool:IsA("Tool")) then
				tool:Destroy()
			end
		end
	end
	if(type(self.InitComponents[player.Name]) == "table") then
		table.clear(self.InitComponents[player.Name])
	end
	self.InitComponents[player.Name] = nil
	return true
end

function module:CloneDaggers(player)
	if(not player) then return end
	local daggers = ServerStorage.Resources.Daggers:Clone()
	daggers.Parent = player.Backpack
	return daggers
end

function module:RemoveDaggers(player)
	if(not player) then return end
	local daggers = player.Backpack:FindFirstChild("Daggers")
	if(not daggers) then
		if(player.Character:FindFirstChild("Daggers")) then
			player.Character:FindFirstChild("Daggers"):Destroy()
		end
		return true
	else
		daggers:Destroy()
		return true
	end
end

function module.Client:CloneDaggers(player)
	return self.Server:CloneDaggers(player)
end

function module.Client:RemoveDaggers(player)
	return self.Server:RemoveDaggers(player)
end

function module.Client:DaggersRaycastAbility(player,posA,posB)
	return self.Server:DaggersRaycastAbility(player,posA,posB)
end

function module.Client:DestroyPlayerComponent(player)
	return self.Server:DestroyPlayerComponent(player)
end

function module.Client:MagnecticBlastAbility(player,posA,posB)
	return self.Server:MagnecticBlastAbility(player,posA,posB)
end

function module.Client:copyWeaponStats(player)
	return self.Server:copyWeaponStats(player)
end

function module.Client:GetRaycast(player,posA,posB,weapon_name)
	return self.Server:GetRaycast(player,posA,posB,weapon_name)
end

function module.Client:SetParent(player,parent)
	return self.Server:SetParent(player,parent)
end

function module.Client:ConstructUserWeapon(player,ref)
	return self.Server:ConstructUserWeapon(player,ref)
end

return module
