local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)

local module = {}
module.__index = module

module.WeaponsStats = {
	["A. Rifle"] = {ReloadTime = 1.75,MaxAmmo = 18,Ammo = 18,Rate = 0.25,Reloading = false};
	["FF Unit"] = {ShieldHealth = 150,ShieldCooldown = 65};
	["FirstAid"] = {HealthGiven = 75,HealthCooldown = 30};
	["Hyperlaser"] = {ReloadTime = 1.95,MaxAmmo = 5,Ammo = 5,Rate = 1,Reloading = false};
	["Laser rifle"] = {ReloadTime = 1.55,MaxAmmo = 18,Ammo = 18,Rate = 0.25,Reloading = false};
	["MAC-10"] = {ReloadTime = 0.5,MaxAmmo = 12,Ammo = 12,Rate = 0.2,Reloading = false};
	["Pistol"] = {ReloadTime = 0.75,MaxAmmo = 10,Ammo = 10,Rate = 0.15,Reloading = false};
	["Pistol2MORE"] = {ReloadTime = 0.75,MaxAmmo = 12,Ammo = 12,Rate = 0.15,Reloading = false};
	["Revolver"] = {ReloadTime = 1.2,MaxAmmo = 7,Ammo = 7,Rate = 0.75,Reloading = false};
	["S. FirstAid"] = {HealthGiven = 75,HealthCooldown = 35};
	["Shotgun"] = {ReloadTime = 2,MaxAmmo = 5,Ammo = 5,Rate = 0.95,Reloading = false};
	["Sniper R."] = {ReloadTime = 3.5,MaxAmmo = 12,Ammo = 12,Rate = 1.5,Reloading = false};
	AbilityWeapon = {
		["Scythe"] = {Damage = 10,SwingRate = 0.25,
			MagnecticBlaster = {Damage = 120,AbilityCooldown = 85},
			CutPower = {AbilityCooldown = 25};
			Daggers = {AbilityCooldown = 65,Damage = 100};
			AbilityFinished = false
		};
	};
	CreatedNVBatteryData = {}
}

module.SpawnNVBatteryAtLocation = function(self,position)
	if(not position) then return end
	local WeaponsService = Knit.GetService("WeaponsService")
	local part = Instance.new("Part",workspace)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.one
	part.Material = "Neon"
	part.Color = Color3.fromRGB(255,255,0)
	part.Transparency = 0.3
	local light = Instance.new("PointLight",part)
	light.Color = Color3.new(0,255,0)
	light.Brightness = 2
	light.Shadows = true
	light.Range = 10
	table.insert(self.WeaponsStats.CreatedNVBatteryData,part)
	local proxy = Instance.new("ProximityPrompt",part)
	proxy.ActionText = "NVBattery"
	proxy.ObjectText = "Take"
	proxy.RequiresLineOfSight = false
	proxy.Triggered:Connect(function(playerWhoTriggered: Player) 
		if(playerWhoTriggered.Character:FindFirstChild("mode_selector")) then
			return 
		end
		table.remove(self.WeaponsStats.CreatedNVBatteryData,table.find(self.WeaponsStats.CreatedNVBatteryData,part))
		part:Destroy()
		WeaponsService.Client.NVBatteryClaimedSignal:Fire(playerWhoTriggered)
	end)
end

module.CleanNVBattery = function(self)
	if(not self.WeaponsStats.CreatedNVBatteryData) then
		return
	end
	for i,v in pairs(self.WeaponsStats.CreatedNVBatteryData) do
		if(v) then
			v:Destroy()
		end
	end
	table.clear(self.WeaponsStats.CreatedNVBatteryData)
end

local function remove(t,value)
	for i,v in pairs(t) do
		if(v.Name == value) then
			table.remove(t,table.find(t,value))
		end
	end
end

function module:Raycast(posA,posB,params)
	local Origin = posA
	local Direction = (posB-Origin).Unit*1000
	local Raycast = workspace:Raycast(Origin,Direction,params or RaycastParams.new())
	local Intersection = Raycast and Raycast.Position or Origin + Direction
	local Distance = (Origin - Intersection).Magnitude
	return Raycast,Intersection,Distance
end

function module:RaycastHitbox(posA,params)
	if(not posA) then return end
	local part = Instance.new("Part",workspace)
	part.Size = Vector3.new(10,5,10);
	part.Position = posA 
	part.CanCollide = false
	part.Material = "ForceField"
	part.Color = Color3.fromRGB(255,0,0);
	part.Anchored = true
	part.Transparency = 1
	Debris:AddItem(part,2)
	local array_from_part = workspace:GetPartsInPart(part,params)
	if(not array_from_part) then
		return
	end
	local humanoid = nil
	for i,v in pairs(array_from_part) do
		if(v) then
			if(v.Parent:FindFirstChild("Humanoid") and v.Parent:FindFirstChild("mode_selector") == nil) then
				humanoid = v.Parent:FindFirstChild("Humanoid")
				break
			end
		end
	end
	if(not humanoid) then return end
	return {Instance = humanoid}
end

function module:GetRandomWeapon(parent)
	local Weapons = ServerStorage.Weapons:GetChildren()
	local exclude_weapons = {"Pistol","Pistol2More","FirstAid","S. FirstAid"}
	remove(Weapons,exclude_weapons[1])
	remove(Weapons,exclude_weapons[2])
	remove(Weapons,exclude_weapons[3])
	remove(Weapons,exclude_weapons[4])
	local random_weapon = Weapons[math.random(1,#Weapons)]
	return random_weapon.Name
end

function module:LoadHeathItem()
	local healthItem = ServerStorage.Weapons["S. FirstAid"].Name
	return healthItem
end

function module:LoadWeapon(parent)
	local player = Players:GetPlayerFromCharacter(parent)
	if(player) then
		local profile = Knit.GetService("ProfileStoreService"):GetProfile()
		if(profile) then
			if(profile.Data.Products["x2 bullets"]) then
				return ServerStorage.Weapons.Pistol2MORE.Name
			end
		end
	end
	local Pistol = ServerStorage.Weapons.Pistol
	return Pistol.Name
end
function module:GetScythe()
	if(not ServerStorage.Resources.Scythe) then return end
	return ServerStorage.Resources.Scythe.Name
end

function module:SetDamageLabel(damage_dealt,parent)
	if(not damage_dealt) then return end	
	if(not parent) then return end
	local textLabelDamage = ServerStorage.Resources.TextLabel:Clone()
	textLabelDamage.Parent = parent
	textLabelDamage.Text = "- " .. tostring(damage_dealt)
	textLabelDamage.TextTransparency = 0
	Debris:AddItem(textLabelDamage,3)
	return textLabelDamage
end

function module:GetWeaponDamage(weapon_name)
	if(not weapon_name) then return end
	local weaponInStorage = ServerStorage.Weapons:FindFirstChild(weapon_name)
	if(not weaponInStorage) then return end
	return weaponInStorage:FindFirstChild("Damage").Value
end

return module
