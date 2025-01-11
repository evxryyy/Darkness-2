local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)
local WeaponsComponents = require(script.Parent.WeaponsComponent)

local function DroppableWeaponsData(t)
	if(not t) then return end
	local data = {}
	for i,v in pairs(t) do
		if(i == "AbilityWeapon") then continue end
		if(i == "CreatedNVBatteryData") then continue end
		if(not data[i]) then
			data[i] = i
		else
			continue
		end
	end
	return data
end

local main = {}
main.__index = main
main.DroppableWeapons = DroppableWeaponsData(WeaponsComponents.WeaponsStats)
main.dropStarted = false

function main:StartDrops()
	if(self.dropStarted == true) then return end
	local WeaponsService = Knit.GetService("WeaponsService")
	local weaponsFolder = ReplicatedStorage.Weapons
	local getMapName = Knit.GetService("GameService").State.MapChoosen
	if(not getMapName) then return end
	local map = workspace:FindFirstChild(getMapName)
	if(not map) then return end
	local weaponsLocation = {}
	for i,parts in pairs(map.MapData.WeaponDrops:GetChildren()) do
		if(parts:IsA("BasePart")) then
			local randomWeapon = ReplicatedStorage.Weapons.WeaponDrops:GetChildren()[math.random(1,#ReplicatedStorage.Weapons.WeaponDrops:GetChildren())]:Clone()
			randomWeapon.Parent = parts.Parent
			randomWeapon.Position = parts.Position
			randomWeapon.Anchored = true
			randomWeapon.CanCollide = false
			weaponsLocation[randomWeapon] = randomWeapon.Position
			local weaponLight = Instance.new("PointLight",randomWeapon)
			weaponLight.Color = Color3.new(0.333333, 1, 1)
			weaponLight.Shadows = true
			weaponLight.Brightness = 2
			weaponLight.Range = 12
			local proximity = Instance.new("ProximityPrompt",randomWeapon)
			proximity.ObjectText = randomWeapon.Name
			proximity.ActionText = "Interact"
			proximity.Triggered:Connect(function(playerWhoTriggered: Player) 
				if(not playerWhoTriggered) then return end
				local character = playerWhoTriggered.Character or playerWhoTriggered.CharacterAdded:Wait()
				if(not character) then return end
				local mode_selector = character:FindFirstChild("mode_selector")
				if(mode_selector) then return end
				local maxTools = 0
				local getWeaponsFromStorage = game.ServerStorage.Weapons:FindFirstChild(randomWeapon.Name)
				if(not getWeaponsFromStorage) then return end
				local mkWeapon = getWeaponsFromStorage:Clone()
				mkWeapon.Parent = playerWhoTriggered.Backpack
				weaponsLocation[randomWeapon] = nil
				if(self.liveWeaponsDropped[randomWeapon]) then
					self.liveWeaponsDropped[randomWeapon] = nil
				end
				if(mkWeapon.Name ~= "NV Battery") then
					WeaponsService.Client.ClaimDroppedWeapons:Fire(playerWhoTriggered,mkWeapon)
				else
					WeaponsService.Client.NVBatteryClaimedSignal:Fire(playerWhoTriggered,mkWeapon)
				end
				randomWeapon:Destroy()
			end)
		end
	end
	self.dropStarted = true
	self.liveWeaponsDropped = weaponsLocation
	return weaponsLocation
end

function main:CancelDrops()
	if(self.dropStarted == false) then return end
	if(not self.liveWeaponsDropped) then return end
	for weapon,position in pairs(self.liveWeaponsDropped) do
		if(weapon) then
			weapon:Destroy()
		end
	end
	table.clear(self.liveWeaponsDropped)
	self.liveWeaponsDropped = nil
	self.dropStarted = false
	return "cleaned"
end

return main
