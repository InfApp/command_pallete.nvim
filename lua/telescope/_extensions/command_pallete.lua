local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local drop_down_theme = require("telescope.themes").get_dropdown{}
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local make_entry = require "telescope.make_entry"
local cmd_pallete = require'command_pallete'

function GetAllCommands()
	local command_iter = vim.api.nvim_get_commands {}
	local commands = {}

	for _, cmd in pairs(command_iter) do
		table.insert(commands, cmd)
	end
	local buf_command_iter = vim.api.nvim_buf_get_commands(0, {})
	buf_command_iter[true] = nil -- remove the redundant entry
	for _, cmd in pairs(buf_command_iter) do
	table.insert(commands, cmd)
	end
	return commands
end


function GetPromtValue(prompt_bufnr)
	local buf = vim.api.nvim_buf_get_lines(prompt_bufnr,0,1,true)
	local _, value = next(buf)

	local picker = action_state.get_current_picker(prompt_bufnr)
	local prompt_prefix = picker['prompt_prefix']
	local value = string.gsub(value,prompt_prefix,'')
	local stripped = string.gsub(value, "%s+", "")
	return stripped
end

function ErrorMsg(msg)
	vim.notify('Command: '..msg..' not found','ERROR')
	actions.close(prompt_bufnr)
end


function Command_pallete()
	local finder = finders.new_table{
		results = GetAllCommands(),
		entry_maker = make_entry.gen_from_commands({}),
	}
	local opts = {
		prompt_title = "Commands",
		sorter = conf.generic_sorter({}),
		finder = finder,
		attach_mappings = function(prompt_bufnr, _)
		actions.select_default:replace(function()
			local selection = action_state.get_selected_entry()
			local prompt_value =  GetPromtValue(prompt_bufnr)
			if selection == nil then
				ErrorMsg(prompt_value)
				return
			end
			actions.close(prompt_bufnr)
			local val = selection.value
       		local cmd = string.format([[:%s ]], val.name)
			if val.nargs == "0" and prompt_value ~= '' then
				vim.cmd(cmd)
			  else
				ParamPicker(cmd)
			end
		end)
		return true
		end
	}
	pickers.new(drop_down_theme,opts):find()
end


function ParamPicker(commands)
	local results = vim.fn.getcompletion(commands,'cmdline')
	if table.getn(results) == 0 then
		vim.cmd(commands)
		return
	end
	local finder = finders.new_table{
		results = results,
	}
	local opts = {
		prompt_title = "Commands",
		sorter = conf.generic_sorter({}),
		finder = finder,
		attach_mappings = function(prompt_bufnr, _)
		actions.select_default:replace(function()
			local selection = action_state.get_selected_entry()
			local prompt_value =  GetPromtValue(prompt_bufnr)
			if selection == nil then
				ErrorMsg(prompt_value)
				return
			end
			actions.close(prompt_bufnr)
			local val = selection.value
       		local cmd = string.format([[:%s ]], val.name)
			if val.nargs == "0" then
				vim.cmd(commands..cmd)
			elseif prompt_value == '' then
				ParamPicker(commands..' '..cmd)
			end
		end)
		return true
		end
	}
	pickers.new(drop_down_theme,opts):find()
end





return require("telescope").register_extension({
    exports = {
        command_pallete = Command_pallete
    },
})
