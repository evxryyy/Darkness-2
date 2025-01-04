local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.Roact)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

local module = Knit.CreateService({
	Name = "PropsService";
	Client = {
		ChangePropsSignal = Knit.CreateSignal();
		ChangeAllSameClassInstanceSignal = Knit.CreateSignal()
	}
})

function module:KnitStart(...)
	self.Client.ChangePropsSignal:Connect(function(player,instance_path,instance_name,data)
		if(instance_path) then
			local getInstance = instance_path:FindFirstChild(instance_name)
			if(not getInstance) then return end
			if(getInstance[data.props_name]) then
				getInstance[data.props_name] = data.props_value
				return true	
			end
			return false
		end
		return false
	end)
	self.Client.ChangeAllSameClassInstanceSignal:Connect(function(player,instance_type,exclude_name,data)
		if(instance_type) then
			for i,instance in pairs(workspace:GetDescendants()) do
				if(instance:IsA(instance_type) and instance.Name ~= exclude_name) then
					instance[data.props_name] = data.props_value
				end
			end
			task.delay(data.delay_before_activation,function()
				for i,instance in pairs(workspace:GetDescendants()) do
					if(instance:IsA(instance_type) and instance.Name ~= exclude_name) then
						instance[data.props_name] = true
					end
				end
			end)
		end
	end)
end

return module
