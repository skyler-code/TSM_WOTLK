-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_Additions                           --
--           http://www.curse.com/addons/wow/tradeskillmaster_additions           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- register this file with Ace Libraries
local addonName, TSM = ...
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, addonName, "AceEvent-3.0", "AceConsole-3.0")
TSM.simpleModuleName = GetAddOnMetadata(addonName, "X-TSM-Module-Name")
TSM.version = GetAddOnMetadata(addonName, "X-Curse-Packaged-Version") or GetAddOnMetadata(addonName, "Version") -- current version of the addon

local savedDBDefaults = {
	global = {
		enableAuctionSales = true,
		enableVendorBuying = true,
		enablePostingSpam = true,
	},
	char = {
		auctions = {},
	},
}

-- Called once the player has loaded WOW.
function TSM:OnInitialize()
	-- load the savedDB into TSM.db
	self.db = LibStub:GetLibrary("AceDB-3.0"):New(addonName.."DB", savedDBDefaults, true)
	
	for module in pairs(self.modules) do
		self[module] = self.modules[module]
	end

	-- register with TSM
	self:RegisterModule()
	self:UpdateFeatureStates()
end

-- registers this module with TSM by first setting all fields and then calling TSMAPI:NewModule().
function TSM:RegisterModule()
	TSMAPI:RegisterReleasedModule(addonName, self.version, GetAddOnMetadata(addonName, "Author"), GetAddOnMetadata(addonName, "Notes"), self.versionKey)
	TSMAPI:RegisterIcon(self.simpleModuleName, "Interface\\Icons\\Inv_Misc_Coin_08", function(...) self.Options:Load(...) end, addonName)
end

-- enable / disable features according to the options
function TSM:UpdateFeatureStates()
	for module in pairs(TSM.modules) do
		if TSM.db.global['enable'..module] then
			TSM[module]:Enable()
		else
			TSM[module]:Disable()
		end
	end
end