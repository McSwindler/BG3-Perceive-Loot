local NearbyCharacterEventName = 'PL_NearbyCharacter'
local FoundItemEventName = 'PL_FoundItem'
local FoundItemSubStringLen = string.len(FoundItemEventName) + 2
local CompletedEventName = 'PL_Iterate_Complete'
local SearchedStatus = 'BEING_SEARCHED'
local BeamVfx = 'VFX_Script_Perception_Default_01_46bd169e-bbb5-a6fe-0fe7-97c64f620d5d'
local SpellName = 'Shout_Perceive_Loot'
local TagsToHighlight = {
    HEALING_POTION='1879a93d-2edf-4f54-85dd-81a3724d677f',
    LOOT_GOLD='6c6b7cac-113c-42ee-bc46-05567b067a9f'
}

local CurrentEffects = {}
local debug = false

local function Debug(message)
    if debug then
        Ext.Utils.Print("[PerceiveLoot][DEBUG] " .. message)
    end
end

local function IsItemValuable(item)
    if Osi.IsJunk(item) == 1 then
        Debug("Rejecting item " .. item .. " - is junk")
        return false
    elseif Osi.IsStoryItem(item) == 1 then
        Debug("Highling item " .. item .. " - story item")
        return true
    elseif Osi.ItemGetGoldValue(item) >= 150 then
        Debug("Highling item " .. item .. " - >= 150 gold")
        return true
    end

    for name,tag in pairs(TagsToHighlight) do
        if Osi.IsTagged(item, tag) == 1 then
            Debug("Highling item " .. item .. " - tagged " .. name)
            return true
        end
    end

    local ItemEntity = Ext.Entity.Get(item)
    if ItemEntity.Value.Unique then
        Debug("Highling item " .. item .. " - Unique")
        return true
    elseif ItemEntity.Value.Rarity >= 2 then
        Debug("Highling item " .. item .. " - Rare or above")
        return true
    end

    Debug("Rejecting item " .. item .. " - no match")
    return false
end

local function HighlightObject(object)
    if CurrentEffects[object] == nil then
        CurrentEffects[object] = Osi.PlayLoopBeamEffect(object, Osi.GetHostCharacter(), BeamVfx, '', '')
    end
end

local function HandleContainer(uuid, parent)
    if Osi.IsLocked(uuid) == 1 then
        Debug("Highlighting item " .. uuid .. " - locked")
        HighlightObject(parent)
    else
        Debug("Found Item Container " .. uuid .. " in " .. parent)
        Osi.IterateInventory(uuid, FoundItemEventName .. '_' .. parent, CompletedEventName)
    end
end

local function HandleItem(uuid, parent)
    Debug("Found Item " .. uuid .. " in " .. parent)
    if IsItemValuable(uuid) then 
        HighlightObject(parent) 
    end
end

local function SearchForItems(uuid, name)
    if name == NearbyCharacterEventName and Osi.IsDead(uuid) == 1 and Osi.IsPartyMember(uuid, 0) == 0 then
        Debug("Found Dead Body " .. uuid)
        Osi.IterateInventory(uuid, FoundItemEventName .. '_' .. uuid, CompletedEventName)
    elseif name:find('^' .. FoundItemEventName) ~= nil then
        local parent = string.len(name) > FoundItemSubStringLen and string.sub(name, FoundItemSubStringLen) or uuid
        if Osi.IsContainer(uuid) == 1 then
            HandleContainer(uuid, parent)
        elseif Osi.IsItem(uuid) == 1 then
            HandleItem(uuid, parent)
        end
    end
end

Ext.Osiris.RegisterListener("EntityEvent", 2, "after", SearchForItems)

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function (object, status, _, _)
    if status == SearchedStatus then
        if Osi.IsItem(object) == 1 and Osi.IsMovable(object) == 1 then
            SearchForItems(object, FoundItemEventName)
        elseif Osi.IsCharacter(object) == 1 then
            SearchForItems(object, NearbyCharacterEventName)
        end
    end
end)

Ext.Osiris.RegisterListener("Moved", 1, "after", function (item)
    if CurrentEffects[item] ~= nil then
        Debug("Removing beam from " .. item)
        Osi.StopLoopEffect(CurrentEffects[item])
        CurrentEffects[item] = nil
    end
end)

Ext.Osiris.RegisterListener("UseStarted", 2, "after", function (character, item)
    if CurrentEffects[item] ~= nil and Osi.IsPartyMember(character, 0) == 1 then
        Debug(character .. " removing beam from " .. item)
        Osi.StopLoopEffect(CurrentEffects[item])
        CurrentEffects[item] = nil
    end
end)

Ext.Osiris.RegisterListener("RequestCanLoot", 2, "after", function (character, body)
    if CurrentEffects[body] ~= nil and Osi.IsPartyMember(character, 0) == 1 then
        Debug(character .. " removing beam from " .. body)
        Osi.StopLoopEffect(CurrentEffects[body])
        CurrentEffects[body] = nil
    end
end)

local function AddSpellToPC(uuid)
    if Osi.IsSummon(uuid) == 0 and Osi.IsPartyFollower(uuid) == 0 and Osi.IsPartyMember(uuid, 0) == 1 then
        Debug("Adding spell to " .. uuid)
        Osi.AddSpell(uuid, SpellName, 1, 1)
    end
end

Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", function(uuid)
    AddSpellToPC(uuid)
end)

Ext.Osiris.RegisterListener("SavegameLoaded", 0, "after", function()
    Ext.Utils.Print("[PerceiveLoot][INFO] Applying " .. SpellName .. " to current Player Characters.")
    for _,uuid in pairs(Osi.DB_PartyMembers:Get(nil)) do
        AddSpellToPC(uuid[1])
    end
end)


local function ToggleDebug(_)
    debug = not debug
end
Ext.RegisterConsoleCommand("PL_ToggleDebug", ToggleDebug);