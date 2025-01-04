local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local Maid = require(ReplicatedStorage:WaitForChild("Packages").Maid)
local FormatNumberAlt = require(ReplicatedStorage:WaitForChild("Packages").FormatNumberAlt)

local module = Knit.CreateController({
	Name = "IntroController";
	PassesId = "PRIVATE";
	Upgrades = "PRIVATE";
	ProductsId = "PRIVATE";
)}

--[[
	@LoadAnimation(...)
	@desc: require and start the introGui animation, when the play button is clicked the menuGui appear.
	@params:...
	@return nil
]]
function module:LoadAnimation(...)
	if(self.maid_intro_interaction) then return end
	local GameService = Knit.GetService("GameService")
	self.maid_intro_interaction = Maid.new()
	local IntroFrame = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("IntroGui"):WaitForChild("IntroFrame")
	local LoadBar = IntroFrame.LoadBar
	local fill = LoadBar.fill
	local GLogo = IntroFrame.GLogo
	LoadBar.Visible = true
	local position_tween = TweenService:Create(LoadBar,TweenInfo.new(1),{Position = UDim2.new(LoadBar.Position.X.Scale,LoadBar.Position.X.Offset,0.5,0)})
	position_tween:Play()
	position_tween.Completed:Wait()
	ContentProvider:PreloadAsync({game})
	ContentProvider:PreloadAsync({workspace})
	TweenService:Create(fill,TweenInfo.new(0.2),{
		Size = UDim2.fromScale(0.75,1)
	}):Play()
	ContentProvider:PreloadAsync({ReplicatedStorage})
	TweenService:Create(fill,TweenInfo.new(0.2),{
		Size = UDim2.fromScale(1,1)
	}):Play()
	LoadBar.TextLabel.Text = "Loaded !"
	task.wait(2)
	local tween_end_loading = TweenService:Create(LoadBar,TweenInfo.new(1),{Position = UDim2.new(0.5,-150,-0.5,0)})
	tween_end_loading:Play()
	tween_end_loading.Completed:Wait()
	GLogo.Visible = true
	LoadBar.Visible = false
	local anim = TweenService:Create(GLogo,TweenInfo.new(0.7),{Position = UDim2.fromScale(0.5,0.5)})
	anim:Play()
	anim.Completed:Wait()
	GLogo.PlayButton.Visible = true
	self.maid_intro_interaction:giveTask(GLogo.PlayButton.Activated:Connect(function()
		GLogo.PlayButton.Text = "Die"
		IntroFrame.Visible = false
		GameService.PlayerIsLoadedSignal:Fire()
		if(GameService:isGameStarted() == true) then
			local game_info = Players.LocalPlayer.PlayerGui.MenuGui.GameInfo
			game_info = "Wait until the game end."
			GameService:EnableSpectate(Players.LocalPlayer)
		end
		self:MenuInteraction()
		self.maid_intro_interaction:clean()
	end))
end

--[[
	@MenuInteraction(...)
	@desc: load and start the menu with current game information and other ui's interaction.
	@params: ...
	@return: nil
]]
function module:MenuInteraction(...)
	if(self.maid_menu_interaction) then return end
	self.maid_menu_interaction = Maid.new()
	local MenuGui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MenuGui")
	MenuGui.Enabled = true
	local gameInfoLabel = MenuGui:WaitForChild("GameInfo")
	local knitGameService = Knit.GetService("GameService")
	knitGameService.UpdateClientSignal:Connect(function(text : string)
		if(not text) then return end
		gameInfoLabel.Text = text
	end)
	self:UiComponents()
end

