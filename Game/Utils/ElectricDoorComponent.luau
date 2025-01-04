local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)

local function SingleDoorTween(object,reverse)
	for pos = 0,1.5,0.1 do
		if(reverse) then
			object.CFrame = object.CFrame * CFrame.new(pos,0,0)
		else
			object.CFrame = object.CFrame * CFrame.new(-pos,0,0)
		end
		task.wait()
	end
end

local class = {}
class.__index = class

function class.new(object)
	if(not object) then return end
	local self = setmetatable({}, class)
	self.trove = Trove.new()
	self.classId = HttpService:GenerateGUID(false)
	self.observer_object = self.trove:AttachToInstance(object)
	self.ProximityPrompt = self.trove:Add(Instance.new("ProximityPrompt",object.DoorButton))
	self.ProximityPrompt.RequiresLineOfSight = false
	self.ProximityPrompt.MaxActivationDistance = 15
	self.ProximityPrompt.ObjectText = "Door"
	self.ProximityPrompt.ActionText = "Interact"
	self.signal = self.trove:Construct(Signal)
	self.trove:Connect(self.signal,function(...)
		if(object.Open.Value == false) then
			local door,door2 = object:FindFirstChild("Door"), object:FindFirstChild("Door2")
			if(not door2) then
				self.ProximityPrompt.Enabled = false
				object.Open.Value = true
				SingleDoorTween(door)
				task.delay(1,function()
					self.ProximityPrompt.Enabled = true
				end)
			else
				self.ProximityPrompt.Enabled = false
				object.Open.Value = true
				task.spawn(SingleDoorTween,door2,false)
				SingleDoorTween(door,true)
				task.delay(1,function()
					self.ProximityPrompt.Enabled = true
				end)
			end
		else
			local door,door2 = object:FindFirstChild("Door"), object:FindFirstChild("Door2")
			if(not door2) then
				self.ProximityPrompt.Enabled = false
				SingleDoorTween(door,true)
				object.Open.Value = false
				task.delay(1,function()
					self.ProximityPrompt.Enabled = true
				end)
			else
				self.ProximityPrompt.Enabled = false
				task.spawn(SingleDoorTween,door2,true)
				SingleDoorTween(door,false)
				object.Open.Value = false
				task.delay(1,function()
					self.ProximityPrompt.Enabled = true
				end)
			end
		end
	end)
	self.trove:Connect(self.ProximityPrompt.Triggered,function(...)
		self:Fire(...)
	end)
	self.trove:Connect(CollectionService:GetInstanceRemovedSignal("ElectricalDoor"),function(instance)
		self:Destroy()
	end)
	CollectionService:AddTag(object,"ElectricalDoor")
	return self
end

function class:Fire(...)
	return self.signal:Fire(...)
end

function class:Destroy()
	if(self.observer_object) then
		self.observer_object:Disconnect()
	end
	if(self.signal) then
		self.signal:DisconnectAll()
		self.signal:Destroy()
	end
	self.classId = nil
	self.ProximityPrompt:Destroy()
	self.trove:Clean()
	table.clear(self)
	self = nil
	return true
end

function class:CleanAll()
	local instance_array = CollectionService:GetTagged("ElectricalDoor")
	for i,instance in pairs(instance_array) do
		if(instance) then
			CollectionService:RemoveTag(instance,"ElectricalDoor")
		end
	end
end

return class
