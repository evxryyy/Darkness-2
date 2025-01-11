local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

return function()
	local PropsService = Knit.GetService("PropsService")
	PropsService.ChangeAllSameClassInstanceSignal:Fire(
		"PointLight",
		"light",
		{props_name = "Enabled",props_value = false,delay_before_activation = 10,position = Players.LocalPlayer.Character.HumanoidRootPart.Position}
	)
end
