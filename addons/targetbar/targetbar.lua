
addon.name      = 'targetbar';
addon.author    = 'arosecra';
addon.version   = '1.0';
addon.desc      = '';
addon.link      = '';

local imgui = require('imgui');
local common = require('common');

local libs2imgui = require('org_github_arosecra/imgui');
local libs2config = require('org_github_arosecra/config');
local mechanics = require('org_github_arosecra/mechanics');
local action = require('org_github_arosecra/packets/action');
local action_tracking = require('action_tracking');


local targetbar_window = {
    is_open = { true }
};

-- runtime_config = {
--    Name
--    Percent
--    ServerId
--    Index
--    Action  = {
--       Name
--       Start Time
--       Ended
--    }
--    PartyServerIds = {
--
--    }
--    TargetName
--}

local runtime_config = {
};

local once = false;

ashita.events.register('load', 'targetbar_load_cb', function ()
    print("[targetbar] 'load' event was called.");
	local playerEntity = GetPlayerEntity();
	print(playerEntity.ServerId);
	print(AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0));
	--AshitaCore:GetConfigurationManager():Load(addon.name, 'targetbar\\targetbar.ini');
	--runtime_config.tab = AshitaCore:GetConfigurationManager():GetString(addon.name, "settings", "defaulttab");
	--runtime_config.tab_type = AshitaCore:GetConfigurationManager():GetString(addon.name, "settings", "tabs.type." .. runtime_config.tab);
end);

ashita.events.register('command', 'targetbar_command_cb', function (e)
    if (not e.command:startswith('/targetbar') and not e.command:startswith('/tb')) then
		return;
    end
    print("[targetbar] Blocking '/tb' command!");
    e.blocked = true;
end);

ashita.events.register('plugin_event', 'targetbar_plugin_event_cb', function (e)
    if (not e.name:startswith('/targetbar') and not e.name:startswith('/tb')) then
		return;
    end
    print("[targetbar] Blocking '/tb' command!");
    e.blocked = true;
	
end);

local i = 0;

ashita.events.register('packet_in', 'targetbar_packet_in_callback1', function (e)
    if (e.id == IPacketIncomingAction) then
		local action = action.parse(e.data);
		action_tracking.track(action, runtime_config);

		if once then
			coroutine.sleepf(1);
			local file = io.open("D:\\action_" .. i .. ".txt", "w")
			file:write(e.data);
			file:close();
			i = i + 1;
			once = true;
		end
    end
end);

--determine the targeted entity name, index, server id and hp percent
ashita.events.register('d3d_beginscene', 'targetbar_beginscene_callback1', function (isRenderingBackBuffer)
	local playerEntity = GetPlayerEntity();
	if playerEntity == nil then
		runtime_config = {};
		return;
	end
	local party = AshitaCore:GetMemoryManager():GetParty();
	local target = AshitaCore:GetMemoryManager():GetTarget();
	local targetEntity = GetEntity(target:GetTargetIndex(0));
	
	if targetEntity == nil then
		runtime_config = {};
		return;
	end
	
	runtime_config.Target = targetEntity.Name;
	runtime_config.Percent = targetEntity.HPPercent / 100
	
	if runtime_config.Percent == 0 then
		runtime_config = {};
		return;
	end
	runtime_config.PartyServerIds = {}
	for i=0,5 do
		runtime_config.PartyServerIds[party:GetMemberServerId(i)] = party:GetMemberName(i);
	end
	
	runtime_config.Index = targetEntity.TargetIndex
	runtime_config.ServerId = targetEntity.ServerId

	if runtime_config.ActionStartTime ~= nil and runtime_config.ActionStartTime - os.time() >= 3 then
		runtime_config.ActionStartTime = nil;
		runtime_config.Action = nil;
	end

end);

-- draw the target bar table and progress bar
ashita.events.register('d3d_present', 'targetbar_present_cb', function ()
	local windowStyleFlags = libs2imgui.gui_style_table_to_var("imguistyle", addon.name, "window.style");
	local tableStyleFlags = libs2imgui.gui_style_table_to_var("imguistyle", addon.name, "table.style");
	libs2imgui.imgui_set_window(addon.name);
	
	if runtime_config.Index ~= nil then
		if imgui.Begin(addon.name, targetbar_window.is_open, windowStyleFlags) then

			if imgui.BeginTable(addon.name, 4, tableStyleFlags, 0, 0) then
				imgui.TableNextColumn();
				imgui.Text(runtime_config.Target);
				imgui.TableNextColumn();
				imgui.Text(tostring(runtime_config.Percent * 100));
				imgui.TableNextColumn();
				if runtime_config.Action ~= nil then
					imgui.Text(runtime_config.Action);
				end
				imgui.TableNextColumn();
				if runtime_config.TargetName ~= nil then
					imgui.Text(runtime_config.TargetName);
				end
				
				imgui.EndTable();
			end
			
			local color = libs2imgui.get_color('health', mechanics.health_percent_to_status(runtime_config.Percent));
			imgui.PushStyleColor(ImGuiCol_PlotHistogram, color);
			imgui.ProgressBar(runtime_config.Percent, {-1.0, 0.0}, "");
			imgui.PopStyleColor();
		end
		imgui.End();
	end
end);