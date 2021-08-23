-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_Additions                           --
--           http://www.curse.com/addons/wow/tradeskillmaster_additions           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- load the parent file (TSM) into a local variable and register this file as a module
local addonName, TSM = ...
local AuctionSales = TSM:NewModule("AuctionSales", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName) -- loads the localization table

function AuctionSales:OnEnable()
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", AuctionSales.FilterSystemMsg)
	self:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")
end

function AuctionSales:OnDisable()
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", AuctionSales.FilterSystemMsg)
	self:UnregisterEvent("AUCTION_OWNED_LIST_UPDATE")
end

function AuctionSales:AUCTION_OWNED_LIST_UPDATE()
	for i = 1, GetNumAuctionItems("owner") do
		local name, _, quantity, _, _, _, _, _, buyout, _, _, _, wasSold = GetAuctionItemInfo("owner", i)
		if wasSold == 0 and (buyout and buyout > 0) then
			local itemLink = GetAuctionItemLink("owner", i)
			TSM.db.char.auctions[name] = {buyout=buyout, quantity=quantity, itemLink=itemLink}
		end
	end
end

local SOLD = ERR_AUCTION_SOLD_S:gsub("%%s", "(.+)")
local EXPIRED = ERR_AUCTION_EXPIRED_S:gsub("%%s", "(.+)")

function AuctionSales.FilterSystemMsg(chatFrame, event, msg, ...)
	local expiredItem = strmatch(msg, EXPIRED)
	local soldItem = strmatch(msg, SOLD)

	local auctionItemInfo = TSM.db.char.auctions[expiredItem or soldItem]
	if not auctionItemInfo then return end

	if expiredItem then
		return nil, format(ERR_AUCTION_EXPIRED_S, auctionItemInfo.itemLink), ...
	end

	if soldItem then
		return nil, format(L["Your auction of %sx%s has sold for |cFFFFFFFF%s|r"], auctionItemInfo.itemLink, auctionItemInfo.quantity, GetCoinTextureString(auctionItemInfo.buyout)), ...
	end
end