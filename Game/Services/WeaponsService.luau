local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)
local WeaponsComponent = require(ServerScriptService.Game.Utils.WeaponsComponent)

local module = Knit.CreateService({
	Name = "WeaponsService";
	Client = {
		WeaponsDamageAnimation = Knit.CreateSignal();
		MagnecticBlastRaySignal = Knit.CreateSignal();
		BeastKilledPlayerSignal = Knit.CreateSignal();
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
			["random_art"] = WeaponsComponent:GetRandomWeapon(character)
		}
		if(findProfile) then
			if(findProfile.Data.Products.health) then
				data["health_item"] = WeaponsComponent:LoadHeathItem()
				findProfile.Data.Products.health = nil
			end
		end
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

function module:GetRaycast(player,posA,posB,weapon_name)
	if(not player) then return end
	if(not posA or not posB) then return end
	if(not weapon_name) then return end
	local GameService = Knit.GetService("GameService")
	if(weapon_name == "Scythe") then
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Blacklist
		overlapParams.FilterDescendantsInstances = player.Character:GetChildren()
		local RaycastResult = WeaponsComponent:RaycastHitbox(posA,posB,overlapParams)
		if(not RaycastResult) then return end
		if(RaycastResult.Instance) then
			local billboard_clone = ServerStorage.Resources.DamageSign:Clone()
			billboard_clone.Parent = RaycastResult.Instance.Parent:FindFirstChild("Head")
			local label = WeaponsComponent:SetDamageLabel(
				WeaponsComponent.WeaponsStats.AbilityWeapon.Scythe.Damage,
				billboard_clone
			)
			self.Client.WeaponsDamageAnimation:Fire(player,label)
			Debris:AddItem(billboard_clone,3)
			RaycastResult.Instance:TakeDamage(WeaponsComponent.WeaponsStats.AbilityWeapon.Scythe.Damage)
			GameService:UpdatePlayerProfile(player,{damage = WeaponsComponent.WeaponsStats.AbilityWeapon.Scythe.Damage})
			if(RaycastResult.Instance.Health <= 0) then
				self.Client.BeastKilledPlayerSignal:Fire(player)
			end	
		end
	else
		local Raycast,Intersection,Distance = WeaponsComponent:Raycast(posA,posB)
		if(Raycast) then
			local hit = Raycast.Instance
			if(hit.Parent:FindFirstChildOfClass("Humanoid") and hit.Parent:FindFirstChild("mode_selector")) then
				local humanoidRootPart = hit.Parent:FindFirstChild("HumanoidRootPart")
				local label = WeaponsComponent:SetDamageLabel(
					WeaponsComponent:GetWeaponDamage(weapon_name),
					hit.Parent:FindFirstChild("Head"):FindFirstChildOfClass("BillboardGui")
				)
				self.Client.WeaponsDamageAnimation:FireAll(label)
				hit.Parent:FindFirstChildOfClass("Humanoid"):TakeDamage(WeaponsComponent:GetWeaponDamage(weapon_name))	
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
		part:Destroy()
		if(ray.Instance.Parent:FindFirstChild("Humanoid") and ray.Instance.Parent:FindFirstChild("mode_selector") == nil) then
			local billboard_clone = ServerStorage.Resources.DamageSign:Clone()
			billboard_clone.Parent = ray.Instance.Parent:FindFirstChild("Head")
			local label = WeaponsComponent:SetDamageLabel(
				WeaponsComponent.WeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.Damage,
				billboard_clone
			)
			self.Client.WeaponsDamageAnimation:Fire(player,label)
			Debris:AddItem(billboard_clone,3)
			ray.Instance.Parent:FindFirstChild("Humanoid"):TakeDamage(WeaponsComponent.WeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.Damage)
			GameService:UpdatePlayerProfile(player,{damage = WeaponsComponent.WeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.Damage})
		end
		self.Client.MagnecticBlastRaySignal:FireAll({origin = player.Character:FindFirstChild("HumanoidRootPart").Position,interpolation = intersection,direction = distance})
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
