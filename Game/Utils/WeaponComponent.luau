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

module.WeaponsStats = "PRIVATE"

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

function module:RaycastHitbox(posA,posB,params)
	if(not posA or not posB) then return end
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
			if(v.Parent:FindFirstChild("Humanoid")) then
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
	local exclude_weapons = {"Pistol","Pistol2More"}
	remove(Weapons,exclude_weapons[1])
	remove(Weapons,exclude_weapons[2])
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
