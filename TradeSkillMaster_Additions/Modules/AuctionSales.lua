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
	AuctionSales:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")
end

function AuctionSales:OnDisable()
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", AuctionSales.FilterSystemMsg)
	AuctionSales:UnregisterEvent("AUCTION_OWNED_LIST_UPDATE")
end

function AuctionSales:AUCTION_OWNED_LIST_UPDATE()
	wipe(TSM.db.char.auctionPrices)
	wipe(TSM.db.char.auctionMessages)
	
	local auctionPrices = {}
	for i=1, GetNumAuctionItems("owner") do
		local link = GetAuctionItemLink("owner", i)
		local name, _, quantity, _, _, _, _, _, buyout, _, _, _, wasSold = GetAuctionItemInfo("owner", i)
		if wasSold == 0 then
			if buyout and buyout > 0 then
				auctionPrices[link] = auctionPrices[link] or {name=name}
				tinsert(auctionPrices[link], {buyout=buyout, quantity=quantity})
			end
		end
	end
	for link, auctions in pairs(auctionPrices) do
		-- make sure all auctions are the quantity
		local quantity = auctions[1].quantity
		for i=2, #auctions do
			if quantity ~= auctions[i].quantity then
				quantity = nil
				break
			end
		end
		if quantity then
			local prices = {}
			for _, data in ipairs(auctions) do
				tinsert(prices, data.buyout)
			end
			sort(prices)
			TSM.db.char.auctionPrices[link] = prices
			TSM.db.char.auctionMessages[format(ERR_AUCTION_SOLD_S, auctions.name)] = link
		end
	end
end

local EXPIRED = ERR_AUCTION_EXPIRED_S:gsub("%%s", "(.-)")

function AuctionSales.FilterSystemMsg(self, event, msg, ...)
	local lineID = select(10, ...)
	if lineID ~= self.prevLineID then
		self.prevLineID = lineID

		local expiredItem = strmatch(msg, EXPIRED)
		if expiredItem then
			local _, itemLink = GetItemInfo(expiredItem)
			if itemLink then
				return nil, format(ERR_AUCTION_EXPIRED_S, itemLink), ...
			end
			return
		end

		local link = TSM.db.char.auctionMessages and TSM.db.char.auctionMessages[msg]
		if not link then return end

		local price = tremove(TSM.db.char.auctionPrices[link], 1)
		if not price then -- couldn't determine the price, so just replace the link
			return nil, format(ERR_AUCTION_SOLD_S, link), ...
		end

		if #TSM.db.char.auctionPrices[link] == 1 then -- this was the last auction
			TSM.db.char.auctionMessages[msg] = nil
		end
		return nil, format(L["Your auction of %s has sold for |cFFFFFFFF%s|r"], link, GetCoinTextureString(price)), ...
	end
end