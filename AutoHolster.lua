local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")

-- Default Settings
local function InitializeSettings()
    if not AutoHolsterDB then
        AutoHolsterDB = {
            combat = true,
            outsideCombat = true
        }
    end
end

-- Create the Settings Menu
local function SetupMenu()
    -- Register the main category
    local category = Settings.RegisterVerticalLayoutCategory("AutoHolster")
    
    -- We need to use a 'Getter' and 'Setter' to ensure the menu stays in sync with your SavedVariables
    
    -- 1. Toggle for Sheath After Combat
    local cb1_setting = Settings.RegisterAddOnSetting(category, "AutoHolster_CombatOnly", "combatOnly", AutoHolsterDB, Settings.VarType.Boolean, "Sheath After Combat", "Automatically sheathes weapons when combat ends.")
    Settings.CreateCheckbox(category, cb1_setting, "Sheath After Combat", "Put weapons away when leaving combat.")

    -- 2. Toggle for Sheath on Target Change
    local cb2_setting = Settings.RegisterAddOnSetting(category, "AutoHolster_OutsideCombat", "outsideCombat", AutoHolsterDB, Settings.VarType.Boolean, "Sheath on Target Change", "Sheathes weapons when clearing an enemy target or selecting a friendly.")
    Settings.CreateCheckbox(category, cb2_setting, "Sheath on Target Change", "Put weapons away when changing to a non-hostile target.")

    Settings.RegisterAddOnCategory(category)
end

local function TrySheath(event)
    if InCombatLockdown() or IsStealthed() then return end
    if not AutoHolsterDB then return end

    local shouldPutAway = false

    -- Logic 1: After Combat
    if event == "PLAYER_REGEN_ENABLED" and AutoHolsterDB.combat then
        shouldPutAway = true
    end

    -- Logic 2: Target Changes
    if AutoHolsterDB.outsideCombat then
        if not UnitExists("target") then
            shouldPutAway = true
        else
            if UnitIsPlayer("target") then
                if not UnitIsEnemy("player", "target") then shouldPutAway = true end
            else
                local guid = UnitGUID("target")
                if guid then
                    local unitType = strsplit("-", guid)
                    if unitType ~= "Creature" or not UnitIsEnemy("player", "target") then
                        shouldPutAway = true
                    end
                end
            end
        end
    end

    if shouldPutAway and GetSheathState() ~= 1 then
        ToggleSheath()
    end
end

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "AutoHolster" then
        InitializeSettings()
        SetupMenu()
    else
        -- Delay slightly to let the game state update
        C_Timer.After(0.15, function() TrySheath(event) end)
    end
end)

