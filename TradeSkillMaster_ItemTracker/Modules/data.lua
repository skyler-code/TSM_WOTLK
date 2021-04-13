-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_ItemTracker - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/TradeSkillMaster_ItemTracker.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Data = TSM:NewModule("Data", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_ItemTracker")

local CURRENT_PLAYER, CURRENT_GUILD = UnitName("player"), GetGuildInfo("player")
local BUCKET_TIME = 0.2 -- wait at least this amount of time between throttled events firing
local throttleFrames = {}
local isScanning = false

function Data:Initialize()
	Data:RegisterEvent("BAG_UPDATE", "EventHandler")
	Data:RegisterEvent("BANKFRAME_OPENED", "EventHandler")
	Data:RegisterEvent("PLAYERBANKSLOTS_CHANGED", "EventHandler")
	Data:RegisterEvent("AUCTION_OWNED_LIST_UPDATE", "EventHandler")
	
	TSMAPI:RegisterData("playerlist", Data.GetPlayers)
	TSMAPI:RegisterData("guildlist", Data.GetGuilds)
	TSMAPI:RegisterData("playerbags", Data.GetPlayerBags)
	TSMAPI:RegisterData("playerbank", Data.GetPlayerBank)
	TSMAPI:RegisterData("playermail", Data.GetPlayerMail)
	TSMAPI:RegisterData("playerauctions", Data.GetPlayerAuctions)
	TSMAPI:RegisterData("totalplayerauctions", Data.GetAuctionsTotal)
	TSMAPI:RegisterData("playertotal", Data.GetPlayerTotal)
	
	CURRENT_PLAYER, CURRENT_GUILD = UnitName("player"), GetGuildInfo("player")
	Data:StoreCurrentGuildInfo()
end

local guildThrottle = CreateFrame("frame")
guildThrottle:Hide()
guildThrottle.attemptsLeft = 20
guildThrottle:SetScript("OnUpdate", function(self, elapsed)
		self.timeLeft = self.timeLeft - elapsed
		if self.timeLeft <= 0 then
			self.attemptsLeft = self.attemptsLeft - 1
			Data:StoreCurrentGuildInfo(self.attemptsLeft == 0)
		end
	end)

function Data:StoreCurrentGuildInfo(noDelay)
	CURRENT_GUILD = GetGuildInfo("player")
	if CURRENT_GUILD then
		TSM.guilds[CURRENT_GUILD] = TSM.guilds[CURRENT_GUILD] or {items={}, characters={[CURRENT_PLAYER]=true}}
		TSM.guilds[CURRENT_GUILD].characters = TSM.guilds[CURRENT_GUILD].characters or {}
		TSM.guilds[CURRENT_GUILD].items = TSM.guilds[CURRENT_GUILD].items or {}
		if not TSM.guilds[CURRENT_GUILD].characters[CURRENT_PLAYER] then
			TSM.guilds[CURRENT_GUILD].characters[CURRENT_PLAYER] = true
		end
		for guildName, data in pairs(TSM.guilds) do
			data.characters = data.characters or {}
			if guildName ~= CURRENT_GUILD and data.characters[CURRENT_PLAYER] then
				data.characters[CURRENT_PLAYER] = nil
			end
		end
		guildThrottle:Hide()
	elseif not noDelay then
		guildThrottle.timeLeft = 0.5
		guildThrottle:Show()
	else
		guildThrottle:Hide()
	end
	TSM.characters[CURRENT_PLAYER].guild = CURRENT_GUILD
	TSM.characters[CURRENT_PLAYER].lastUpdate = time()
end

function Data:ThrottleEvent(event)
	if not throttleFrames[event] then
		local frame = CreateFrame("Frame")
		frame.baseTime = BUCKET_TIME
		frame.event = event
		frame:Hide()
		frame:SetScript("OnShow", function(self) Data:UnregisterEvent(self.event) self.timeLeft = self.baseTime end)
		frame:SetScript("OnUpdate", function(self, elapsed)
				self.timeLeft = self.timeLeft - elapsed
				if self.timeLeft <= 0 then
					Data:EventHandler(self.event, "FIRE")
					self:Hide()
					Data:RegisterEvent(self.event, "EventHandler")
				end
			end)
		throttleFrames[event] = frame
	end
	
	-- resets the delay time on the frame
	throttleFrames[event]:Hide()
	throttleFrames[event]:Show()
end

function Data:EventHandler(event, fire)
	if isScanning then return end
	if fire ~= "FIRE" then
		Data:ThrottleEvent(event)
	else
		if event == "BAG_UPDATE" then
			Data:GetBagData()
		elseif event == "PLAYERBANKSLOTS_CHANGED" or event == "BANKFRAME_OPENED" then
			Data:GetBankData()
		elseif event == "AUCTION_OWNED_LIST_UPDATE" then
			Data:ScanPlayerAuctions()
		end
	end
end

-- scan the player's bags
function Data:GetBagData()
	wipe(TSM.characters[CURRENT_PLAYER].bags)
	for bag=0, NUM_BAG_SLOTS do
		for slot=1, GetContainerNumSlots(bag) do
			local itemID = TSMAPI:GetItemID(GetContainerItemLink(bag, slot))
			if itemID and not TSM:IsSoulbound(bag, slot, itemID) then
				local quantity = select(2, GetContainerItemInfo(bag, slot))
				TSM.characters[CURRENT_PLAYER].bags[itemID] = (TSM.characters[CURRENT_PLAYER].bags[itemID] or 0) + quantity
			end
		end
	end
	TSM.characters[CURRENT_PLAYER].lastUpdate = time()
end

-- scan the player's bank
function Data:GetBankData()
	local locationList = {}
	wipe(TSM.characters[CURRENT_PLAYER].bank)
	
	local function ScanBankBag(bag)
		for slot=1, GetContainerNumSlots(bag) do
			local itemID = TSMAPI:GetItemID(GetContainerItemLink(bag, slot))
			if itemID and not TSM:IsSoulbound(bag, slot, itemID) then
				locationList[itemID] = locationList[itemID] or {}
				local quantity = select(2, GetContainerItemInfo(bag, slot))
				TSM.characters[CURRENT_PLAYER].bank[itemID] = (TSM.characters[CURRENT_PLAYER].bank[itemID] or 0) + quantity
				tinsert(locationList[itemID], {bag=bag, slot=slot, quantity=quantity})
			end
		end
	end
	
	for bag=NUM_BAG_SLOTS+1, NUM_BAG_SLOTS+NUM_BANKBAGSLOTS do
		ScanBankBag(bag)
	end
	ScanBankBag(-1)
	TSM.characters[CURRENT_PLAYER].lastUpdate = time()
end

local gFrame = CreateFrame("Frame")
gFrame:Hide()
gFrame.timeLeft = 0.5
gFrame:SetScript("OnUpdate", function(self, elapsed)
	self.timeLeft = self.timeLeft - elapsed
	if self.timeLeft <= 0 then
		self.timeLeft = 0.5
		self:Hide()
		Data:SendMessage("TSMGUILDBANK", CopyTable(self.locationList))
	end
end)

function Data:ScanPlayerAuctions()
	wipe(TSM.characters[CURRENT_PLAYER].auctions)
	TSM.characters[CURRENT_PLAYER].auctions.time = time()
	
	for i=1, GetNumAuctionItems("owner") do
		local itemID = TSMAPI:GetItemID(GetAuctionItemLink("owner", i))
		local _, _, quantity, _, _, _, _, _, _, _, _, _, wasSold = GetAuctionItemInfo("owner", i)
		if wasSold == 0 and itemID then
			TSM.characters[CURRENT_PLAYER].auctions[itemID] = (TSM.characters[CURRENT_PLAYER].auctions[itemID] or 0) + quantity
		end
	end
	TSM.characters[CURRENT_PLAYER].lastUpdate = time()
end




-- functions for getting data through TSMAPI:GetData()

function Data:GetPlayers()
	local temp = {}
	for name in pairs(TSM.characters) do
		tinsert(temp, name)
	end
	return temp
end

function Data:GetGuilds()
	local temp = {}
	for name in pairs(TSM.guilds) do
		tinsert(temp, name)
	end
	return temp
end

function Data:GetPlayerBags(player)
	player = player or CURRENT_PLAYER
	if not player or not TSM.characters[player] then return end
	
	return TSM.characters[player].bags
end

function Data:GetPlayerBank(player)
	player = player or CURRENT_PLAYER
	if not player or not TSM.characters[player] then return end
	
	return TSM.characters[player].bank
end

function Data:GetPlayerMail(player)
	player = player or CURRENT_PLAYER
	if not player or not TSM.characters[player] then return end
	
	return TSM.characters[player].mail
end

function Data:GetGuildBank(guild)
	guild = guild or CURRENT_GUILD
	if not guild or not TSM.guilds[guild] then return end
	
	return TSM.guilds[guild].items
end

function Data:GetPlayerAuctions(player)
	player = player or CURRENT_PLAYER
	if not TSM.characters[player] then return end
	
	TSM.characters[player].auctions = TSM.characters[player].auctions or {}
	local lastScanTime = TSM.characters[player].auctions.time or 0
	
	if (time() - lastScanTime) < (48*60*60) then
		return TSM.characters[player].auctions
	end
end

function Data:GetPlayerTotal(itemID)
	local playerTotal, altTotal = 0, 0
	
	for name, data in pairs(TSM.characters) do
		if name == CURRENT_PLAYER then
			playerTotal = playerTotal + (data.bags[itemID] or 0)
			playerTotal = playerTotal + (data.bank[itemID] or 0)
			playerTotal = playerTotal + (data.mail[itemID] or 0)
		else
			altTotal = altTotal + (data.bags[itemID] or 0)
			altTotal = altTotal + (data.bank[itemID] or 0)
			altTotal = altTotal + (data.mail[itemID] or 0)
		end
	end
	
	return playerTotal, altTotal
end


function Data:GetAuctionsTotal(itemID)
	local auctionsTotal = 0
	for _, data in pairs(TSM.characters) do
		auctionsTotal = auctionsTotal + (data.auctions[itemID] or 0)
	end
	
	return auctionsTotal
end


-- ***************************************************************************
-- MAIL TRACKING FUNCTIONS
-- ***************************************************************************
function Data:UpdateMailQuantities(player)
	local data = TSM.characters[player]
	wipe(data.mail)
	for link, count in pairs(data.mailInfo) do
		local itemID = TSMAPI:GetItemID(link)
		data.mail[itemID] = (data.mail[itemID] or 0) + count
	end
	TSM.characters[player].lastMailUpdate = time()
end

do
	local tmpBuyouts = {}
	local function hookFunc(listType, index, bidPlaced)
		local link = GetAuctionItemLink(listType, index)
		local name, _, count, _, _, _, _, _, _, buyout = GetAuctionItemInfo(listType, index)
		if bidPlaced == buyout then
			tinsert(tmpBuyouts, {name=name, link=link, count=count})
		end
	end
	local function hookFunc2(index)
		local link = GetAuctionItemLink("owner", index)
		local count = select(3, GetAuctionItemInfo("owner", index))
		local mailInfo = TSM.characters[CURRENT_PLAYER].mailInfo
		mailInfo[link] = (mailInfo[link] or 0) + count
		Data:UpdateMailQuantities(CURRENT_PLAYER)
	end
	local function hookFunc3(index, itemIndex)
		local player = TSM.characters[CURRENT_PLAYER]
		for itemIndex=(itemIndex or 1), (itemIndex or ATTACHMENTS_MAX_RECEIVE) do
			local link = GetInboxItemLink(index, itemIndex)
			if link then
				if player.mailInfo[link] then
					player.mailInfo[link] = player.mailInfo[link] - select(3, GetInboxItem(index, itemIndex))
					if player.mailInfo[link] <= 0 then
						player.mailInfo[link] = nil
					end
				end
			end
		end
	end
	local function hookFunc4(target)
		local altName
		for name in pairs(TSM.characters) do
			if strlower(name) == strlower(target) then
				altName = name
				break
			end
		end
		if not altName then return end
		for i=1, 16 do
			local link = GetSendMailItemLink(i)
			if link then
				local count = select(3, GetSendMailItem(i))
				TSM.characters[altName].mailInfo[link] = (TSM.characters[altName].mailInfo[link] or 0) + count
			end
		end
		Data:UpdateMailQuantities(altName)
	end
	local function hookFunc5(index)
		local sender = select(3, GetInboxHeaderInfo(index))
		local target = TSM.characters[sender]
		local player = TSM.characters[CURRENT_PLAYER]
		if not target then return end
		for itemIndex=1, ATTACHMENTS_MAX_RECEIVE do
			local link = GetInboxItemLink(index, itemIndex)
			if link then
				target.mailInfo[link] = (target.mailInfo[link] or 0) + select(3, GetInboxItem(index, itemIndex))
				if player.mailInfo[link] then
					player.mailInfo[link] = player.mailInfo[link] - select(3, GetInboxItem(index, itemIndex))
					if player.mailInfo[link] <= 0 then
						player.mailInfo[link] = nil
					end
				end
			end
		end
		Data:UpdateMailQuantities(sender)
		Data:UpdateMailQuantities(CURRENT_PLAYER)
	end
	
	local function onChatMsg(_, msg)
		if msg:match(gsub(ERR_AUCTION_WON_S, "%%s", "")) then
			while #tmpBuyouts > 0 do
				local info = CopyTable(tmpBuyouts[1])
				tremove(tmpBuyouts, 1)
				if msg == format(ERR_AUCTION_WON_S, info.name) then
					local mailInfo = TSM.characters[CURRENT_PLAYER].mailInfo
					mailInfo[info.link] = (mailInfo[info.link] or 0) + info.count
					Data:UpdateMailQuantities(CURRENT_PLAYER)
					break
				end
			end
		end
	end
	
	local function onMailUpdate()
		local player = TSM.characters[CURRENT_PLAYER]
		local numItems, totalItems = GetInboxNumItems()
		if numItems == totalItems then
			wipe(player.mailInfo)
		end
		local newInfo = {}
		for i=1, numItems do
			if select(8, GetInboxHeaderInfo(i)) then
				for j=1, ATTACHMENTS_MAX_RECEIVE do
					local link = GetInboxItemLink(i, j)
					if link then
						if not player.mailInfo[link] then
							newInfo[link] = (newInfo[link] or 0) + select(3, GetInboxItem(i, j))
						end
					end
				end
			end
		end
		for link, count in pairs(newInfo) do
			player.mailInfo[link] = count
		end
		Data:UpdateMailQuantities(CURRENT_PLAYER)
	end

	Data:RegisterEvent("CHAT_MSG_SYSTEM", onChatMsg)
	Data:RegisterEvent("MAIL_INBOX_UPDATE", onMailUpdate)
	Data:Hook("PlaceAuctionBid", hookFunc, true)
	Data:Hook("CancelAuction", hookFunc2, true)
	Data:Hook("TakeInboxItem", hookFunc3, true)
	Data:Hook("AutoLootMailItem", hookFunc3, true)
	Data:Hook("SendMail", hookFunc4, true)
	Data:Hook("ReturnInboxItem", hookFunc5, true)
end