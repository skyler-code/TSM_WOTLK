-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_ItemTracker - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/TradeSkillMaster_ItemTracker.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- register this file with Ace Libraries
local addonName, TSM = ...
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, addonName, "AceEvent-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

TSM.version = GetAddOnMetadata(addonName,"X-Curse-Packaged-Version") or GetAddOnMetadata(addonName, "Version") -- current version of the addon
TSM.versionKey = 2
TSM.simpleModuleName = GetAddOnMetadata(addonName, "X-TSM-Module-Name")

-- default values for the savedDB
local savedDBDefaults = {
	-- any global 
	global = {
	},
	
	-- data that is stored per realm/faction combination
	factionrealm = {
		characters = {},
		guilds = {},
		charactersToSync = {},
	},
	
	-- data that is stored per user profile
	profile = {
		tooltip = "simple",
	},
}

local characterDefaults = { -- anything added to the characters table will have these defaults
	bags = {},
	bank = {},
	auctions = {},
	guild = nil,
	mail = {},
	mailInfo = {},
	lastUpdate = nil,
	lastUpdateMail = nil,
}
local guildDefaults = {
	items = {},
	characters = {},
	lastUpdate = nil,
}

-- Called once the player has loaded into the game
-- Anything that needs to be done in order to initialize the addon should go here
function TSM:OnInitialize()
	-- create shortcuts to all the modules
	for moduleName, module in pairs(TSM.modules) do
		TSM[moduleName] = module
	end
	
	-- load the saved variables table into TSM.db
	TSM.db = LibStub:GetLibrary("AceDB-3.0"):New(addonName.."DB", savedDBDefaults, true)
	TSM.characters = TSM.db.factionrealm.characters
	TSM.guilds = TSM.db.factionrealm.guilds
	
	-- register the module with TSM
	TSMAPI:RegisterReleasedModule(addonName, TSM.version, GetAddOnMetadata(addonName, "Author"), GetAddOnMetadata(addonName, "Notes"), TSM.versionKey)
		
	TSMAPI:RegisterIcon(self.simpleModuleName, "Interface\\Icons\\INV_Misc_Gem_Variety_01", function(...) TSM.Config:Load(...) end, addonName)
	
	local playerName, guildName = UnitName("player"), GetGuildInfo("player")
	if not TSM.characters[playerName] then
		TSM.characters[playerName] = characterDefaults
	end
	TSM.characters[playerName].account = TSM.db.global.accountId
	if guildName and not TSM.guilds[guildName] then
		TSM.guilds[guildName] = guildDefaults
	end
	
	TSM.Data:Initialize()
	--TSM.Comm:DoSync()
	
	if TSM.db.profile.tooltip ~= "hide" then
		TSMAPI:RegisterTooltip(addonName, function(...) return TSM:LoadTooltip(...) end)
	end
	
	local itemIDs = {}
	for _, data in pairs(TSM.characters) do
		data.mail = data.mail or characterDefaults.mail
		data.mailInfo = data.mailInfo or characterDefaults.mailInfo
		for itemID in pairs(data.bags) do
			itemIDs[itemID] = true
		end
		for itemID in pairs(data.bank) do
			itemIDs[itemID] = true
		end
		for itemID in pairs(data.mail) do
			itemIDs[itemID] = true
		end
		for itemID in pairs(data.auctions) do
			itemIDs[itemID] = true
		end
	end
	TSMAPI:GetItemInfoCache(itemIDs, true)
end

function TSM:LoadTooltip(itemID)
	local text = {}
	local grandTotal = 0

	if TSM.db.profile.tooltip == "simple" then
		local player, alts = TSM.Data:GetPlayerTotal(itemID)
		local auctions = TSM.Data:GetAuctionsTotal(itemID)
		grandTotal = grandTotal + player + alts + auctions
		tinsert(text, format("  "..L["ItemTracker: %s on player, %s on alts, %s on AH"], "|cffffffff"..player.."|r", "|cffffffff"..alts.."|r", "|cffffffff"..auctions.."|r"))
	elseif TSM.db.profile.tooltip == "full" then
		for name, data in pairs(TSM.characters) do
			local bags = data.bags[itemID] or 0
			local bank = data.bank[itemID] or 0
			local auctions = data.auctions[itemID] or 0
			local mail = data.mail[itemID] or 0
			local total = bags + bank + auctions + mail
			grandTotal = grandTotal + total
			
			local bagText = "|cffffffff"..bags.."|r"
			local bankText = "|cffffffff"..bank.."|r"
			local auctionText = "|cffffffff"..auctions.."|r"
			local mailText = "|cffffffff"..mail.."|r"
			local totalText = "|cffffffff"..total.."|r"
		
			if total > 0 then
				tinsert(text, format("  "..L["%s: %s (%s in bags, %s in bank, %s on AH, %s in mail)"], name, totalText, bagText, bankText, auctionText, mailText))
			end
		end
	end

	if #text > 0 then
		tinsert(text, 1, format(L["ItemTracker Data (%s item(s) total):"], "|cffffffff"..grandTotal.."|r"))
	end
	
	return text
end

-- Make sure the item isn't soulbound
local scanTooltip
local resultsCache = {}
function TSM:IsSoulbound(bag, slot, itemID)
	local slotID = tostring(bag) .. tostring(slot) .. tostring(itemID)
	if resultsCache[slotID] then return resultsCache[slotID] end
	
	if not scanTooltip then
		scanTooltip = CreateFrame("GameTooltip", "TSMItemTrackerScanTooltip", UIParent, "GameTooltipTemplate")
		scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	end
	scanTooltip:ClearLines()
	
	if bag < 0 or bag > NUM_BAG_SLOTS then
		scanTooltip:SetHyperlink("item:"..itemID)
	else
		scanTooltip:SetBagItem(bag, slot)
	end
	
	for id=1, scanTooltip:NumLines() do
		local text = _G["TSMItemTrackerScanTooltipTextLeft" .. id]
		if text and ((text:GetText() == ITEM_BIND_ON_PICKUP and id < 4) or text:GetText() == ITEM_SOULBOUND or text:GetText() == ITEM_BIND_QUEST) then
			resultsCache[slotID] = true
			return true
		end
	end
	
	resultsCache[slotID] = nil
	return false
end