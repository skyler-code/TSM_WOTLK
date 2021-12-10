-- loads the localization table --
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Destroying") 

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local de = TSM:NewModule("de", "AceEvent-3.0", "AceHook-3.0")--TSM:NewModule("GUI", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local GetItemQualityColor, GetContainerNumSlots, GetItemInfo, IsEquippableItem, GetContainerItemID, GetContainerItemLink =
    GetItemQualityColor, GetContainerNumSlots, GetItemInfo, IsEquippableItem, GetContainerItemID, GetContainerItemLink
local tinsert, strmatch, pairs, select = table.insert, strmatch, pairs, select

local lib = TSMAPI

de.dObj = {
    bag = 0,
    slot = 1,
    Item = nil,
}

local function canDE(itemString)
    if not itemString then return end
    local _,_,q = GetItemInfo(itemString)
    if IsEquippableItem(itemString) and ( q>= 2 and q <= 4 ) and not TSM.db.factionrealm.SafeTable[itemString] then
        return true
    end
end

local bagsNum = 4
function de:searchAndDestroy(pre) 
    for bag = de.dObj.bag, bagsNum do --bags		
        for slot = de.dObj.slot, GetContainerNumSlots(bag) do
            local itemString = strmatch(GetContainerItemLink(bag, slot) or "", "item[%-?%d:]+")
            if  pre == nil or (bag ~= pre.bag or slot ~= pre.slot) then 
                if canDE(itemString) then 
                    de.dObj.bag  = bag
                    de.dObj.slot = slot
                    return {bag = bag, slot = slot}
                end
            end
        end--end slots
    end--end bags
    
    de.dObj.bag  = 0
    de.dObj.slot = 1
end

local function getFormattedItemStr(id)
    local name,_,quality = GetItemInfo(id)
    if not name then
        local itemId = tonumber(id) and id or strmatch(id, "item:(%d+):")
        lib:SetCacheTooltip(itemId)
        return id
    end
    local color = ITEM_QUALITY_COLORS[quality]
    return color.hex..name.."|r"
end

function de:getDestroyTable ()
    local gearTable = {}
    local itemIds = {}
    for bag = 0, bagsNum do --bags		
        for slot = 1, GetContainerNumSlots(bag) do
            local itemString = strmatch(GetContainerItemLink(bag, slot) or "", "item[%-?%d:]+")
            if not itemIds[itemString] and canDE(itemString) then
                tinsert(gearTable, 
                    {
                        cols = {
                            {
                                value = function(itemString)
                                    if itemString then
                                        return getFormattedItemStr(itemString)
                                    end
                                end,
                                args = {itemString},
                            },
                        },
                        itemString = itemString
                    }
                )
                itemIds[itemString] = true
            end
        end
    end
    return gearTable
end

function de:getSafeTable()
    local safeTable = {}
    for itemString,_ in pairs(TSM.db.factionrealm.SafeTable) do
        tinsert(safeTable, 
            {
                cols = {
                    {
                        value = function(itemString) 
                            if itemString then
                                return getFormattedItemStr(itemString) 
                            end 
                        end,
                        args = {itemString},
                    },
                },
                itemString = itemString
            }
        )
    end
    return safeTable
end