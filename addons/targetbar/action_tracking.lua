local action = require("org_github_arosecra.packets.action");


local action_tracking = {};

local starting_message_ids = T{IActionMagicStart,IActionWeaponskillStart,IActionItemStart}
local completed_message_ids = T{IActionMagicFinish,IActionMobAbilityFinish,IActionWeaponskillFinish,IActionItemFinish,IActionJobAbilityFinish}
local spell_message_ids = T{IActionMagicStart}
local item_message_ids = T{IActionItemStart}
local weapon_skill_message_ids = T{IActionWeaponskillStart}
local tracked_debuff_ids = T{2,19,7,28}
local untracked_debuff_categories = T{8,7,6,9}
local damaging_spell_message_ids = T{2,252}
local non_damaging_spell_message_ids = T{75,236,237,268,270,271}

action_tracking.track = function(action, runtime_config)
	local target = AshitaCore:GetMemoryManager():GetTarget();
    --print('----')
    --print('category: ' .. action.category);
    --print('target_count: ' .. action.target_count);
    --print('actor_id: ' .. action.actor_id);
    --print('memory target id: ' .. target:GetTargetIndex(0))
    --print('param: ' .. action.param);
    --if(action.targets[1] ~= nil) then
    --    print('target[1].id: ' .. action.targets[1].id)
    --    print('target[1].action_count: ' .. action.targets[1].action_count)
    --    if(action.targets[1].actions[1] ~= nil) then
    --        print('target action.param: ' .. action.targets[1].actions[1].param)
    --        print('target action.message: ' .. action.targets[1].actions[1].message)
    --    end
    --end
    action_tracking.track_action(action, runtime_config);
    action_tracking.track_enemy_target(action, runtime_config);
    action_tracking.track_debuff(action, runtime_config);
end

action_tracking.track_action = function(action, runtime_config) 
    local actor_id = action.actor_id

    if action.actor_id ~= runtime_config.ServerId then
        return;
    end

    local action_id = action.param;
    if starting_message_ids:contains(action.category) then
        if action.targets[1] ~= nil and action.targets[1].actions[1] ~= nil then
        	action_id = action.targets[1].actions[1].param;
        end
    end

    if action_id == 0 then
        return;
    end

    local action_name = nil;
    if spell_message_ids:contains(action.category) then
        local spell = AshitaCore:GetResourceManager():GetSpellById(action_id);
        if spell ~= nil then
            runtime_config.Action = spell.Name[1];
        else
            runtime_config.Action = 'Unknown Spell ' .. action_id;
        end
        runtime_config.ActionStartTime = os.time();
    elseif item_message_ids:contains(action.category) then
        local item = AshitaCore:GetResourceManager():GetItemById(action_id);
        if item ~= nil then
            runtime_config.Action = item.Name[2];
        else
            runtime_config.Action = 'Unknown Item ' .. action_id;
        end
        runtime_config.ActionStartTime = os.time();
    elseif actor_id < 0x01000000 then --npcs
        local ability = AshitaCore:GetResourceManager():GetString("monster_abilities", action_id, 2);
        if ability ~= nil then
            runtime_config.Action = ability;
        else
            runtime_config.Action = 'Unknown NPC Ability ' .. action_id;
        end
        runtime_config.ActionStartTime = os.time();
    elseif action.category == IActionJobAbilityFinish then
        local ability = AshitaCore:GetResourceManager():GetAbilityById(action_id);
        if ability ~= nil then
            runtime_config.Action = ability.Name[2];
        else
            runtime_config.Action = 'Unknown Ability ' .. action_id;
        end
        runtime_config.ActionStartTime = os.time();
    elseif weapon_skill_message_ids:contains(action.category) then
        local ability = AshitaCore:GetResourceManager():GetAbilityById(action_id);
        if ability ~= nil then
            runtime_config.Action = ability.Name[2];
        else
            runtime_config.Action = 'Unknown Weaponskill ' .. action_id;
        end
        runtime_config.ActionStartTime = os.time();
    end

    if action.targets[1] ~= nil and 
       action.targets[1].message == 0 and
       action.targetsp[1].id == action.actor_id then
        runtime_config.Action = "";
    end
end

-- track the target of the target, if there is one
action_tracking.track_enemy_target = function(action, runtime_config)
    local actor_id = action.actor_id

    if action.actor_id ~= runtime_config.ServerId then
        return;
    end

    -- if there's more than one target or no target, ignore the action
    if action.target_count > 1 and
       action.target_count == 0 then
        return;
    end

    -- we only follow auto attack actions to track the target of the target
    if action.category ~= IActionAttack then
        return;
    end

    runtime_config.TargetName = runtime_config.PartyServerIds[action.targets[1].id];


end

action_tracking.track_debuff = function(action, runtime_config)
    if untracked_debuff_categories:contains(action.category) then
        return;
    end

    --track enemy buffs (rino guard, for instance)
end

return action_tracking;