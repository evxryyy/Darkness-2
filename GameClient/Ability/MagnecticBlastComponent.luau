local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)

return function(posA,posB)
	local WeaponsService = Knit.GetService("WeaponsService")
	WeaponsService:MagnecticBlastAbility(posA,posB)
	local connection
	connection = WeaponsService.MagnecticBlastRaySignal:Connect(function(data)
		if(not data) then return end
		local sphere = Instance.new("Part",workspace)
		sphere.Shape = Enum.PartType.Block
		sphere.Color = Color3.fromRGB(255,0,0)
		sphere.Material = "Neon"
		sphere.Transparency = 0.3
		sphere.Anchored = true
		sphere.CanCollide = false
		sphere.CastShadow = false
		TweenService:Create(sphere,TweenInfo.new(.1),{Size = Vector3.new(3,3,data.direction)}):Play()
		sphere.CFrame = CFrame.new(data.origin,data.interpolation)*CFrame.new(0,0,-data.direction/2)
		task.delay(3,function()
			local tweenData = TweenService:Create(sphere,TweenInfo.new(.5),{Size = Vector3.new(0,0,data.direction),Transparency = 1})
			tweenData:Play()
			tweenData.Completed:Wait()
			Debris:AddItem(sphere,2)
			if(connection) then
				connection:Disconnect()
				connection = nil
			end
		end)
	end)
end
