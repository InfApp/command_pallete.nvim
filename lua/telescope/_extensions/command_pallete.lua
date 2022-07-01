local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local drop_down_theme = require("telescope.themes").get_dropdown{}
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local state = require "telescope.state"
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



function CreateBufferChangeHandler(cached_state)
	return function(text)
		local cmd = string.gsub(text, "%s+", " ")
		local last_char = string.sub(cmd,-1)
		if last_char ==' ' or #cmd == 1 then
			if #cmd == 1 then
				cmd = ''
			end
			cached_state['items'] = vim.fn.getcompletion(cmd,'cmdline')
			for key,value in ipairs(cached_state['items']) do
				cached_state['items'][key] = {
					value = cmd..value,
					display = cmd..value,
					ordinal= cmd..value
				}
			end
		end
		return cached_state['items']
	end
end


function OnSpace(prompt_bufnr)
	return function()
		local selection = action_state.get_selected_entry()
		local picker =  action_state.get_current_picker(prompt_bufnr)
		if(selection == nil) then
			local text =  action_state.get_current_line()
			picker:reset_prompt(text.." ")
			return
		end
		picker:reset_prompt(selection.value.." ")
	end
end

function Command_pallete()
	local cached_state =  {
		items = nil,
		cached_command=nil
	}
	local finder = finders.new_dynamic{
		entry_maker = function (entry)
			return entry
		end,
		fn = CreateBufferChangeHandler(cached_state),
	}
	local opts = {
		prompt_title = "Commands",
		sorter = conf.generic_sorter({}),
		finder = finder,
		attach_mappings = function(prompt_bufnr, _)
		actions.select_default:replace(function()
			actions.close(prompt_bufnr)
			local cmd =  action_state.get_current_line()
			vim.cmd(cmd)
		end)
		_('i','<SPACE>',OnSpace(prompt_bufnr))
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
