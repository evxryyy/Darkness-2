local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Maid = require(ReplicatedStorage.Packages.Maid)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Roact = require(ReplicatedStorage.Packages.Roact)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local PlayerEventTracker = require(ReplicatedStorage.Packages.PlayerEventTracker)

local Mouse = Players.LocalPlayer:GetMouse()

local module = Knit.CreateController({
	Name = "GameController";
	health_bar_initialised = false;
	nv_initialised = false;
})

local function findMax(array)
	if(type(array) == "function") then
		array = array()
	end
	local function sort_values(t)
		local values = TableUtil.Values(t)
		table.sort(values,function(a,b)
			return a < b
		end)
		return values
	end
	local get_max_value = sort_values(array)[#sort_values(array)]
	local get_profile_data = nil
	for i,num in pairs(array) do
		if(num) then
			if(num == get_max_value) then
				get_profile_data = i
				break
			end
		end
	end
	if(not get_profile_data) then return {[""] = -10} end
	local bind = {[get_profile_data] = get_max_value}
	return bind
end

local function init_weapon_signal(types)
	local ProfileStoreService = Knit.GetService("ProfileStoreService")
	local MarketService = Knit.GetService("MarketService")
	local GameService = Knit.GetService("GameService")
	local WeaponsService = Knit.GetService("WeaponsService")
	WeaponsService:DestroyPlayerComponent()
	local WeaponsConfig = WeaponsService:ConstructUserWeapon(types)
	local WeaponsSignal = WeaponsService:SetParent()
	if(type(WeaponsSignal) ~= "table") then
		WeaponsSignal = {WeaponsSignal}
	end
	local WeaponsStats = TableUtil.Copy(WeaponsService:copyWeaponStats(),true)
	for i,tool : Tool in pairs(WeaponsSignal) do
		tool.Activated:Connect(function()
			if(WeaponsStats[tool.Name]) then
				if(WeaponsStats[tool.Name].Reloading ~= false) then return end
				if(WeaponsStats[tool.Name].Ammo > 0) and (WeaponsStats[tool.Name].Rate ~= 0.0) then
					WeaponsService:GetRaycast(
						tool:FindFirstChild("Handle"):FindFirstChildOfClass("Attachment").WorldPosition,
						Mouse.Hit.Position,tool.Name
					)
					WeaponsStats[tool.Name].Ammo -= 1
					local temp_rate = WeaponsStats[tool.Name].Rate
					WeaponsStats[tool.Name].Rate = 0
					task.delay(WeaponsStats[tool.Name].Rate,function()
						WeaponsStats[tool.Name].Rate = temp_rate
					end)
				elseif(WeaponsStats[tool.Name].Ammo <= 0) then
					WeaponsStats[tool.Name].Reloading = true
					task.delay(WeaponsStats[tool.Name].ReloadTime,function()
						WeaponsStats[tool.Name].Ammo = WeaponsStats[tool.Name].MaxAmmo
						WeaponsStats[tool.Name].Reloading = false
					end)
				end
			end
		end)
		tool.Equipped:Connect(function() 
			for i,animationTrack : AnimationTrack in pairs(Players.LocalPlayer.Character.Humanoid.Animator:GetPlayingAnimationTracks()) do
				if(animationTrack.Name == "holdstaff" or animationTrack.Name == "attack" or animationTrack.Name == "walkstaff") then
					animationTrack.Looped = false
					animationTrack:Stop()
				end
			end
			if(WeaponsStats[tool.Name]) then
			elseif(WeaponsStats.AbilityWeapon[tool.Name]) then
				local startHandleTracker : AnimationTrack = Players.LocalPlayer.Character.Humanoid.Animator:LoadAnimation(tool:FindFirstChild("holdstaff"))
				startHandleTracker.Looped = true
				startHandleTracker:Play()
				startHandleTracker.Name = "holdstaff"
				PlayerEventTracker:TrackUser(Players.LocalPlayer,Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):GetPropertyChangedSignal("MoveDirection"),function()
					if(Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").MoveDirection ~= Vector3.zero) then
						startHandleTracker:Stop()
						startHandleTracker.Looped = false
						startHandleTracker = Players.LocalPlayer.Character.Humanoid.Animator:LoadAnimation(tool:FindFirstChild("walkstaff"))
						startHandleTracker.Looped = true
						startHandleTracker:Play()
						startHandleTracker.Name = "walkstaff"
					else
						startHandleTracker:Stop()
						startHandleTracker.Looped = false
						startHandleTracker = Players.LocalPlayer.Character.Humanoid.Animator:LoadAnimation(tool:FindFirstChild("holdstaff"))
						startHandleTracker.Looped = true
						startHandleTracker:Play()
						startHandleTracker.Name = "holdstaff"	
					end
				end)	
			end
		end)
		tool.Unequipped:Connect(function() 
			PlayerEventTracker:UntrackUser(Players.LocalPlayer)
			for i,animationTrack : AnimationTrack in pairs(Players.LocalPlayer.Character.Humanoid.Animator:GetPlayingAnimationTracks()) do
				if(animationTrack.Name == "holdstaff" or animationTrack.Name == "attack" or animationTrack.Name == "walkstaff") then
					animationTrack.Looped = false
					animationTrack:Stop()
				end
			end
		end)
		tool.Destroying:Connect(function() 
			PlayerEventTracker:UntrackUser(Players.LocalPlayer)
			for i,animationTrack : AnimationTrack in pairs(Players.LocalPlayer.Character.Humanoid.Animator:GetPlayingAnimationTracks()) do
				if(animationTrack.Name == "holdstaff" or animationTrack.Name == "attack" or animationTrack.Name == "walkstaff") then
					animationTrack.Looped = false
					animationTrack:Stop()
				end
			end
		end)
	end
end

local function init_gui_signal(types)
	if(not types) then return end
	local MarketService = Knit.GetService("MarketService")
	if(types == "beast") then
		local beast_gui = Players.LocalPlayer.PlayerGui:WaitForChild("BeastGui")
		beast_gui.Enabled = true
		Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):GetPropertyChangedSignal("MoveDirection"):Once(function(...: any) 
			if(Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").MoveDirection ~= Vector3.zero) then
				beast_gui.PlayGuide.Visible = false
			end
		end)
		if(MarketService:GetProductFromData("ViewPlayerName") == true) then
			for i,plr in pairs(Players:GetPlayers()) do
				if(plr.Character) then
					local ui_template = ReplicatedStorage.Templates.NameSign:Clone()
					ui_template.Parent = plr.Character.Head
					ui_template.AlwaysOnTop = true
					ui_template.TextLabel.Text = "@" .. plr.Name
				end
			end
		end
	elseif(types ~= "beast") then
		local SurvivorGui = Players.LocalPlayer.PlayerGui:WaitForChild("SurvivorGui")
		SurvivorGui.Enabled = true
		Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):GetPropertyChangedSignal("MoveDirection"):Once(function(...: any) 
			if(Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").MoveDirection ~= Vector3.zero) then
				SurvivorGui.PlayGuide.Visible = false
			end
		end)
	end
end

local function init_health_bar_signal(self,types)
	if(not self) then return end
	if(not types) then return end
	if(types == "beast") then
		local health_bar = Players.LocalPlayer.PlayerGui:WaitForChild("BeastGui").HealthBar
		health_bar:FindFirstChild("hptext").Text = tostring(Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health) .. "/" .. tostring(Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").MaxHealth)
		TweenService:Create(health_bar.fill,TweenInfo.new(0.2),{Size = UDim2.fromScale((Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health / Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").MaxHealth),1)}):Play()
		if(self.health_bar_initialised) then
			self.health_bar_initialised:Disconnect()
			self.health_bar_initialised = false
			TweenService:Create(health_bar.fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,1)}):Play()
			health_bar:FindFirstChild("hptext").Text = tostring(Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health) .. "/" .. tostring(Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").MaxHealth)
		else
			self.health_bar_initialised = Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):GetPropertyChangedSignal("Health"):Connect(function(...: any) 
				local percent = (Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health / Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").MaxHealth)
				TweenService:Create(health_bar.fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(percent,1)}):Play()
				health_bar:FindFirstChild("hptext").Text = tostring(Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health) .. "/" .. tostring(Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").MaxHealth)
			end)
		end
	end
end

local function init_nightvision_signal(self,types)
	if(not self) then return end
	if(not types) then return end
	if(types == "beast") then return end
	local MarketService = Knit.GetService("MarketService")
	local night_charge = Players.LocalPlayer.PlayerGui:FindFirstChild("SurvivorGui").NightVisionCharge
	local nv_frame = Players.LocalPlayer.PlayerGui:FindFirstChild("SurvivorGui").NightVisionFrame
	if(self.nv_initialised) then
		if(self.nv_initialised.event) then
			task.cancel(self.nv_initialised.event)
			self.nv_initialised.event = nil
		elseif(self.nv_initialised.task) then
			task.cancel(self.nv_initialised.task)
			self.nv_initialised.task = nil
		end
		ContextActionService:UnbindAction("NightVisionEvent")
		self.nv_initialised = nil
		night_charge.Value = 0
		TweenService:Create(nv_frame.Parent.NVBar.Bar,TweenInfo.new(0.1),{
			Size = UDim2.fromScale(1,night_charge.Value/100)
		}):Play()
		nv_frame.Parent.Enabled = false
	else
		night_charge.Value = 0
		TweenService:Create(nv_frame.Parent.NVBar.Bar,TweenInfo.new(0.1),{
			Size = UDim2.fromScale(1,night_charge.Value/100)
		}):Play()
		if(MarketService:GetProductFromData("nightvision") == true) then
			night_charge.Value += 50
			TweenService:Create(nv_frame.Parent.NVBar.Bar,TweenInfo.new(0.1),{
				Size = UDim2.fromScale(1,night_charge.Value/100)
			}):Play()
		end
		self.nv_initialised = {
			task = coroutine.create(function() 
			end);
		}
		ContextActionService:BindAction("NightVisionEvent",function()
			if(self.nv_initialised.event) then
				task.cancel(self.nv_initialised.event)
				self.nv_initialised.event = nil
				self.nv_initialised.task = coroutine.create(function() 
					if(night_charge.Value >= 100) then return end
					while(night_charge.Value ~= 100) do
						night_charge.Value += 1
						TweenService:Create(nv_frame.Parent.NVBar.Bar,TweenInfo.new(0.1),{
							Size = UDim2.fromScale(1,night_charge.Value/100)
						}):Play()
						task.wait(1)
					end
				end)
				task.spawn(self.nv_initialised.task)
				nv_frame.Visible = false
			elseif(self.nv_initialised.task) then
				task.cancel(self.nv_initialised.task)
				self.nv_initialised.task = nil
				self.nv_initialised.event = coroutine.create(function()
					if(night_charge.Value <= 0) then return end
					while(night_charge.Value ~= 0) do
						night_charge.Value -= 1
						TweenService:Create(nv_frame.Parent.NVBar.Bar,TweenInfo.new(0.1),{
							Size = UDim2.fromScale(1,night_charge.Value/100)
						}):Play()
						task.wait(1)
					end
					nv_frame.Visible = false
				end)
				task.spawn(self.nv_initialised.event)
				nv_frame.Visible = true
			end
		end,true,Enum.KeyCode.G)
		ContextActionService:SetTitle("NightVisionEvent","NV")
		ContextActionService:SetDescription("NightVisionEvent","Active the Night-vision")
	end
end

local function init_TFlashlight_signal(self,types)
	if(not self) then return end
	if(not types) then return end
	if(types == "beast") then return end
	if(not self.temp_maid_signal) then
		local PropsService = Knit.GetService("PropsService")
		self.temp_maid_signal = Maid.new()
		self.temp_maid_signal:giveTask(Players.LocalPlayer.PlayerGui:WaitForChild("SurvivorGui").TFlashLight.Activated:Connect(function(inputObject: InputObject, clickCount: number) 
			if(Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart"):FindFirstChild("light")) then
				if(Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart"):FindFirstChild("light").Enabled == false) then
					PropsService.ChangePropsSignal:Fire(
						Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart"),
						"light",
						{props_name = "Enabled",props_value = true}
					)
					Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart"):FindFirstChild("light").Enabled = true
				else
					PropsService.ChangePropsSignal:Fire(
						Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart"),
						"light",
						{props_name = "Enabled",props_value = false}
					)
					Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart"):FindFirstChild("light").Enabled = false
				end
			end
		end))
	else
		self.temp_maid_signal:clean()
	end
end

local function init_beast_temp_health_bar(self,types)
	if(not self) then return end
	if(not types) then return end
	if(types ~= "beast") then return end
	local WeaponsService = Knit.GetService("WeaponsService")
	local PropsService = Knit.GetService("PropsService")
	local energyBar = Players.LocalPlayer.PlayerGui:WaitForChild("BeastGui"):WaitForChild("EnergyBar")
	local energyCharge = Players.LocalPlayer.PlayerGui:WaitForChild("BeastGui"):WaitForChild("EnergyCharge")
	if(not self.temp_health_bar_signal) then
		self.temp_health_bar_signal = {
			task = coroutine.create(function(...) 
			end),
			event = nil
		}
		if(self.temp_health_bar_signal.task) then
			task.cancel(self.temp_health_bar_signal.task)
			self.temp_health_bar_signal.task = nil
			self.temp_health_bar_signal.task = coroutine.create(function() 
				local percent = (energyCharge.Value / 100)
				while(energyCharge.Value > 0) do
					energyCharge.Value -= 1
					percent = (energyCharge.Value / 100)
					TweenService:Create(energyBar.fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(percent,1)}):Play()
					task.wait(3)
				end
				PropsService.ChangePropsSignal:Fire(
					Players.LocalPlayer.Character,
					"Humanoid",
					{props_name = "Health",props_value = 0}
				)
			end)
			task.spawn(self.temp_health_bar_signal.task)
		end
		self.temp_health_bar_signal.event = WeaponsService.BeastKilledPlayerSignal:Connect(function()
			energyCharge.Value += 20
		end)	
	else
		task.cancel(self.temp_health_bar_signal.task)
		self.temp_health_bar_signal.task = nil
		self.temp_health_bar_signal.event:Disconnect()
		self.temp_health_bar_signal.event = nil
		table.clear(self.temp_health_bar_signal)
		self.temp_health_bar_signal = nil
		energyCharge.Value = 100
		TweenService:Create(energyBar.fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,1)}):Play()
	end
end

local function init_ability(self,types)
	if(not self) then return end
	if(not types) then return end
	if(types ~= "beast") then return end
	local WeaponsService = Knit.GetService("WeaponsService")
	local WeaponsStats = WeaponsService:copyWeaponStats()
	local copyWeaponsStats = TableUtil.Copy(WeaponsStats,true)
	local SpecialFrame = Players.LocalPlayer.PlayerGui:WaitForChild("BeastGui").SpecialFrame
	local Sbar = SpecialFrame.SBar
	local ab = require(script.Parent.Parent.Modules.Ability)
	local getCutPowerFn = ab.cutPowerAbility
	local getBlastPowerFn = ab.blast
	local getSeekPlayersFn = ab.seekPlayers
	if(not self.ability_component_data) then 
		self.ability_component_data = {
			task = coroutine.create(function(...) 
			end),
			maid = Maid.new()
		}
		if(self.ability_component_data.task) then
			task.cancel(self.ability_component_data.task)
			self.ability_component_data.task = nil
			self.ability_component_data.task = coroutine.create(function(...) 
				while (task.wait(1)) do
					if(SpecialFrame.AbilityCharge.Value <= 100) then
						SpecialFrame.AbilityCharge.Value += 1
					end
					if(SpecialFrame.AbilityCharge.Value > 100) then
						SpecialFrame.AbilityCharge.Value = 100
					end
					TweenService:Create(Sbar.Fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,SpecialFrame.AbilityCharge.Value/100)}):Play()
					SpecialFrame.perc.Text = tostring(SpecialFrame.AbilityCharge.Value)
				end	
			end)
			task.spawn(self.ability_component_data.task)
			ContextActionService:BindAction("CutPowerAction",function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
				if(inputState == Enum.UserInputState.End) then
					if(SpecialFrame.AbilityCharge.Value >= 15 and copyWeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown ~= 0) then
						SpecialFrame.AbilityCharge.Value -= math.clamp(15,0,100)
						TweenService:Create(Sbar.Fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,SpecialFrame.AbilityCharge.Value/100)}):Play()
						SpecialFrame.perc.Text = tostring(SpecialFrame.AbilityCharge.Value)
						copyWeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown = 0
						getCutPowerFn()
						task.delay(WeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown,function()
							copyWeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown = WeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown
						end)
					end
				end
			end,false,Enum.KeyCode.Z)
			ContextActionService:BindAction("SeekPlayers",function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
				if(inputState == Enum.UserInputState.End) then
					if(SpecialFrame.AbilityCharge.Value >= 30 and copyWeaponsStats.AbilityWeapon.Scythe.SeekPlayers.AbilityCooldown ~= 0) then
						SpecialFrame.AbilityCharge.Value -= math.clamp(30,0,100)
						TweenService:Create(Sbar.Fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,SpecialFrame.AbilityCharge.Value/100)}):Play()
						SpecialFrame.perc.Text = tostring(SpecialFrame.AbilityCharge.Value)
						copyWeaponsStats.AbilityWeapon.Scythe.SeekPlayers.AbilityCooldown = 0
						getSeekPlayersFn()
						task.delay(WeaponsStats.AbilityWeapon.Scythe.SeekPlayers.AbilityCooldown,function()
							copyWeaponsStats.AbilityWeapon.Scythe.SeekPlayers.AbilityCooldown = WeaponsStats.AbilityWeapon.Scythe.SeekPlayers.AbilityCooldown
						end)
					end
				end
			end,false,Enum.KeyCode.X)
			ContextActionService:BindAction("MagneticBlast",function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
				if(inputState == Enum.UserInputState.End) then
					if(SpecialFrame.AbilityCharge.Value >= 90 and copyWeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.AbilityCooldown ~= 0) then
						SpecialFrame.AbilityCharge.Value -= math.clamp(90,0,100)
						TweenService:Create(Sbar.Fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,SpecialFrame.AbilityCharge.Value/100)}):Play()
						SpecialFrame.perc.Text = tostring(SpecialFrame.AbilityCharge.Value)
						copyWeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.AbilityCooldown = 0
						getBlastPowerFn(
							Players.LocalPlayer.Character.HumanoidRootPart.Position,
							Players.LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector * -150
						)
						task.delay(WeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.AbilityCooldown,function()
							copyWeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.AbilityCooldown = WeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.AbilityCooldown
						end)
					end
				end
			end,false,Enum.KeyCode.C)
			self.ability_component_data.maid:giveTask(SpecialFrame.Sp1.Activated:Connect(function(inputObject: InputObject, clickCount: number) 
				if(SpecialFrame.AbilityCharge.Value >= 15 and copyWeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown ~= 0) then
					SpecialFrame.AbilityCharge.Value -= math.clamp(15,0,100)
					TweenService:Create(Sbar.Fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,SpecialFrame.AbilityCharge.Value/100)}):Play()
					SpecialFrame.perc.Text = tostring(SpecialFrame.AbilityCharge.Value)
					copyWeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown = 0
					getCutPowerFn()
					task.delay(WeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown,function()
						copyWeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown = WeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown
					end)
				end
			end))
			self.ability_component_data.maid:giveTask(SpecialFrame.Sp2.Activated:Connect(function(inputObject: InputObject, clickCount: number) 
				if(SpecialFrame.AbilityCharge.Value >= 30 and copyWeaponsStats.AbilityWeapon.Scythe.SeekPlayers.AbilityCooldown ~= 0) then
					SpecialFrame.AbilityCharge.Value -= math.clamp(30,0,100)
					TweenService:Create(Sbar.Fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,SpecialFrame.AbilityCharge.Value/100)}):Play()
					SpecialFrame.perc.Text = tostring(SpecialFrame.AbilityCharge.Value)
					copyWeaponsStats.AbilityWeapon.Scythe.SeekPlayers.AbilityCooldown = 0
					getSeekPlayersFn()
					task.delay(WeaponsStats.AbilityWeapon.Scythe.SeekPlayers.AbilityCooldown,function()
						copyWeaponsStats.AbilityWeapon.Scythe.SeekPlayers.AbilityCooldown = WeaponsStats.AbilityWeapon.Scythe.SeekPlayers.AbilityCooldown
					end)
				end
			end))
			self.ability_component_data.maid:giveTask(SpecialFrame.Sp3.Activated:Connect(function(inputObject: InputObject, clickCount: number) 
				if(SpecialFrame.AbilityCharge.Value >= 90 and copyWeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.AbilityCooldown ~= 0) then
					SpecialFrame.AbilityCharge.Value -= math.clamp(90,0,100)
					TweenService:Create(Sbar.Fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,SpecialFrame.AbilityCharge.Value/100)}):Play()
					SpecialFrame.perc.Text = tostring(SpecialFrame.AbilityCharge.Value)
					copyWeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.AbilityCooldown = 0
					getBlastPowerFn(Players.LocalPlayer.Character.HumanoidRootPart.Position,Mouse.Hit.Position)
					task.delay(WeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.AbilityCooldown,function()
						copyWeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.AbilityCooldown = WeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.AbilityCooldown
					end)
				end	
			end))
		end
	else
		task.cancel(self.ability_component_data.task)
		self.ability_component_data.task = nil
		self.ability_component_data.maid:clean()
		self.ability_component_data.maid = nil
		table.clear(self.ability_component_data)
		self.ability_component_data = nil
		TweenService:Create(Sbar.Fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,0)}):Play()
		SpecialFrame.perc.Text = tostring(0)	
		SpecialFrame.Parent.EnergyCharge.Value = 0
		ContextActionService:UnbindAction("CutPowerAction")
		ContextActionService:UnbindAction("SeekPlayers")
		ContextActionService:UnbindAction("MagneticBlast")
	end
