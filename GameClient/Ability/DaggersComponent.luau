local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)

return function()
	local WeaponsService = Knit.GetService("WeaponsService")
	local backpack = Players.LocalPlayer.Backpack
	if(backpack:FindFirstChild("Daggers") or Players.LocalPlayer.Character:FindFirstChild("Daggers")) then
		return
	end
	local data = {}
	local getDaggers = WeaponsService:CloneDaggers()
	getDaggers.Equipped:Connect(function()
		if(data.RunServiceConnection) then
			data.RunServiceConnection:Disconnect()
			data.RunServiceConnection = nil
			if(data.part) then
				data.part:Destroy()
				data.part = nil
			end
		else
			if(data.part) then
				data.part:Destroy()
				data.part = nil
			end
			local part = Instance.new("Part",getDaggers.Parent)
			part.Name = "direction"
			part.CFrame = Players.LocalPlayer.Character.HumanoidRootPart.RootAttachment.WorldCFrame * CFrame.new(0,0,-15)
			part.Size = Vector3.new(3,3,30)
			part.Transparency = 0.3
			part.Anchored = true
			part.CanCollide = false
			part.Color = Color3.fromRGB(255,0,0)
			part.Material = "Neon"
			data.part = part
			data.RunServiceConnection = RunService.RenderStepped:Connect(function(deltaTime: number) 
				part.CFrame = Players.LocalPlayer.Character.HumanoidRootPart.RootAttachment.WorldCFrame * CFrame.new(0,0,-15)
			end)
		end
	end)
	getDaggers.Activated:Once(function()
		if(data.RunServiceConnection) then
			data.RunServiceConnection:Disconnect()
			data.RunServiceConnection = nil
			if(data.part) then
				data.part:Destroy()
				data.part = nil
			end
		end
		local Mouse = Players.LocalPlayer:GetMouse()
		WeaponsService:DaggersRaycastAbility(Players.LocalPlayer.Character.HumanoidRootPart.Position,Mouse.Hit.Position)
		WeaponsService:RemoveDaggers()
	end)
	getDaggers.Unequipped:Connect(function()
		if(data.part) then
			data.part:Destroy()
			data.part = nil
		end
		if(data.RunServiceConnection) then
			data.RunServiceConnection:Disconnect()
			data.RunServiceConnection = nil
		end
	end)
	getDaggers.Destroying:Connect(function()
		if(data.part) then
			data.part:Destroy()
			data.part = nil
		end
		if(data.RunServiceConnection) then
			data.RunServiceConnection:Disconnect()
			data.RunServiceConnection = nil
			if(data.part) then
				data.part:Destroy()
				data.part = nil
			end
		end
	end)
end
