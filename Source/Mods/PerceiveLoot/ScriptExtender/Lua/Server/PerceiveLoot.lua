---@diagnostic disable: undefined-global

local NearbyCharacterEventName = 'PL_NearbyCharacter'
local FoundItemEventName = 'PL_FoundItem'
local FoundItemSubStringLen = string.len(FoundItemEventName) + 2
local CompletedEventName = 'PL_Iterate_Complete'
local SearchedStatus = 'BEING_SEARCHED'
local BeamVfx = 'VFX_Script_Perception_Default_01_46bd169e-bbb5-a6fe-0fe7-97c64f620d5d'

local CurrentEffects = {}


local function IsItemValuable(item)
    return Osi.IsJunk(item) == 0 and ((Osi.IsStoryItem(item) == 1
        or Osi.IsTagged(item, "LOOT_GOLD") == 1
        or Osi.IsTagged(item, "HEALING_POTION") == 1
        -- or Osi.GetVarObject(item, "ObjectCategory") == "PotionHealing"
        -- or Osi.GetVarObject(item, "ObjectCategory") == "Gold"
        -- or Osi.GetVarObject(item, "Rarity") == "Rare"
        -- or Osi.GetVarObject(item, "Rarity") == "VeryRare"
        -- or Osi.GetVarObject(item, "Rarity") == "Legendary"
        -- or Osi.GetVarObject(item, "Unique") == "1"
        or Osi.ItemGetGoldValue(item) > 150))
end

local function SearchForItems(uuid, name)
    if name == NearbyCharacterEventName and Osi.IsDead(uuid) == 1 and Osi.IsPartyMember(uuid, 0) == 0 then
        Ext.Utils.Print("Found Dead Body " .. uuid)
        Osi.IterateInventory(uuid, FoundItemEventName .. '_' .. uuid, CompletedEventName)
    elseif name:find('^' .. FoundItemEventName) ~= nil then
        local parent = string.len(name) > FoundItemSubStringLen and string.sub(name, FoundItemSubStringLen) or uuid
        if Osi.IsContainer(uuid) == 1 then
            Ext.Utils.Print("Found Item Container " .. uuid .. " in " .. parent)
            Osi.IterateInventory(uuid, FoundItemEventName .. '_' .. parent, CompletedEventName)
        elseif Osi.IsItem(uuid) == 1 then
            Ext.Utils.Print("Found Item " .. uuid .. " in " .. parent)
            if IsItemValuable(uuid) and CurrentEffects[parent] == nil then
                CurrentEffects[parent] = Osi.PlayLoopBeamEffect(parent, GetHostCharacter(), BeamVfx, '', '')
            end
        end
    end
end

Ext.Osiris.RegisterListener("EntityEvent", 2, "after", SearchForItems)

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function (object, status, _, _)
    if status == SearchedStatus then
        if Osi.IsItem(object) == 1 and Osi.IsMovable(object) == 1 then
            Ext.Utils.Print("Searching item for loot " .. object)
            SearchForItems(object, FoundItemEventName)
        elseif Osi.IsCharacter(object) == 1 then
            Ext.Utils.Print("Searching body for loot " .. object)
            SearchForItems(object, NearbyCharacterEventName)
        else
            Ext.Utils.Print("Can't search loot from " .. object)
        end
    end
end)

Ext.Osiris.RegisterListener("Moved", 1, "after", function (item)
    if CurrentEffects[item] ~= nil then
        Ext.Utils.Print("Removing beam from " .. item)
        Osi.StopLoopEffect(CurrentEffects[item])
        CurrentEffects[item] = nil
    end
end)

Ext.Osiris.RegisterListener("UseStarted", 2, "after", function (character, item)
    if CurrentEffects[item] ~= nil and Osi.IsPartyMember(character, 0) == 1 then
        Ext.Utils.Print(character .. " removing beam from " .. item)
        Osi.StopLoopEffect(CurrentEffects[item])
        CurrentEffects[item] = nil
    end
end)

Ext.Osiris.RegisterListener("RequestCanLoot", 2, "after", function (character, body)
    if CurrentEffects[body] ~= nil and Osi.IsPartyMember(character, 0) == 1 then
        Ext.Utils.Print(character .. " removing beam from " .. body)
        Osi.StopLoopEffect(CurrentEffects[body])
        CurrentEffects[body] = nil
    end
end)

-- Ext.Osiris.RegisterListener("UsingSpell", 5, "after", function (spellCaster, name, a, b, c, d)
--     if name == 'Shout_Perceive_Loot' then
--         Ext.Utils.Print("UsingSpell", spellCaster, name, a, b, c, d)
--         if spellCaster ~= nil then
--             Ext.Utils.Print(spellCaster .. " looking for loot")
--             Osi.IterateCharactersAround(spellCaster, 9, NearbyCharacterEventName, CompletedEventName)
--         end
--     end
-- end)

Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", function(uuid)
    Ext.Utils.Print("CharacterJoinedParty " .. uuid)
    if Osi.IsSummon(uuid) == 0 then
        AddSpell(uuid, "Shout_Perceive_Loot", 1, 1)
    end
end)

Ext.Osiris.RegisterListener("SavegameLoaded", 0, "after", function()
    Ext.Utils.Print("SavegameLoaded")
    for _,uuid in pairs(Osi.DB_PartyMembers:Get(nil)) do
        Ext.Utils.Print("Party Member " .. uuid[1])
        AddSpell(uuid[1], "Shout_Perceive_Loot", 1, 1)
    end
end)

local function addSpell(cmd)
    AddSpell(GetHostCharacter(), "Shout_Perceive_Loot", 1, 1)
end
Ext.RegisterConsoleCommand("addPerceiveSpell", addSpell);