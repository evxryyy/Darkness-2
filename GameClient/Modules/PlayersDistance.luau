local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local module = {}
module.__index = module

function module:StartDistanceData()
	if(self.RE) then return end
	self.distances = {}
	self.addedInstance = {}
	self.RE = RunService.RenderStepped:Connect(function(deltaTime: number)
		table.clear(self.distances)
		for i,player in pairs(Players:GetPlayers()) do
			if(player == Players.LocalPlayer) then continue end
			local character = player.Character
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if(not humanoidRootPart) then return end
			local register_distance_num = (Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart").Position - humanoidRootPart.Position).Magnitude
			if(not register_distance_num) then return end
			table.insert(self.distances,register_distance_num)
			if(table.find(self.addedInstance,player.Name)) then
				local get_billboard_gui = player.Character.HumanoidRootPart:FindFirstChild("DistanceBillboardGui")
				if(get_billboard_gui) then
					get_billboard_gui.TextLabel.Text = ("%d(m)"):format(register_distance_num)
					get_billboard_gui.Size = UDim2.fromScale(register_distance_num/10,register_distance_num/10)
				end
			else
				local clone_billboard_gui = script.Parent.Parent.UITemplate.DistanceBillboardGui:Clone()
				clone_billboard_gui.Parent = player.Character.HumanoidRootPart
				clone_billboard_gui.TextLabel.Text = ("%d(m)"):format(register_distance_num)
				clone_billboard_gui.Size = UDim2.fromScale(register_distance_num/10,register_distance_num/10)
				table.insert(self.addedInstance,player.Name)
			end
		end
	end)
end

function module:StopDistanceData()
	table.clear(self.addedInstances)
	self.RE:Disconnect()
	table.clear(self.distances)
	table.clear(self.RE)
end

return module
