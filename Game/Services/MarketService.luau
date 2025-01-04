local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local module = Knit.CreateService({
	Name = "MarketService";
	Client = {}
})

function module:UpgradesPurchase(player: Instance, Info)
	local leaderstats = player:WaitForChild("leaderstats")
	local Points = leaderstats:WaitForChild("Points")
	local findProfile = Knit.GetService("ProfileStoreService"):GetProfile(player)
	if(not findProfile) then return false end
	if(not findProfile.Data.Products[Info.Name] and Points.Value >= Info.cost) then
		findProfile.Data.Products[Info.Name] = true
		Points.Value -= Info.cost
		return true
	elseif(findProfile.Data.Products[Info.Name]) then
		return true
	end
	return false
end

function module:ProductPurchase(player: Instance, Info)
	if(not player or not Info) then return end
	local findProfile = Knit.GetService("ProfileStoreService"):GetProfile(player)
	if(not findProfile) then return Enum.ProductPurchaseDecision.NotProcessedYet end
	if(not findProfile.Data.Products["temp_beast"]) then
		findProfile.Data.Products["temp_beast"] = Info.PurchaseId
	end	
end

function module:GetProductFromData(player,product_name)
	if(not player or not product_name) then return end
	local findProfile = Knit.GetService("ProfileStoreService"):GetProfile(player)
	if(not findProfile) then return "System error, canno't find player profile" end
	if(findProfile.Data.Products[product_name]) then
		return true
	end
	return false
end

function module:RemoveProductFromData(player, product_name)
	if(not player or not product_name) then return end
	local findProfile = Knit.GetService("ProfileStoreService"):GetProfile(player)
	if(not findProfile) then return "System error, canno't find player profile" end
	if(findProfile.Data.Products[product_name]) then
		findProfile.Data.Products[product_name] = nil
		return true
	end
	return false
end

function module.Client:GetProductFromData(player,product_name)
	return self.Server:GetProductFromData(player,product_name)
end

function module.Client:RemoveProductFromData(player,product_name)
	return self.Server:RemoveProductFromData(player,product_name)
end

function module.Client:UpgradesPurchase(player,info)
	return self.Server:UpgradesPurchase(player,info)
end

function module:KnitStart(...)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Instance, gamePassId: number, wasPurchased: boolean) 
		if(player)then
			local info_id = MarketplaceService:GetProductInfo(gamePassId,Enum.InfoType.GamePass)
			local findProfile = Knit.GetService("ProfileStoreService"):GetProfile(player)
			if(not findProfile) then return Enum.ProductPurchaseDecision.NotProcessedYet end
			if(wasPurchased) then
				if(not findProfile.Data.Products[info_id.Name]) then
					findProfile.Data.Products[info_id.Name] = gamePassId
				end		
			end
		end
	end)
	MarketplaceService.ProcessReceipt = function(reiceptInfo)
		local player = Players:GetPlayerByUserId(reiceptInfo.PlayerId)
		if(player) then
			self:ProductPurchase(player,reiceptInfo)
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

return module
