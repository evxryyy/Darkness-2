local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local ProfileService = require(ServerStorage.DataModules.ProfileService)
local Knit = require(ReplicatedStorage.Packages.Knit)
local DataTemplate = require(ServerScriptService.Game.Templates.DataTemplate)

local StorageService = ProfileService.GetProfileStore("Darkness2(testing)",DataTemplate)

local module = Knit.CreateService({
	Name = "ProfileStoreService";
	Client = {};
	Profiles = {}
})

function module:LoadProfile(player : Player)
	if(not player) then return end
	local profile = StorageService:LoadProfileAsync("Player_"..player.UserId)
	if(profile) then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			profile = nil
			return player:Kick("Data error.")
		end)
		if(player:IsDescendantOf(Players)) then
			self.Profiles[player.UserId] = profile
			local leaderstats = Instance.new("Folder",player)
			leaderstats.Name = "leaderstats"
			local points = Instance.new("IntValue",leaderstats)
			points.Value = self.Profiles[player.UserId].Data.Points
			points.Name = "Points"
			points:GetPropertyChangedSignal("Value"):Connect(function(...: any) 
				self.Profiles[player.UserId].Data.Points = points.Value
			end)
			print(profile)
		else
			profile:Release()
		end
	else
		player:Kick("Profile failed to load, try again shortly. If issue persists, contact us!")
	end
	return profile
end

function module:GetProfile(player : Player,sub_plr)
	if(not player) then return end
	if(not sub_plr) then
		if(not self.Profiles[player.UserId]) then return end
		return self.Profiles[player.UserId]
	else
		if(not self.Profiles[sub_plr.UserId]) then return end
		return self.Profiles[sub_plr.UserId]
	end
end

function module:DisconnectProfile(player : Player)
	if(not player) then return end
	if(not self.Profiles[player.UserId]) then return end
	self.Profiles[player.UserId]:Release()
	self.Profiles[player.UserId] = nil
	return true
end

function module.Client:GetProfile(player,sub_plr)
	local copy_profile = self.Server:GetProfile(player,sub_plr).Data
	if(table.isfrozen(copy_profile)) then
		return copy_profile
	else
		table.freeze(copy_profile)
	end
	return copy_profile
end

function module:KnitStart(...)
	Players.PlayerAdded:Connect(function(player : Player)
		local profile = self:LoadProfile(player)
	end)
	Players.PlayerRemoving:Connect(function(player: Player) 
		self:DisconnectProfile(player)	
	end)
end

return module
