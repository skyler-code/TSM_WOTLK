-- ---------------------------------------------------------------------------------------
-- 					TradeSkillMaster_Destroying - AddOn by Geemoney			   --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_destroying.aspx --
--																	   --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/	   --
-- 	Please contact the license holder (Sapu) via email at	sapu94@gmail.com with any   --
--		questions or concerns regarding this license.				 		   --
-- ---------------------------------------------------------------------------------------
--TSMAPI:RegisterSlashCommand("destroying", GUI:Load, "/TSM Destroying", notLoadFunc)

-- load the parent file (TSM) into a local variable and register this file as a module
local addonName, TSM = ...
-- loads the localization table --
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local GUI = TSM:NewModule("GUI", "AceEvent-3.0", "AceHook-3.0")--TSM:NewModule("GUI", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local Obj = {
    frame = nil,
    action = nil,
    filter = nil
}

local Spacer = 
{
    type = "Label",
    text = "\n",
    fontObject = GameFontNormalMedium,
    fullWidth = true,
    relativeHeight = 1,

}

local rTable = nil
local function drawConfigUI (container)
    local spellTable = TSM:GetSpells() 
    local page = 
    {
		{
			type = "SimpleGroup",
			layout = "Flow",
			children = 
			{
                {	--button
                    type = "Button",
					text = L["Display the Destroyer"],
					relativeWidth = 1,
					callback = function() TSM.destroybtn:Show() end			

                }, 	--button
                 Spacer, 
                {	--button
                    type = "Button",
					text = L["Create Macro to Display the Destroyer"],
					relativeWidth = 1,
					callback = function() CreateMacro("TSMDestroyer", 1, "/tsm destroy", nil, nil) end
                }, 	--button
                {	--button
                    type = "Button",
					text = L["Create Macro to Use the Destroyer"],
					relativeWidth = 1,
					callback = function() CreateMacro("TSMUseDestroyer", 1, "/click TSMDestroyingButton1", nil, nil) end
                }, 	--button
                Spacer, 
                {	--Prospecting DD
                    type = "Dropdown",
                    relativeWidth = 0.5,
                    list =  spellTable,
                    value = current,
                    callback =	function(this, event, item) rTable = item end
                }, 	-- End Prospecting DD
                {	--button
                    type = "Button",
                    text = L["Clear Results Table"],
                    relativeWidth = .5,
                    callback = function()
                        if not rTable then return end
                        if rTable == "Prospecting" then
                            TSM.db.factionrealm.Prospecting = {Day = {},Mat = {}}
                        elseif rTable == "Milling" then
                            TSM.db.factionrealm.Milling = {Day = {},Mat = {}}
                        elseif rTable == "Disenchant" then
                            TSM.db.factionrealm.DE = {Day = {},Mat = {}}
                        end
                        TSM:Print(spellTable[rTable]..L[" Table has been cleared"])
                    end			
                }, 	--button
            }--end childern
        }--end
    }--end page
    TSMAPI:BuildPage(container, page)

end
local Warning = L["Warning: Destroying will do its best to destroy everything in your bags."].."|cffff8888"
local function drawUI (container)
    Obj.filter = TSM.db.global.filter
    local page = 
    {
		{
			type = "SimpleGroup",
			layout = "Flow",
			children = 
			{
                 {
                    type = "Label",
                    text = Warning,
                    fontObject = GameFontNormalMedium,
                    fullWidth = true,
                    relativeHeight = 1,
                    colorRed = 255,
					colorGreen = 0,
					colorBlue = 0,
                },
                {	--button
                    type = "Button",
                    text = L["Display the Destroyer"],
                    relativeWidth = 1,
                    callback = function() TSM.destroybtn:Show() end

                }, 	--button
                {	--filter DD
                    type = "Dropdown",
                    relativeWidth = 0.5,
                    label = L["Set Filter"],
                    list =  {["mats"] = "Mats", ["date"] = "Date"},
                    value = Obj.filter,
                    callback =	function(this, event, filter) 
                        Obj.filter = filter
                        TSM.db.global.filter = filter
                        TSM.stDestroying:updateTable(Obj.frame, Obj.action, Obj.filter)
                    end			
                }, 	-- End filter DD

            }--end childern
        }--end
    }--end page
    TSMAPI:BuildPage(container, page)

end

local deWarning = L["Warning: If you are about to disenchant BOP/soulbound items the Slow speed is recomended."].."|cffff8888"

local function drawDE_UI (container)
    Obj.filter = TSM.db.global.filter
    local page = 
    {
		{
			type = "SimpleGroup",
			layout = "Flow",
			children = 
			{
                {
                    type = "Label",
                    text = deWarning,
                    fontObject = GameFontNormalMedium,
                    fullWidth = true,
                    relativeHeight = 1,
                    colorRed = 255,
					colorGreen = 0,
					colorBlue = 0,
                },
                Spacer,
                {	--button
                    type = "Button",
                    text = L["Display the Destroyer"],
                    relativeWidth = 1,
                    callback = function() TSM.destroybtn:Show() end			

                }, 	--button
               

            }--end childern
        }--end
    }--end page
    TSMAPI:BuildPage(container, page)

end

function GUI:Load(parent)
    local tabGroupTable={}
	local spellTable = TSM:GetSpells()
    for k,v in pairs(spellTable) do
        tinsert(tabGroupTable, {text=v,value=k})
    end
    tinsert(tabGroupTable, {text=L["Config"], value="Config"})

	local simpleGroup = AceGUI:Create("TSMSimpleGroup")
	simpleGroup:SetLayout("Fill")
	parent:AddChild(simpleGroup)
	
	--containers--
	local tabGroup = AceGUI:Create("TSMTabGroup")
	tabGroup:SetLayout("Fill")

	tabGroup:SetTabs(tabGroupTable)
	
	tabGroup:SetCallback("OnGroupSelected", function(self, _, value)
            tabGroup:ReleaseChildren()		
			TSM.stDestroying:hideTable()
            TSM.stDE:hideTable()

            if value == "Config" then
                drawConfigUI (self)
                Obj.frame  = nil
                Obj.action = nil
                return
            else
                Obj.action = strlower(value)
                Obj.filter = "mats"
            end
            
            Obj.frame = self
            if value ~= "Disenchant" then
                drawUI (self)
                TSM.stDestroying:DrawScrollFrame (self, Obj.action, Obj.filter)
            else
                drawDE_UI(self)
                TSM.stDE:InitScrollFrames (self, Obj.action, Obj.filter)
            end
		end)
	
	simpleGroup:AddChild(tabGroup)
    local _, firstTab = next(tabGroupTable)
	tabGroup:SelectTab(firstTab.value)
	
	GUI:HookScript(simpleGroup.frame, "OnHide", function() 
        GUI:UnhookAll() 
        TSM.stDestroying:hideTable() 
        TSM.stDE:hideTable() 
	end)
    
end

function GUI:getInfo() return Obj end

