local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.Roact)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Packages.Promise)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local PlayerEventTracker = require(ReplicatedStorage.Packages.PlayerEventTracker)
local WeaponsComponent = require(ServerScriptService.Game.Utils.WeaponsComponent)
local DropsComponent = require(ServerScriptService.Game.Utils.DropsComponent)
local ElectricDoorComponent = require(ServerScriptService.Game.Utils.ElectricDoorComponent)

local module = Knit.CreateService({
	Name = "GameService";
	Client = {
		UpdateClientSignal = Knit.CreateSignal();
		InitGameSignal = Knit.CreateSignal();
		InitComponentsSignal = Knit.CreateSignal();
		InitGameResults = Knit.CreateSignal();
		PlayerIsLoadedSignal = Knit.CreateSignal();
		EnabledSpectateControl = Knit.CreateSignal();
	};
	State = {
		started = false;
		intermission = 30;
		player_amount_min = 4;
		StartSignal = Signal.new();
		current_signal_started = nil;
		MapChoosen = "[^/%p]";
		playersStats = {};
		beastStats = {};
		heartbeat_thread = nil,
		loaded_players = {}
	}
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

local function remove(tA,tB)
	for i,v in pairs(tB) do
		if(tA[i]) then
			tA[i] = nil
		end
	end
end

local function setSpawn(player_name,spawn_cf)
	if(not player_name) then return end
	local player = Players:FindFirstChild(player_name)
	if(not player) then return end
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	humanoidRootPart.CFrame = spawn_cf
	return humanoidRootPart.CFrame
end

local function addInstanceToChar(parent,instance_type,props,k)
	return Roact.mount(Roact.createElement(instance_type,props),parent,k)
end

local function each(t,func,arg)
	for i,v in pairs(t) do
		func(i,arg)
	end
end

local function randomPlayerSpawn(map)
	local spawns = workspace:WaitForChild(map):WaitForChild("MapData").PlayerSpawns:GetChildren()
	return spawns[math.random(1,#spawns)].CFrame
end

local function randomBeastSpawn(map)
	local spawns = workspace:WaitForChild(map):WaitForChild("MapData").BeastSpawns:GetChildren()
	return spawns[math.random(1,#spawns)].CFrame
end

local function setLightToHRP(player_character)
	if(not player_character) then return end
	local light = Instance.new("PointLight",player_character.HumanoidRootPart)
	light.Brightness = 2
	light.Color = Color3.new(1, 1, 1)
	light.Shadows = true
	light.Range = 12
	light.Name = "PlayerLightComponent"
	return light
end

function module:LoadingStartSignal(...)
	if(not self.State) then return end
	if(not self.State.started) then return end
	local Maps = ServerStorage.Maps:GetChildren()
	local random = Random.new():NextInteger(1,3)
	local ChoosenMap = Maps[random]
	if(ChoosenMap) then
		local clone = ChoosenMap:Clone()
		clone.Parent = workspace
		for i,plr_loaded in pairs(self.State.loaded_players) do
			if(Players:FindFirstChild(plr_loaded)) then
				self.Client.InitGameSignal:Fire(Players:FindFirstChild(plr_loaded),"Initializing scripts/spawns")
			end
		end
		self.State.MapChoosen = clone.Name
		if(clone:FindFirstChild("MapParts")) then
			for i,object in pairs(clone.MapParts:GetChildren()) do
				if(string.find(object.Name,"ElectricalDoor")) then
					Promise.new(function()
						local class = ElectricDoorComponent.new(object)
					end):catch(warn)
				end
			end
		else
			for i,object in pairs(clone.Furniture:GetChildren()) do
				if(string.find(object.Name,"ElectricalDoor")) then
					Promise.new(function()
						local class = ElectricDoorComponent.new(object)
					end):catch(warn)
				end
			end
		end
		--[Disabled cause DropsComponent already drop NV-Battery]
		--for i,WeaponParts in pairs(clone.MapData.WeaponDrops:GetChildren()) do
		--	--WeaponsComponent.SpawnNVBatteryAtLocation(WeaponsComponent,WeaponParts.Position)
		--end
		DropsComponent:StartDrops()
		local __data__ = self:LoadGame()
	end	
end

function module:OnSignalStart(...)
	if(not self.State) then return end
	if(self.State.current_signal_started) then
		task.cancel(self.State.current_signal_started)
		return
	end
	self.State.current_signal_started = coroutine.create(function() 
		for i = self.State.intermission,0,-1 do
			self.Client.UpdateClientSignal:FireAll(("Game start in %d second(s)"):format(i))
			task.wait(1)
		end
		self.Client.UpdateClientSignal:FireAll("Initializing game (not finished)")
		self.State.started = true
		self:LoadingStartSignal()
	end)
	task.spawn(self.State.current_signal_started)
end

function module:LoadGame(map_name)
	local data = {}
	for i,players in pairs(self.State.loaded_players) do
		if(not data[players]) then
			local getPlayerFromName = Players:FindFirstChild(players)
			if(not getPlayerFromName) then continue end
			local profile = Knit.GetService("ProfileStoreService"):GetProfile(getPlayerFromName)
			data[players] = Random.new():NextInteger(1,10)
			if(profile) then
				if(profile.Data.Products.temp_beast) then
					data[players] += 100
					Knit.GetService("MarketService"):RemoveProductFromData(getPlayerFromName,"temp_beast")
				end
				if(profile.Data.Products["10x beast"]) then
					data[players] += 5
				end
			end
		end
	end
	local beastChoosen = findMax(data)
	local juggernautChoosen = findMax(function() 
		local copy = data
		for players,value in pairs(copy) do
			local getPlayerFromName = Players:FindFirstChild(players)
			if(not getPlayerFromName) then continue end
			local profile = Knit.GetService("ProfileStoreService"):GetProfile(getPlayerFromName)
			if(profile) then
				if(profile.Data.Products["3x juggernaut"]) then
					value += 3
				end
				if(profile.Data.Products["juggernaut"]) then
					value += 3
				end
			end
		end
		remove(copy,beastChoosen)
		local juggernaut = findMax(copy)
		return juggernaut
	end)
	local survivors = {}
	local copy_data = data
	remove(copy_data,beastChoosen)
	remove(copy_data,juggernautChoosen)
	survivors = copy_data
	each(survivors,function(a0,a1) 
		setSpawn(a0,a1)
		local player = Players:FindFirstChild(a0)
		if(not player) then 
			if(self.State.playersStats[a0]) then
				table.clear(self.State.playersStats[a0])
				self.State.playersStats[a0] = nil
			end
			return 
		end
		local profile = Knit.GetService("ProfileStoreService"):GetProfile(player)
		if(profile) then
			if(profile.Data.Products.VIP) then
				player.Character:FindFirstChild("Humanoid").MaxHealth = 140
				player.Character:FindFirstChild("Humanoid").Health = 140
			end
		end
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
		self.Client.InitComponentsSignal:Fire(player,"survivor")
		self.State.playersStats[player.Name] = {}
		local instance_data = setLightToHRP(character)
		PlayerEventTracker:TrackUser(player,player.Character.Humanoid.Died,function()
			if(self.State.playersStats[player.Name]) then
				table.clear(self.State.playersStats[player.Name])
				self.State.playersStats[player.Name] = nil
				self.Client.EnabledSpectateControl:Fire(player,true)
				self.Client.InitGameResults:Fire(player,"dead")
			end
			instance_data:Destroy()
			PlayerEventTracker:UntrackUser(player.Name)
		end)
	end,randomPlayerSpawn(self.State.MapChoosen))
	each(beastChoosen,function(a0,a1) 
		setSpawn(a0,a1)
		local player = Players:FindFirstChild(a0)
		if(not player) then 
			if(self.State.beastStats[a0]) then
				table.clear(self.State.beastStats[a0])
				self.State.beastStats[a0] = nil
			end
		end
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
		addInstanceToChar(character.Humanoid,"HumanoidDescription",{
			RightArm = 0;
			RightArmColor = Color3.fromRGB(0,0,0);
			LeftArm = 0;
			LeftArmColor = Color3.fromRGB(0,0,0);
			RightLeg = 0;
			RightLegColor = Color3.fromRGB(0,0,0);
			LeftLeg = 0;
			LeftLegColor = Color3.fromRGB(0,0,0);
			Torso = 0;
			TorsoColor = Color3.fromRGB(0,0,0);
			Head = 0;
			HeadColor = Color3.fromRGB(0,0,0);
			HatAccessory = 0;
			BackAccessory = 0;
			HairAccessory = 0;
			FaceAccessory = 0;
			FrontAccessory = 0;
			ShouldersAccessory = 0;
			WaistAccessory = 0;
			NeckAccessory = 0
		},"BeastTransformDescription")
		for i,character_part in pairs(character:GetChildren()) do
			if(character_part:IsA("Part")) then
				character_part.Transparency = 0.3
				character_part.Color = Color3.new(0,0,0)
			end
		end
		character.Humanoid:ApplyDescription(character.Humanoid:FindFirstChild("BeastTransformDescription"))
		addInstanceToChar(character,"StringValue",{Value = "Beast"},"mode_selector")
		local copyDamageGui = ServerStorage.Resources.DamageSign:Clone()
		copyDamageGui.Parent = character.Head
		character.Humanoid.MaxHealth = 250
		character.Humanoid.WalkSpeed = 26
		character.Humanoid.Health = character.Humanoid.MaxHealth
		self.Client.InitComponentsSignal:Fire(player,"beast")
		self.State.beastStats[player.Name] = {}
		PlayerEventTracker:TrackUser(player,player.Character.Humanoid.Died,function()
			if(self.State.beastStats[player.Name]) then
				table.clear(self.State.beastStats[player.Name])
				self.State.beastStats[player.Name] = nil
			end
			PlayerEventTracker:UntrackUser(player.Name)
		end)
	end,randomBeastSpawn(self.State.MapChoosen))
	each(juggernautChoosen,function(a0,a1) 
		setSpawn(a0,a1)
		local player = Players:FindFirstChild(a0)
		if(not player) then
			if(self.State.playersStats[a0]) then
				table.clear(self.State.playersStats[a0])
				self.State.playersStats[a0] = nil
			end
			return
		end
		local profile = Knit.GetService("ProfileStoreService"):GetProfile(player)
		player.Character:FindFirstChild("Humanoid").MaxHealth += 50
		player.Character:FindFirstChild("Humanoid").Health = player.Character:FindFirstChild("Humanoid").MaxHealth
		if(profile) then
			if(profile.Data.Products.VIP) then
				player.Character:FindFirstChild("Humanoid").MaxHealth += 20
				player.Character:FindFirstChild("Humanoid").Health = player.Character:FindFirstChild("Humanoid").MaxHealth
			end
		end
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
		local cloneJuggernautSign = ServerStorage.Resources.JuggernautSign:Clone()
		cloneJuggernautSign.Parent = character.Head
		local instance_data = setLightToHRP(character)
		self.Client.InitComponentsSignal:Fire(player,"juggernaut")
		self.State.playersStats[player.Name] = {}
		PlayerEventTracker:TrackUser(player,player.Character.Humanoid.Died,function()
			if(self.State.playersStats[player.Name]) then
				table.clear(self.State.playersStats[player.Name])
				self.State.playersStats[player.Name] = nil
				self.Client.EnabledSpectateControl:Fire(player,true)
				self.Client.InitGameResults:Fire(player,"dead")
				instance_data:Destroy()
			end
			PlayerEventTracker:UntrackUser(player.Name)
		end)
	end,randomPlayerSpawn(self.State.MapChoosen))
	self:UpdateGameData({Survivors = survivors,Juggernaut = juggernautChoosen,Beast = beastChoosen})
	for i,plr in pairs(Players:GetPlayers()) do
		if(self.State.beastStats[plr.Name]) then continue end
		if(self.State.playersStats[plr.Name]) then continue end
		if(not self.State.playersStats[plr.Name]) then
			self.Client.EnabledSpectateControl:Fire(plr,true)
		elseif(not self.State.beastStats[plr.Name]) then
			self.Client.EnabledSpectateControl:Fire(plr,true)
		end
	end
	return data
end

function module:UpdatePlayerProfile(player,data)
	if(not player) then return end
	if(self.State.beastStats[player.Name]) then
		if(not self.State.beastStats[player.Name].DamageDealt) then
			self.State.beastStats[player.Name].DamageDealt = 0
		end
		self.State.beastStats[player.Name].DamageDealt += data.damage
	elseif(self.State.playersStats[player.Name]) then
		if(not self.State.playersStats[player.Name].DamageDealt) then
			self.State.playersStats[player.Name].DamageDealt = 0
		end
		self.State.playersStats[player.Name].DamageDealt += data.damage
	end
end

function module:UpdateGameData(data)
	if(not data) then return end
	local signal = Signal.new()
	self.State.heartbeat_thread = RunService.Heartbeat:Connect(function(dt)
		local value = 0
		local survivor_value = 0
		for i,v in pairs(self.State.beastStats) do
			if(i) then 
				value += 1
			end
		end
		for j,k in pairs(self.State.playersStats) do
			if(j) then
				survivor_value += 1
			end
		end
		if(value <= 0) then
			signal:Fire("beast-loose")	
		elseif(survivor_value <= 0) then
			signal:Fire("survivor-loose")
		end
	end)
	signal:Once(function(ref)
		if(ref == "beast-loose") then
			local copy_survivor_data = TableUtil.Copy(self.State.playersStats,true)
			self.Client.InitGameResults:FireAll(copy_survivor_data,"damage_total_taken")
		elseif(ref == "survivor-loose") then
			local copy_beast_data = TableUtil.Copy(self.State.beastStats,true)
			self.Client.InitGameResults:FireAll(copy_beast_data)
		end
		DropsComponent:CancelDrops()
		self.State.heartbeat_thread:Disconnect()
		self.State.heartbeat_thread = nil
		self.State.beastStats = {}
		self.State.playersStats = {}
		if(self.State.current_signal_started) then
			task.cancel(self.State.current_signal_started)
			self.State.current_signal_started = nil
		end
		self.State.started = false
		for i,plr in pairs(Players:GetPlayers()) do
			if(#plr.Backpack:GetChildren() > 0) then
				for i,tool in pairs(plr.Backpack:GetChildren()) do
					if(tool) then
						tool:Destroy()
					end
				end
			else
				for i,tool in pairs(plr.Character:GetChildren()) do
					if(tool:IsA("Tool")) then
						tool:Destroy()
					elseif(tool.Name == "mode_selector") then
						tool:Destroy()
					elseif(tool.Name == "JuggernautSign") then
						tool:Destroy()
					elseif(tool.Name == "HumanoidRootPart") then
						if(tool:FindFirstChildOfClass("PointLight")) then
							tool:FindFirstChildOfClass("PointLight"):Destroy()
						end
					elseif(tool.Name == "Shield") then
						tool:Destroy()
					end
				end
			end
			if(PlayerEventTracker:GetUserTracker(plr.Name)) then
				PlayerEventTracker:UntrackUser(plr.Name)
			end
		end
		WeaponsComponent.CleanNVBattery(WeaponsComponent)
		ElectricDoorComponent:CleanAll()
		workspace:FindFirstChild(self.State.MapChoosen):Destroy()
		self.State.MapChoosen = "[^/%p]"
		for i,plr in pairs(Players:GetPlayers()) do
			self.Client.EnabledSpectateControl:Fire(plr,false)
		end
		self.Client.UpdateClientSignal:FireAll("Initialising game in 5 second(s)")
		task.delay(5,function()
			if(#self.State.loaded_players >= self.State.player_amount_min) then
				if(not self.State.current_signal_started) then
					self.State.StartSignal:Fire("Game intermision signal")
				end
			else
				if(self.State.current_signal_started) then
					self.State.StartSignal:Fire("Cancelling game intermission")
				end
				self.Client.UpdateClientSignal:FireAll(("Darkness 2 need %d players to start."):format(self.State.player_amount_min))
			end
		end)
	end)
	return signal	
end

function module:playerIsInGame(player,plr)
	if(not player) then return end
	if(not plr) then return end
	if(not self.State.playersStats[plr.Name]) then 
		return false 
	elseif(not self.State.beastStats[plr.Name]) then
		return false
	end
	return true
end

function module:EnableSpectate(player,plr)
	if(not player) then return end
	if(not plr) then return end
	if(not self.State.playersStats[plr.Name]) then
		self.Client.EnabledSpectateControl:Fire(plr,true)
	elseif(not self.State.beastStats[plr.Name]) then
		self.Client.EnabledSpectateControl:Fire(plr,true)
	end
end

function module:isGameStarted(player)
	if(self.State.started) then
		return true
	else
		return false
	end
end

function module:getPlayersInGame(player)
	if(not player) then return end
	local players = {}
	for i,plr in pairs(Players:GetPlayers()) do
		if(self.State.playersStats[plr.Name]) then
			table.insert(players,plr.Name)
		elseif(self.State.beastStats[plr.Name]) then
			table.insert(players,plr.Name)
		else
			continue
		end
	end
	return players
end

function module.Client:EnableSpectate(player,plr)
	return self.Server:EnableSpectate(player,plr)
end

function module.Client:isGameStarted(player)
	return self.Server:isGameStarted(player)
end

function module.Client:getPlayersInGame(player)
	return self.Server:getPlayersInGame(player)
end

function module.Client:playerIsInGame(player,plr)
	return self.Server:playerIsInGame(player,plr)
end

function module:KnitStart(...)
	self.State.StartSignal:Connect(function()
		self:OnSignalStart()
	end)
	self.Client.PlayerIsLoadedSignal:Connect(function(player)
		if(not player) then return end
		if(table.find(self.State.loaded_players,player.Name)) then return end
		table.insert(self.State.loaded_players,player.Name)
		if(#self.State.loaded_players >= self.State.player_amount_min) then
			if(not self.State.current_signal_started) then
				self.State.StartSignal:Fire("Game intermision signal")
			end
		else
			if(self.State.current_signal_started) then
				self.State.StartSignal:Fire("Cancelling game intermission")
			end
			self.Client.UpdateClientSignal:FireAll(("Darkness 2 need %d players to start."):format(self.State.player_amount_min))
		end
	end)
	Players.PlayerRemoving:Connect(function(player : Player)
		if(not player) then return end
		if(table.find(self.State.loaded_players,player.Name)) then
			table.remove(self.State.loaded_players,table.find(self.State.loaded_players,player.Name))
		end
		if(#self.State.loaded_players >= self.State.player_amount_min) then
			if(not self.State.current_signal_started) then
				self.State.StartSignal:Fire("Game intermision signal")
			end
		else
			if(self.State.current_signal_started) then
				self.State.StartSignal:Fire("Cancelling game intermission")
			end
			self.Client.UpdateClientSignal:FireAll(("Darkness 2 need %d players to start."):format(self.State.player_amount_min))
		end
		if(self.State.playersStats[player.Name]) then
			table.clear(self.State.playersStats[player.Name])
			self.State.playersStats[player.Name] = nil
		elseif(self.State.beastStats[player.Name]) then
			table.clear(self.State.beastStats[player.Name])
			self.State.beastStats[player.Name] = nil
		end
	end)
end

return module
