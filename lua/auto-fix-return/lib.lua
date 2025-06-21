local fix = require("auto-fix-return.fix")

local M = {}

local command_id = 0
local registered_ts_cbs_bufs = {}

local TESTED_PARSER_REV = "5e73f476efafe5c768eda19bbe877f188ded6144"

---If possible pull the installed TreeSitter parser version from 'nvim-treesitter'
---@return string|nil
function M.get_parser_version()
  local ts_config = require("nvim-treesitter.configs")
  if ts_config == nil then
    return nil
  end

  local rev_file = io.open(ts_config.get_parser_info_dir() .. "/go.revision")

  if rev_file == nil then
    return nil
  end

  local rev = rev_file:read("*a")
  local value = string.gsub(rev, '"', "")
  value = string.gsub(value, "\n", "")

  return value
end

function M.setup_user_commands()
  vim.api.nvim_create_user_command("AutoFixReturn", function(opts)
    if #opts.fargs == 0 then
      fix.wrap_golang_return()
    elseif opts.fargs[1] == "enable" then
      M.enable_tree_cbs()
      vim.notify("AutoFixReturn: Enabled on all buffers", vim.log.levels.INFO)
    elseif opts.fargs[1] == "disable" then
      M.disable_ts_cbs()
      vim.notify("AutoFixReturn: Disabled on all buffers", vim.log.levels.INFO)
    end
  end, {
    nargs = "?",
    complete = function()
      return { "enable", "disable" }
    end,
  })
end

function M.enable_tree_cbs()
  local rev = M.get_parser_version()

  if rev ~= nil and rev ~= TESTED_PARSER_REV then
    vim.notify(
      "AutoFixReturn: Current Go treesitter parser version '"
        .. rev
        .. "' is not tested with this plugin.\n"
        .. "If you encounter issues please upgrade your Go Treesitter parser to the tested version '"
        .. TESTED_PARSER_REV
        .. "'",
      vim.log.levels.WARN
    )
  end

  for bufnr, _ in pairs(registered_ts_cbs_bufs) do
    registered_ts_cbs_bufs[bufnr] = true
  end

  -- Register callbacks on current Go buffers that aren't registered yet
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and registered_ts_cbs_bufs[bufnr] == nil then
      if vim.bo[bufnr].filetype == "go" then
        M.register_buf_cbs(bufnr)
        registered_ts_cbs_bufs[bufnr] = true
      end
    end
  end

  if command_id ~= 0 then
    return
  end

  -- Register the autocmd to handle buffer read events that attach ts callbacks to the buffers parser
  command_id = vim.api.nvim_create_autocmd({ "BufReadPost" }, { callback = M.register_buf_handler })
end

function M.register_buf_handler(event)
  local bufnr = event.buf
  M.register_buf_cbs(bufnr)
  registered_ts_cbs_bufs[bufnr] = true
end

function M.register_buf_cbs(bufnr)
  if vim.bo[bufnr].filetype ~= "go" then
    return
  end

  local tree = vim.treesitter.get_parser(bufnr)

  if tree == nil then
    return
  end

  -- We can not modify the tree in the on_changedtree callback
  -- so we use a flag to prevent re-entrancy and dispatch the
  -- auto fix via schedule
  local processing = false
  tree:register_cbs({
    on_changedtree = function()
      if not registered_ts_cbs_bufs[bufnr] then
        return
      end
      if processing then
        return
      end
      processing = true
      vim.schedule(function()
        fix.wrap_golang_return()
        processing = false
      end)
    end,
  }, false)
end

function M.disable_buf_ts_cbs()
  for bufnr, _ in pairs(registered_ts_cbs_bufs) do
    registered_ts_cbs_bufs[bufnr] = false
  end
end

function M.disable_ts_cbs()
  if command_id == 0 then
    return
  end

  vim.api.nvim_del_autocmd(command_id)
  command_id = 0

  M.disable_buf_ts_cbs()
end

return M
