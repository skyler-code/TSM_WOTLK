-- loads the localization table --
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Destroying") 

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local destroybtn = TSM:NewModule("destroybtn", "AceEvent-3.0", "AceHook-3.0")--TSM:NewModule("GUI", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries


--Useful Globals--
local mat

local speedTable ={
    ["Slow"]   = "Slow",
    ["Normal"] = "Normal",
    ["Fast"]   = "Fast"
}


local frame = nil
function destroybtn:Show()
    if frame and frame:IsVisible() then return end
    
    local spellTable = TSM:GetSpells()

    if #spellTable == 0 then 
        return TSM:Print(L["You do not know Milling, Prospecting or Disenchant."])
    end

    --TSM:Print(L["The Destroyer has risen!"])

    frame = AceGUI:Create("TSMWindow")
    local dButton = AceGUI:Create("TSMFastDestroyButton")
    local dropSpell = AceGUI:Create("TSMDropdown")
    local dropSpeed = AceGUI:Create("TSMDropdown")

    frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    frame:SetTitle(L["The Destroyer"])
    frame:SetLayout("Flow")
    frame:SetHeight(175)
    frame:SetWidth(200)
    frame:SetPoint(TSM.db.global.anchor, TSM.db.global.xPos, TSM.db.global.yPos)
    frame:SetCallback("OnClose", function (self) 
        TSM.db.global.anchor,_, _,TSM.db.global.xPos,TSM.db.global.yPos = self:GetPoint() 
        AceGUI:Release(self)
        dButton:SetSpell(nil)
    end)

    dButton:SetText("Destroy")
    dButton:SetHeight(75)
    dButton:SetMode("normal")
    dButton:SetLocationsFunc( function(previous)
        TSM.loot:show() 
        if mat == "Disenchantable" then return end
        return TSM.util:searchAndDestroy(mat,previous)
    end)

    dropSpeed:SetList(speedTable)
    dropSpeed:SetCallback("OnValueChanged",function(this, event, item) 
        TSM.db.global.dMode = item
        dButton:SetMode(item) 
    end)
    dropSpeed:SetValue(TSM.db.global.dMode)

    local function setDestroyMode(item)
        dButton:SetSpell(item) 
        TSM.loot:setAction(item)
        if item == "Disenchant" then
            dButton:SetLocationsFunc( 
            function(previous)
                TSM.loot:show() 
                return TSM.de:searchAndDestroy(previous)
            end)
            return
        end
        
        if item =="Prospecting" then
            mat = "Prospectable"
        elseif item == "Milling" then
            mat = "Millable"
        end
        
        dButton:SetLocationsFunc( function(previous)
            TSM.loot:show() 
            return TSM.util:searchAndDestroy(mat,previous)
        end)
    end

    dropSpell:SetList(spellTable)
    dropSpell:SetCallback("OnValueChanged",function(this, event, item) setDestroyMode(spellTable[item]) end)
    dropSpell:SetValue(1)
    setDestroyMode(spellTable[1])

    frame:AddChild(dropSpell) 
    frame:AddChild(dropSpeed)
    frame:AddChild(dButton)
end

    