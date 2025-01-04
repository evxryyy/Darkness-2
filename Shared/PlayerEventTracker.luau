local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Promise = require(ReplicatedStorage.Packages.Promise)

local tracker = {
	users = {}
}
tracker.__index = tracker

function tracker:TrackUser(player,rbxScriptSignal,fn)
	if(not Players:FindFirstChild(player.Name)) then return end
	if(type(fn) ~= "function") then return end
	if(self.users[player.Name]) then return end
	self.users[player.Name] = Trove.new()
	self.users[player.Name]:Connect(rbxScriptSignal,fn)
	return self.users[player.Name]
end

function tracker:GetUserTracker(player_name)
	if(not self.users[player_name]) then return false end
	return true
end

function tracker:UntrackUser(player_name)
	if(not self.users[player_name]) then return false end
	if(self.users[player_name].Destroy) then
		self.users[player_name]:Destroy()
		self.users[player_name] = nil
		return true
	elseif(self.users[player_name].Clean) then
		self.users[player_name]:Clean()
		self.users[player_name] = nil
		return true
	end
	
	return false
end

return tracker