--[[
	@UiComponents(...)
	@desc: bind every ui items like Shop,Buttons,Upgrades,Passes etc.
	@params: none
	@return: nil
]]
function module:UiComponents(...)
	if(not self.maid_menu_interaction) then return end
	local MenuGui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MenuGui")
	local MenuButtons = MenuGui:WaitForChild("MenuButtons")
	local ShopFrame = MenuGui:WaitForChild("ShopFrame")
	local BttnShop = MenuButtons:WaitForChild("Center").BttShop
	local PointsLabel = ShopFrame.points
	MenuButtons.Center.TemporaryBeast.buy.Visible = true
	self.maid_menu_interaction:giveTask(BttnShop.Activated:Connect(function()
		ShopFrame.Visible = not ShopFrame.Visible
	end))
	self.maid_menu_interaction:giveTask(ShopFrame.CloseMenu.Activated:Connect(function()
		ShopFrame.Visible = false
	end))
	self.maid_menu_interaction:giveTask(ShopFrame.passes.Activated:Connect(function()
		ShopFrame.Shop.Passes.Visible = true
		ShopFrame.Shop.Upgrades.Visible = false
	end))
	self.maid_menu_interaction:giveTask(ShopFrame.upgrades.Activated:Connect(function()
		ShopFrame.Shop.Passes.Visible = false
		ShopFrame.Shop.Upgrades.Visible = true
	end))
	for i,bttn_pass in pairs(ShopFrame.Shop.Passes:GetChildren()) do
		if(bttn_pass:IsA("Frame")) then
			self.maid_menu_interaction:giveTask(bttn_pass:FindFirstChildOfClass("TextButton").Activated:Connect(function()
				if(self.PassesId[bttn_pass.Name]) then
					MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer,self.PassesId[bttn_pass.Name])
				end
			end))
		end
	end
	for i,bttn_upgrade in pairs(ShopFrame.Shop.Upgrades:GetChildren()) do
		if(bttn_upgrade:IsA("Frame")) then
			self.maid_menu_interaction:giveTask(bttn_upgrade:FindFirstChildOfClass("TextButton").Activated:Connect(function()
				if(self.Upgrades[bttn_upgrade.Name]) then
					local MarketService = Knit.GetService("MarketService")
					if(bttn_upgrade.Name == "health") then
						local checkVip = Knit.GetService("ProfileStoreService"):GetProfile()
						if(not checkVip.Products.VIP) then return end
						MarketService:UpgradesPurchase({
							["Name"] = bttn_upgrade.Name;
							["cost"] = self.Upgrades[bttn_upgrade.Name]
						})
					else
						MarketService:UpgradesPurchase({
							["Name"] = bttn_upgrade.Name;
							["cost"] = self.Upgrades[bttn_upgrade.Name]
						})
					end
				end
			end))
		end
	end
	self.maid_menu_interaction:giveTask(RunService.Heartbeat:Connect(function(deltaTime: number) 
		PointsLabel.Text = "Points: " .. FormatNumberAlt.FormatCompact(Players.LocalPlayer:WaitForChild("leaderstats"):WaitForChild("Points").Value,5)
	end))
	self.maid_menu_interaction:giveTask(MenuButtons.Center.TemporaryBeast.buy.Activated:Connect(function()
		MarketplaceService:PromptProductPurchase(Players.LocalPlayer,self.ProductsId.Tempbeast)
	end))
end

function module:InitSpectate(...)
	local GameService = Knit.GetService("GameService")
	local SpectateFrame = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MenuGui"):WaitForChild("SpectateControl")
	local SpectateNext = SpectateFrame:WaitForChild("Next")
	local SpectatePrev = SpectateFrame:WaitForChild("Last")
	local count = 1
	GameService.EnabledSpectateControl:Connect(function(state)
		if(state == true) then
			SpectateFrame.Parent.MainFrame.Visible = false
			SpectateFrame.Visible = true
			if(not self.spectate_maid_data) then
				self.spectate_maid_data = Maid.new()
			end
			local plrs = GameService:getPlayersInGame()
			if(#plrs > 0) then
				local getCharacter = workspace:FindFirstChild(plrs[math.clamp(count+1,1,#plrs)])
				if(getCharacter) then 
					workspace.CurrentCamera.CameraSubject = getCharacter:FindFirstChild("Humanoid")
					workspace.CurrentCamera.CFrame = getCharacter:FindFirstChild("HumanoidRootPart").CFrame
					SpectateFrame.Nickname.Text = "@" .. tostring(getCharacter.Name)
				end
			end
			self.spectate_maid_data:giveTask(SpectateNext.Activated:Connect(function()
				local getPlayersInGame = GameService:getPlayersInGame()
				if(#getPlayersInGame > 0) then
					local getCharacter = workspace:FindFirstChild(getPlayersInGame[math.clamp(count+1,1,#getPlayersInGame)])
					if(not getCharacter) then return end
					workspace.CurrentCamera.CameraSubject = getCharacter:FindFirstChild("Humanoid")
					workspace.CurrentCamera.CFrame = getCharacter:FindFirstChild("HumanoidRootPart").CFrame
					SpectateFrame.Nickname.Text = "@" .. tostring(getCharacter.Name)
					math.clamp(count+1,1,#getPlayersInGame)
				end
			end))
			self.spectate_maid_data:giveTask(SpectatePrev.Activated:Connect(function()
				local getPlayersInGame = GameService:getPlayersInGame()
				if(#getPlayersInGame > 0) then
					local getCharacter = workspace:FindFirstChild(getPlayersInGame[math.clamp(count-1,1,#getPlayersInGame)])
					if(not getCharacter) then return end
					workspace.CurrentCamera.CameraSubject = getCharacter:FindFirstChild("Humanoid")
					workspace.CurrentCamera.CFrame = getCharacter:FindFirstChild("HumanoidRootPart").CFrame
					SpectateFrame.Nickname.Text = "@" .. tostring(getCharacter.Name)
					math.clamp(count-1,1,#getPlayersInGame)
				end
			end))
		else
			SpectateFrame.Parent.MainFrame.Visible = true
			SpectateFrame.Visible = false
			workspace.CurrentCamera.CameraSubject = Players.LocalPlayer.Character:FindFirstChild("Humanoid")
			workspace.CurrentCamera.CFrame = Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart").CFrame
			if(self.spectate_maid_data) then
				self.spectate_maid_data:clean()
				self.spectate_maid_data = nil
			end
		end
	end)
end

function module:KnitStart(...)
	self:InitSpectate(...)
	self:LoadAnimation(...)
end

return module
