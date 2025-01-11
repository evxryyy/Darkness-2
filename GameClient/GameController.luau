local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ContextActionService = game:GetService("ContextActionService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Maid = require(ReplicatedStorage.Packages.Maid)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Roact = require(ReplicatedStorage.Packages.Roact)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local ToolsSignal = require(script.Parent.Parent.Modules.ToolsSignal)
local PlayersDistance = require(script.Parent.Parent.Modules.PlayersDistance)
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
	local SurvivorGui = Players.LocalPlayer.PlayerGui:WaitForChild("SurvivorGui")
	local ProfileStoreService = Knit.GetService("ProfileStoreService")
	local MarketService = Knit.GetService("MarketService")
	local GameService = Knit.GetService("GameService")
	local WeaponsService = Knit.GetService("WeaponsService")
	local PropsService = Knit.GetService("PropsService")
	WeaponsService:DestroyPlayerComponent()
	local WeaponsConfig = WeaponsService:ConstructUserWeapon(types)
	local WeaponsSignal = WeaponsService:SetParent()
	if(type(WeaponsSignal) ~= "table") then
		WeaponsSignal = {WeaponsSignal}
	end
	local WeaponsStats = TableUtil.Copy(WeaponsService:copyWeaponStats(),true)
	for i,tool : Tool in pairs(WeaponsSignal) do
		ToolsSignal:RegisterConnection(tool.Activated,function() 
			if(WeaponsStats[tool.Name]) then
				if(WeaponsStats[tool.Name].Ammo) then
					if(WeaponsStats[tool.Name].Ammo > 0) and (WeaponsStats[tool.Name].Rate ~= 0.0) then
						if(WeaponsStats[tool.Name].Reloading ~= false) then return end
						WeaponsService:GetRaycast(
							tool:FindFirstChild("Handle"):FindFirstChildOfClass("Attachment").WorldPosition,
							Mouse.Hit.Position,tool.Name
						)
						WeaponsStats[tool.Name].Ammo -= 1
						local temp_rate = WeaponsStats[tool.Name].Rate
						WeaponsStats[tool.Name].Rate = 0
						if(WeaponsStats[tool.Name].Ammo and WeaponsStats[tool.Name].MaxAmmo) then
							SurvivorGui.AmmoFrame.ammo.Text = WeaponsStats[tool.Name].Ammo .. " / " .. WeaponsStats[tool.Name].MaxAmmo
						else
							SurvivorGui.AmmoFrame.ammo.Text = "inf"	
						end
						task.delay(WeaponsStats[tool.Name].Rate,function()
							WeaponsStats[tool.Name].Rate = temp_rate
						end)
					elseif(WeaponsStats[tool.Name].Ammo <= 0) then
						if(WeaponsStats[tool.Name].Reloading ~= false) then return end
						WeaponsStats[tool.Name].Reloading = true
						if(tool.Handle:FindFirstChild("Reload")) then
							SoundService:PlayLocalSound(tool.Handle:FindFirstChild("Reload"))
						end
						task.delay(WeaponsStats[tool.Name].ReloadTime,function()
							WeaponsStats[tool.Name].Ammo = WeaponsStats[tool.Name].MaxAmmo
							WeaponsStats[tool.Name].Reloading = false
						end)
						SurvivorGui.AmmoFrame.Visible = true
						SurvivorGui.AmmoFrame.nme.Text = tool.Name
						if(WeaponsStats[tool.Name].Ammo and WeaponsStats[tool.Name].MaxAmmo) then
							SurvivorGui.AmmoFrame.ammo.Text = WeaponsStats[tool.Name].Ammo .. " / " .. WeaponsStats[tool.Name].MaxAmmo
						else
							SurvivorGui.AmmoFrame.ammo.Text = "inf"	
						end
					end
				elseif(WeaponsStats[tool.Name].HealthGiven ~= nil) then
					if(WeaponsStats[tool.Name].HealthCooldown ~= 0) then
						local temp_cd = WeaponsStats[tool.Name].HealthCooldown
						WeaponsStats[tool.Name].HealthCooldown = 0
						PropsService.ChangePropsSignal:Fire(
							Players.LocalPlayer.Character,
							"Humanoid",
							{props_name = "Health",props_value = (Players.LocalPlayer.Character.Humanoid.Health + WeaponsStats[tool.Name].HealthGiven)}
						)
						task.delay(temp_cd,function()
							WeaponsStats[tool.Name].HealthCooldown = temp_cd
						end)
					end
				elseif(WeaponsStats[tool.Name].ShieldCooldown ~= nil) then
					if(WeaponsStats[tool.Name].ShieldCooldown ~= 0) then
						local temp_cd = WeaponsStats[tool.Name].ShieldCooldown
						WeaponsService:GetRaycast(0,0,tool.Name) --> position dont needed for the shield
						WeaponsStats[tool.Name].ShieldCooldown = 0
						task.delay(temp_cd,function()
							WeaponsStats[tool.Name].ShieldCooldown = temp_cd
						end)
					end
				end
			elseif(WeaponsStats.AbilityWeapon[tool.Name]) then
				if(WeaponsStats.AbilityWeapon[tool.Name].SwingRate ~= 0) then
					local animation_track = Players.LocalPlayer.Character.Humanoid.Animator:LoadAnimation(tool:FindFirstChild("staffstandardswing"))
					animation_track.Looped = false
					animation_track:Play()
					animation_track.Name = "attack"
					local temp_swing_rate = WeaponsStats.AbilityWeapon[tool.Name].SwingRate
					WeaponsStats.AbilityWeapon[tool.Name].SwingRate = 0
					WeaponsService:GetRaycast(
						Players.LocalPlayer.Character.HumanoidRootPart.Position,
						Vector3.new(0,0,0),
						tool.Name
					)
					task.delay(temp_swing_rate,function()
						WeaponsStats.AbilityWeapon[tool.Name].SwingRate = temp_swing_rate
					end)
				end
			end
		end)
		ToolsSignal:RegisterConnection(tool.Equipped,function(mouse: Mouse) 
			for i,animationTrack : AnimationTrack in pairs(Players.LocalPlayer.Character.Humanoid.Animator:GetPlayingAnimationTracks()) do
				if(animationTrack.Name == "holdstaff" or animationTrack.Name == "attack" or animationTrack.Name == "walkstaff") then
					animationTrack.Looped = false
					animationTrack:Stop()
				end
			end
			if(WeaponsStats[tool.Name]) then
				SurvivorGui.AmmoFrame.Visible = true
				SurvivorGui.AmmoFrame.nme.Text = tool.Name
				if(WeaponsStats[tool.Name].Ammo and WeaponsStats[tool.Name].MaxAmmo) then
					SurvivorGui.AmmoFrame.ammo.Text = WeaponsStats[tool.Name].Ammo .. " / " .. WeaponsStats[tool.Name].MaxAmmo
				else
					SurvivorGui.AmmoFrame.ammo.Text = "inf"
				end
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
		ToolsSignal:RegisterConnection(tool.Unequipped,function() 
			SurvivorGui.AmmoFrame.Visible = false
			PlayerEventTracker:UntrackUser(Players.LocalPlayer)
			for i,animationTrack : AnimationTrack in pairs(Players.LocalPlayer.Character.Humanoid.Animator:GetPlayingAnimationTracks()) do
				if(animationTrack.Name == "holdstaff" or animationTrack.Name == "attack" or animationTrack.Name == "walkstaff") then
					animationTrack.Looped = false
					animationTrack:Stop()
				end
			end
		end)
	end
	if(types == "juggernaut") then
		local battery = ReplicatedStorage.Weapons["NV Batt"]:Clone()
		battery.Parent = Players.LocalPlayer.Backpack
		battery.Activated:Once(function() 
			Players.LocalPlayer.PlayerGui:WaitForChild("SurvivorGui").NightVisionCharge.Value = math.clamp(Players.LocalPlayer.PlayerGui:WaitForChild("SurvivorGui").NightVisionCharge.Value + 50,0,100)
			TweenService:Create(Players.LocalPlayer.PlayerGui:WaitForChild("SurvivorGui").NVBar.Bar,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,(Players.LocalPlayer.PlayerGui:WaitForChild("SurvivorGui").NightVisionCharge.Value/100))}):Play()
			battery:Destroy()	
		end)
	end
	WeaponsService.ClaimDroppedWeapons:Connect(function(tool)
		if(not GameService:isGameStarted()) then return end
		if(not tool) then return end
		ToolsSignal:RegisterConnection(tool.Activated,function()
			if(WeaponsStats[tool.Name]) then
				if(WeaponsStats[tool.Name].Ammo) then
					if(WeaponsStats[tool.Name].Ammo > 0) and (WeaponsStats[tool.Name].Rate ~= 0.0) then
						if(WeaponsStats[tool.Name].Reloading ~= false) then return end
						WeaponsService:GetRaycast(
							tool:FindFirstChild("Handle"):FindFirstChildOfClass("Attachment").WorldPosition,
							Mouse.Hit.Position,tool.Name
						)
						WeaponsStats[tool.Name].Ammo -= 1
						local temp_rate = WeaponsStats[tool.Name].Rate
						WeaponsStats[tool.Name].Rate = 0
						if(WeaponsStats[tool.Name].Ammo and WeaponsStats[tool.Name].MaxAmmo) then
							SurvivorGui.AmmoFrame.ammo.Text = WeaponsStats[tool.Name].Ammo .. " / " .. WeaponsStats[tool.Name].MaxAmmo
						else
							SurvivorGui.AmmoFrame.ammo.Text = "inf"	
						end
						task.delay(WeaponsStats[tool.Name].Rate,function()
							WeaponsStats[tool.Name].Rate = temp_rate
						end)
					elseif(WeaponsStats[tool.Name].Ammo <= 0) then
						if(WeaponsStats[tool.Name].Reloading ~= false) then return end
						WeaponsStats[tool.Name].Reloading = true
						if(tool.Handle:FindFirstChild("Reload")) then
							SoundService:PlayLocalSound(tool.Handle:FindFirstChild("Reload"))
						end
						task.delay(WeaponsStats[tool.Name].ReloadTime,function()
							WeaponsStats[tool.Name].Ammo = WeaponsStats[tool.Name].MaxAmmo
							WeaponsStats[tool.Name].Reloading = false
						end)
						SurvivorGui.AmmoFrame.Visible = true
						SurvivorGui.AmmoFrame.nme.Text = tool.Name
						if(WeaponsStats[tool.Name].Ammo and WeaponsStats[tool.Name].MaxAmmo) then
							SurvivorGui.AmmoFrame.ammo.Text = WeaponsStats[tool.Name].Ammo .. " / " .. WeaponsStats[tool.Name].MaxAmmo
						else
							SurvivorGui.AmmoFrame.ammo.Text = "inf"	
						end
					end
				elseif(WeaponsStats[tool.Name].HealthGiven ~= nil) then
					if(WeaponsStats[tool.Name].HealthCooldown ~= 0) then
						local temp_cd = WeaponsStats[tool.Name].HealthCooldown
						WeaponsStats[tool.Name].HealthCooldown = 0
						PropsService.ChangePropsSignal:Fire(
							Players.LocalPlayer.Character,
							"Humanoid",
							{props_name = "Health",props_value = (Players.LocalPlayer.Character.Humanoid.Health + WeaponsStats[tool.Name].HealthGiven)}
						)
						task.delay(temp_cd,function()
							WeaponsStats[tool.Name].HealthCooldown = temp_cd
						end)
					end
				elseif(WeaponsStats[tool.Name].ShieldCooldown ~= nil) then
					if(WeaponsStats[tool.Name].ShieldCooldown ~= 0) then
						local temp_cd = WeaponsStats[tool.Name].ShieldCooldown
						WeaponsService:GetRaycast(0,0,tool.Name) --> position dont needed for the shield
						WeaponsStats[tool.Name].ShieldCooldown = 0
						task.delay(temp_cd,function()
							WeaponsStats[tool.Name].ShieldCooldown = temp_cd
						end)
					end
				end
			end
		end)
		ToolsSignal:RegisterConnection(tool.Equipped,function()
			for i,animationTrack : AnimationTrack in pairs(Players.LocalPlayer.Character.Humanoid.Animator:GetPlayingAnimationTracks()) do
				if(animationTrack.Name == "holdstaff" or animationTrack.Name == "attack" or animationTrack.Name == "walkstaff") then
					animationTrack.Looped = false
					animationTrack:Stop()
				end
			end
			if(WeaponsStats[tool.Name]) then
				SurvivorGui.AmmoFrame.Visible = true
				SurvivorGui.AmmoFrame.nme.Text = tool.Name
				if(WeaponsStats[tool.Name].Ammo and WeaponsStats[tool.Name].MaxAmmo) then
					SurvivorGui.AmmoFrame.ammo.Text = WeaponsStats[tool.Name].Ammo .. " / " .. WeaponsStats[tool.Name].MaxAmmo
				else
					SurvivorGui.AmmoFrame.ammo.Text = "inf"
				end
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
		ToolsSignal:RegisterConnection(tool.Unequipped,function()
			SurvivorGui.AmmoFrame.Visible = false
			PlayerEventTracker:UntrackUser(Players.LocalPlayer)
			for i,animationTrack : AnimationTrack in pairs(Players.LocalPlayer.Character.Humanoid.Animator:GetPlayingAnimationTracks()) do
				if(animationTrack.Name == "holdstaff" or animationTrack.Name == "attack" or animationTrack.Name == "walkstaff") then
					animationTrack.Looped = false
					animationTrack:Stop()
				end
			end
		end)
	end)
end

local function init_gui_signal(types)
	if(not types) then return end
	local MarketService = Knit.GetService("MarketService")
	if(types == "beast") then
		local beast_gui = Players.LocalPlayer.PlayerGui:WaitForChild("BeastGui")
		beast_gui.Enabled = true
		beast_gui.PlayGuide.Visible = true
		Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):GetPropertyChangedSignal("MoveDirection"):Once(function(...: any) 
			if(Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").MoveDirection ~= Vector3.zero) then
				beast_gui.PlayGuide.Visible = false
			end
		end)
		if(MarketService:GetProductFromData("ViewPlayerName") == true) then
			for i,plr in pairs(Players:GetPlayers()) do
				if(plr.Character) then
					if(plr.Name == Players.LocalPlayer.Name) then continue end
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
		SurvivorGui.PlayGuide.Visible = true
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
	local GameService = Knit.GetService("GameService")
	local WeaponsService = Knit.GetService("WeaponsService")
	local MarketService = Knit.GetService("MarketService")
	local night_charge = Players.LocalPlayer.PlayerGui:FindFirstChild("SurvivorGui").NightVisionCharge
	local nv_frame = Players.LocalPlayer.PlayerGui:FindFirstChild("SurvivorGui").NightVisionFrame
	if(self.nv_initialised) then
		ContextActionService:UnbindAction("NightVisionEvent")
		nv_frame.Visible = false
		if(self.nv_initialised.recv) then
			self.nv_initialised.recv:Disconnect()
			self.nv_initialised.recv = nil
		end
		if(self.nv_initialised.task) then
			task.cancel(self.nv_initialised.task)
			self.nv_initialised.task = nil
		end
		table.clear(self.nv_initialised)
		self.nv_initialised = nil
		for i,plr_part in pairs(Players.LocalPlayer.Character:GetChildren()) do
			if(plr_part:IsA("Tool") and plr_part.Name == "NV Batt") then
				plr_part:Destroy()
			end
		end
		for i,plr_part in pairs(Players.LocalPlayer.Backpack:GetChildren()) do
			if(plr_part:IsA("Tool") and plr_part.Name == "NV Batt") then
				plr_part:Destroy()
			end
		end
		night_charge.Value = 0
		TweenService:Create(nv_frame.Parent.NVBar.Bar,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,(night_charge.Value/100))}):Play()
	else
		self.nv_initialised = {
			recv = WeaponsService.NVBatteryClaimedSignal:Connect(function()
				if(GameService:isGameStarted() == true) then
					local battery = ReplicatedStorage.Weapons["NV Batt"]:Clone()
					battery.Parent = Players.LocalPlayer.Backpack
					battery.Activated:Once(function() 
						night_charge.Value = math.clamp(night_charge.Value+50,0,100)
						TweenService:Create(nv_frame.Parent.NVBar.Bar,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,(night_charge.Value/100))}):Play()
						battery:Destroy()
					end)
				end
			end);
			task = coroutine.create(function()
			end);
		}
		ContextActionService:BindAction("NightVisionEvent",function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
			if(inputState == Enum.UserInputState.End) then
				if(self.nv_initialised.event) then
					if(self.nv_initialised.task) then
						task.cancel(self.nv_initialised.task)
						self.nv_initialised.task = nil
					end
					self.nv_initialised.event = nil
					SoundService:PlayLocalSound(nv_frame.Parent.NV_OFF)
					nv_frame.Visible = false
				elseif(not self.nv_initialised.event) then
					if(self.nv_initialised.task) then
						task.cancel(self.nv_initialised.task)
						self.nv_initialised.task = nil
					end
					self.nv_initialised.event = true
					self.nv_initialised.task = coroutine.create(function(...) 
						while(night_charge.Value ~= 0) do
							task.wait(1)
							math.clamp(night_charge.Value-5,0,100)
							TweenService:Create(nv_frame.Parent.NVBar.Bar,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,(night_charge.Value/100))}):Play()
						end
						nv_frame.Visible = false
						TweenService:Create(nv_frame.Parent.NVBar.Bar,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,(night_charge.Value/100))}):Play()
					end)
					task.spawn(self.nv_initialised.task)
					SoundService:PlayLocalSound(nv_frame.Parent.NV_ON)
					nv_frame.Visible = true
					if(night_charge.Value <= 0) then
						nv_frame.Visible = false
						TweenService:Create(nv_frame.Parent.NVBar.Bar,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,(night_charge.Value/100))}):Play()
					end
				end
			end
		end,true,Enum.KeyCode.G)
		ContextActionService:SetTitle("NightVisionEvent","NV")
		ContextActionService:SetDescription("NightVisionEvent","Active the Night-vision")
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
		energyCharge.Value = 100
		TweenService:Create(energyBar.fill,TweenInfo.new(0.2),{Size = UDim2.fromScale((energyCharge.Value / 100),1)}):Play()
		if(self.temp_health_bar_signal.task) then
			task.cancel(self.temp_health_bar_signal.task)
			self.temp_health_bar_signal.task = nil
			self.temp_health_bar_signal.task = coroutine.create(function() 
				local percent = (energyCharge.Value / 100)
				while(true) do
					energyCharge.Value -= 1
					percent = (energyCharge.Value / 100)
					TweenService:Create(energyBar.fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(percent,1)}):Play()
					if(energyCharge.Value <= 0) then
						task.spawn(function()
							PropsService.ChangePropsSignal:Fire(
								Players.LocalPlayer.Character,
								"Humanoid",
								{props_name = "Health",props_value = 0}
							)
						end)
						break
					end
					task.wait(3)
				end
			end)
			task.spawn(self.temp_health_bar_signal.task)
		end
		self.temp_health_bar_signal.event = WeaponsService.BeastKilledPlayerSignal:Connect(function()
			math.clamp(energyCharge.Value+20,0,100)
		end)	
	else
		energyCharge.Value = 100
		TweenService:Create(energyBar.fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,1)}):Play()
		task.cancel(self.temp_health_bar_signal.task)
		self.temp_health_bar_signal.task = nil
		self.temp_health_bar_signal.event:Disconnect()
		self.temp_health_bar_signal.event = nil
		table.clear(self.temp_health_bar_signal)
		self.temp_health_bar_signal = nil
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
	local getDaggersPowerFn = ab.daggers
	if(not self.ability_component_data) then
		TweenService:Create(Sbar.Fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,0)}):Play()
		SpecialFrame.perc.Text = tostring(0)	
		SpecialFrame.AbilityCharge.Value = 0
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
					if(SpecialFrame.AbilityCharge.Value >= 30 and copyWeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown ~= 0) then
						SpecialFrame.AbilityCharge.Value -= math.clamp(30,0,100)
						TweenService:Create(Sbar.Fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,SpecialFrame.AbilityCharge.Value/100)}):Play()
						TweenService:Create(SpecialFrame.Sp1.ProgressBar,TweenInfo.new(WeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown),{Size = UDim2.fromScale(1,1)}):Play()
						SpecialFrame.perc.Text = tostring(SpecialFrame.AbilityCharge.Value)
						copyWeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown = 0
						getCutPowerFn()
						task.delay(WeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown,function()
							copyWeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown = WeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown
						end)
					end
				end
			end,false,Enum.KeyCode.Z)
			ContextActionService:BindAction("Daggers",function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
				if(inputState == Enum.UserInputState.End) then
					if(SpecialFrame.AbilityCharge.Value >= 70 and copyWeaponsStats.AbilityWeapon.Scythe.Daggers.AbilityCooldown ~= 0) then
						SpecialFrame.AbilityCharge.Value -= math.clamp(70,0,100)
						TweenService:Create(Sbar.Fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,SpecialFrame.AbilityCharge.Value/100)}):Play()
						SpecialFrame.perc.Text = tostring(SpecialFrame.AbilityCharge.Value)
						copyWeaponsStats.AbilityWeapon.Scythe.Daggers.AbilityCooldown = 0
						TweenService:Create(SpecialFrame.Sp2.ProgressBar,TweenInfo.new(WeaponsStats.AbilityWeapon.Scythe.Daggers.AbilityCooldown),{Size = UDim2.fromScale(1,1)}):Play()
						getDaggersPowerFn()
						task.delay(WeaponsStats.AbilityWeapon.Scythe.Daggers.AbilityCooldown,function()
							copyWeaponsStats.AbilityWeapon.Scythe.Daggers.AbilityCooldown = WeaponsStats.AbilityWeapon.Scythe.Daggers.AbilityCooldown
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
						TweenService:Create(SpecialFrame.Sp3.ProgressBar,TweenInfo.new(WeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.AbilityCooldown),{Size = UDim2.fromScale(1,1)}):Play()
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
					TweenService:Create(SpecialFrame.Sp1.ProgressBar,TweenInfo.new(WeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown),{Size = UDim2.fromScale(1,1)}):Play()
					getCutPowerFn()
					task.delay(WeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown,function()
						copyWeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown = WeaponsStats.AbilityWeapon.Scythe.CutPower.AbilityCooldown
					end)
				end
			end))
			self.ability_component_data.maid:giveTask(SpecialFrame.Sp2.Activated:Connect(function(inputObject: InputObject, clickCount: number) 
				if(SpecialFrame.AbilityCharge.Value >= 70 and copyWeaponsStats.AbilityWeapon.Scythe.Daggers.AbilityCooldown ~= 0) then
					SpecialFrame.AbilityCharge.Value -= math.clamp(70,0,100)
					TweenService:Create(Sbar.Fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,SpecialFrame.AbilityCharge.Value/100)}):Play()
					SpecialFrame.perc.Text = tostring(SpecialFrame.AbilityCharge.Value)
					TweenService:Create(SpecialFrame.Sp2.ProgressBar,TweenInfo.new(WeaponsStats.AbilityWeapon.Scythe.Daggers.AbilityCooldown),{Size = UDim2.fromScale(1,1)}):Play()
					copyWeaponsStats.AbilityWeapon.Scythe.Daggers.AbilityCooldown = 0
					getDaggersPowerFn()
					task.delay(WeaponsStats.AbilityWeapon.Scythe.Daggers.AbilityCooldown,function()
						copyWeaponsStats.AbilityWeapon.Scythe.Daggers.AbilityCooldown = WeaponsStats.AbilityWeapon.Scythe.Daggers.AbilityCooldown
					end)
				end
			end))
			self.ability_component_data.maid:giveTask(SpecialFrame.Sp3.Activated:Connect(function(inputObject: InputObject, clickCount: number) 
				if(SpecialFrame.AbilityCharge.Value >= 90 and copyWeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.AbilityCooldown ~= 0) then
					SpecialFrame.AbilityCharge.Value -= math.clamp(90,0,100)
					TweenService:Create(Sbar.Fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,SpecialFrame.AbilityCharge.Value/100)}):Play()
					SpecialFrame.perc.Text = tostring(SpecialFrame.AbilityCharge.Value)
					copyWeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.AbilityCooldown = 0
					TweenService:Create(SpecialFrame.Sp3.ProgressBar,TweenInfo.new(WeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.AbilityCooldown),{Size = UDim2.fromScale(1,1)}):Play()
					getBlastPowerFn(Players.LocalPlayer.Character.HumanoidRootPart.Position,Mouse.Hit.Position)
					task.delay(WeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.AbilityCooldown,function()
						copyWeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.AbilityCooldown = WeaponsStats.AbilityWeapon.Scythe.MagnecticBlaster.AbilityCooldown
					end)
				end	
			end))
			self.ability_component_data.BeastVisibility = function(parent)
				local instance = Instance.new("PointLight",parent)
				instance.Shadows = true
				instance.Brightness = 5
				instance.Range = 100
				instance.Color = Color3.fromRGB(255,0,0)
				return instance	
			end
			self.ability_component_data.BeastVisibility = self.ability_component_data.BeastVisibility(Players.LocalPlayer.Character.HumanoidRootPart)
			PlayersDistance:StartDistanceData()	
		end
	else
		task.cancel(self.ability_component_data.task)
		self.ability_component_data.task = nil
		self.ability_component_data.maid:clean()
		self.ability_component_data.maid = nil
		if(self.ability_component_data.BeastVisibility) then
			if(self.ability_component_data.BeastVisibility.Destroy) then
				self.ability_component_data.BeastVisibility:Destroy()
				self.ability_component_data.BeastVisibility = nil
			end
		end
		table.clear(self.ability_component_data)
		self.ability_component_data = nil
		TweenService:Create(Sbar.Fill,TweenInfo.new(0.2),{Size = UDim2.fromScale(1,0)}):Play()
		SpecialFrame.perc.Text = tostring(0)	
		SpecialFrame.AbilityCharge.Value = 0
		ContextActionService:UnbindAction("CutPowerAction")
		ContextActionService:UnbindAction("Daggers")
		ContextActionService:UnbindAction("MagneticBlast")
		PlayersDistance:StopDistanceData()
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
			if(GameService:isGameStarted() == true) then
				local game_info = Players.LocalPlayer.PlayerGui.MenuGui.GameInfo
				game_info.Text = "Round in progress. (Wait until the game end)"
				Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").Enabled = true
				SoundService:PlayLocalSound(SoundService["door open metal"])
				TweenService:Create(Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").MainFrame.GuiWall1,TweenInfo.new(2.9),{Position = UDim2.fromScale(0,-0.9)}):Play()
				TweenService:Create(Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").MainFrame.GuiWall2,TweenInfo.new(2.9),{Position = UDim2.fromScale(0,1.2)}):Play()
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
			if(self.temp_health_bar_signal) then
				init_beast_temp_health_bar(self,"beast")
			end
			if(self.ability_component_data) then
				init_ability(self,"beast")
			end
			ToolsSignal:UnregisterAll()
			WeaponsService:DestroyPlayerComponent()
			return
		end
		ToolsSignal:UnregisterAll()
		TweenService:Create(Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").MainFrame.GuiWall1,TweenInfo.new(0.2),{Position = UDim2.fromScale(0,-0.1)}):Play()
		TweenService:Create(Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").MainFrame.GuiWall2,TweenInfo.new(0.2),{Position = UDim2.fromScale(0,0.5)}):Play()
		if(self.health_bar_initialised) then
			init_health_bar_signal(self,"beast")
			local beast_gui = Players.LocalPlayer.PlayerGui:WaitForChild("BeastGui")
			beast_gui.Enabled = false
			beast_gui.PlayGuide.Visible = true
		end
		if(self.nv_initialised) then
			init_nightvision_signal(self,"survivor")
		end
		if(self.temp_health_bar_signal) then
			init_beast_temp_health_bar(self,"beast")
		end
		if(self.ability_component_data) then
			init_ability(self,"beast")
		end
		Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").MainFrame.GuiWall1.desc.Text = "GAME ENDS"
		Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").MainFrame.GuiWall2.desc.Text = "NEXT ROUND WILL START SHORTLY"
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
		task.delay(2,function()
			Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").MainFrame.GuiWall1.desc.Text = ""
			Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").MainFrame.GuiWall2.desc.Text = ""
		end)
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
		task.delay(2,function()
			Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").GameResults.Visible = false
			for i,frame in pairs(Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").GameResults.Damages.ScrollingFrame:GetChildren()) do
				if(frame:IsA("TextLabel")) then
					frame:Destroy()
				end
			end
			Players.LocalPlayer.PlayerGui:WaitForChild("MenuGui").GameResults.total.Text = ("The Beast took 0 total damage")
		end)
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