end

function module:Load(...)
	local GameService = Knit.GetService("GameService")
	local WeaponsService = Knit.GetService("WeaponsService")
	GameService.InitComponentsSignal:Connect(function(types)
		if(not types) then return end
		init_gui_signal(types) -- "roles gui (beast or survivor)"
		init_weapon_signal(types) -- "players weapons"
		init_health_bar_signal(self,types) -- "beast health bar"
		init_nightvision_signal(self,types) -- "survivor nv"
		init_TFlashlight_signal(self,types) -- "toggle survivor light"
		init_beast_temp_health_bar(self,types) -- "beast energy bar"
		init_ability(self,types) -- "beast ability, ability charge"
	end)
	WeaponsService.WeaponsDamageAnimation:Connect(function(label)
		if(not label) then return end
		TweenService:Create(label,TweenInfo.new(1.5),{
			Position = UDim2.fromScale(0.5,0.2);
			TextTransparency = 1
		}):Play()
	end)
	GameService.InitGameResults:Connect(function(data,state)
		if(not data) then return end
		if(type(data) ~= "table") then
			Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").Enabled = true
			if(Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").GameResults.Visible == true) then
				Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").GameResults.Visible = false
			end
			if(self.health_bar_initialised) then
				init_health_bar_signal(self,"beast")
				local beast_gui = Players.LocalPlayer.PlayerGui:WaitForChild("BeastGui")
				beast_gui.Enabled = false
				beast_gui.PlayGuide.Visible = true
			end
			if(self.nv_initialised) then
				init_nightvision_signal(self,"survivor")
			end
			if(self.temp_maid_signal) then
				init_TFlashlight_signal(self,"survivor")
			end
			if(self.temp_health_bar_signal) then
				init_beast_temp_health_bar(self,"beast")
			end
			if(self.ability_component_data) then
				init_ability(self,"beast")
			end
			WeaponsService:DestroyPlayerComponent()
			return
		end
		if(self.health_bar_initialised) then
			init_health_bar_signal(self,"beast")
			local beast_gui = Players.LocalPlayer.PlayerGui:WaitForChild("BeastGui")
			beast_gui.Enabled = false
			beast_gui.PlayGuide.Visible = true
		end
		if(self.nv_initialised) then
			init_nightvision_signal(self,"survivor")
		end
		if(self.temp_maid_signal) then
			init_TFlashlight_signal(self,"survivor")
		end
		if(self.temp_health_bar_signal) then
			init_beast_temp_health_bar(self,"beast")
		end
		if(self.ability_component_data) then
			init_ability(self,"beast")
		end
		WeaponsService:DestroyPlayerComponent()
		if(state ~= "damage_total_taken") then 
			Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").GameResults.status.Text = "The beast has won"
			Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").GameResults.status.TextColor3 = Color3.fromRGB(255,0,0)
		else
			Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").GameResults.status.Text = "The survivors have won"
			Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").GameResults.status.TextColor3 = Color3.fromRGB(255, 255, 0)
		end
		Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").Enabled = true
		Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").GameResults.Visible = true
		for i,stats in pairs(data) do
			if(type(stats) == "table") then
				for j,stat in pairs(stats) do
					if(type(stat) == "number") then
						local clone = script.Parent.Parent.UITemplate.template_data:Clone()
						clone.Parent = Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").GameResults.Damages.ScrollingFrame
						clone.Text = ""
						clone.Text = "@" .. i .. " / Damage Dealt: ".. stat
						clone.Visible = true
						clone.Name = i
					end
				end
			end
		end
		if(state ~= "damage_total_taken") then return end
		local calcul = 0
		for i,stats in pairs(data) do
			if(type(stats) == "table") then
				for j,stat in pairs(stats) do
					if(type(stat) == "number") then
						calcul += stat
					end 
				end
			end
		end
		Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").GameResults.total.Text = ("The Beast took %d total damage"):format(calcul)
	end)
end

function module:Init(...)
	local IntroGui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("IntroGui")
	local MenuGui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MenuGui")
	local gameService = Knit.GetService("GameService")
	gameService.InitGameSignal:Connect(function(params)
		if(not params) then return end
		IntroGui.Enabled = false
		MenuGui.Enabled = false
	end)
	self:Load()
end

function module:KnitStart(...)
	self:Init(...)
end

return module
