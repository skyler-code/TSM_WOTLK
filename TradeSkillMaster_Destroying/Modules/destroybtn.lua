-- load the parent file (TSM) into a local variable and register this file as a module
local addonName, TSM = ...
-- loads the localization table --
local L = LibStub("AceLocale-3.0"):GetLocale(addonName) 

local destroybtn = TSM:NewModule("destroybtn", "AceEvent-3.0", "AceHook-3.0")--TSM:NewModule("GUI", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local mat

local speedTable ={
    ["Slow"]   = "Slow",
    ["Normal"] = "Normal",
    ["Fast"]   = "Fast"
}

function destroybtn:Show()
    if self.frame and self.frame:IsVisible() then return end
    
    local spellTable, numKnown = TSM:GetSpells()

    if numKnown == 0 then 
        return TSM:Print(L["You do not know Milling, Prospecting or Disenchant."])
    end

    TSM:Print(L["The Destroyer has risen!"])

    self.frame = AceGUI:Create("TSMWindow")
    local dButton = AceGUI:Create("TSMFastDestroyButton")
    local dropSpell = AceGUI:Create("TSMDropdown")
    local dropSpeed = AceGUI:Create("TSMDropdown")

    self.frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    self.frame:SetTitle(L["The Destroyer"])
    self.frame:SetLayout("Flow")
    self.frame:SetHeight(175)
    self.frame:SetWidth(200)
    self.frame:SetPoint(TSM.db.global.anchor, TSM.db.global.xPos, TSM.db.global.yPos)
    self.frame:SetCallback("OnClose", function (self) 
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
    dropSpell:SetCallback("OnValueChanged",function(this, event, item) setDestroyMode(item) end)
    local firstKey = next(spellTable)
    dropSpell:SetValue(firstKey)
    setDestroyMode(firstKey)

    self.frame:AddChild(dropSpell) 
    self.frame:AddChild(dropSpeed)
    self.frame:AddChild(dButton)
end

    