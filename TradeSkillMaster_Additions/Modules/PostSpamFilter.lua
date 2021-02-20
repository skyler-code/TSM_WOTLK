-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_Additions                           --
--           http://www.curse.com/addons/wow/tradeskillmaster_additions           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- load the parent file (TSM) into a local variable and register this file as a module
local addonName, TSM = ...
local PostSpamFilter = TSM:NewModule("PostSpamFilter", "AceEvent-3.0")

function PostSpamFilter:OnEnable()
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", PostSpamFilter.FilterSystemMsg)
end

function PostSpamFilter:OnDisable()
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", PostSpamFilter.FilterSystemMsg)
end

function PostSpamFilter.FilterSystemMsg(self, event, msg, ...)
	return ({[ERR_AUCTION_REMOVED]=true,[ERR_AUCTION_STARTED]=true})[msg]
end