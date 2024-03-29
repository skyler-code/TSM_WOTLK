-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_Additions                           --
--           http://www.curse.com/addons/wow/tradeskillmaster_additions           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- TradeSkillMaster_Additions Locale - enUS
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_Additions/localization/
local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)
if not L then return end

L["Auction Sales"] = true
L["Enable Auction Sales Feature"] = true
L["Enable Vendor Buying Feature"] = true
L["The auction sales feature will change the 'A buyer has been found for your auction of XXX' text into something more useful which contains a link to the item and, if possible, the amount the auction sold for."] = true
L["The vendor buying feature will replace the default frame that is shown when you shift-right-click on a vendor item for purchasing with a small frame that allows you to buy more than one stacks worth at a time."] = true
L["Vendor Buying"] = true
L["Your auction of %sx%s has sold for |cFFFFFFFF%s|r"] = true
L["Post/Cancel Spam Filter"] = true
L["Filters out the Auction created/cancelled spam."] = true
L["Enable Post/Cancel Spam Filter"] = true