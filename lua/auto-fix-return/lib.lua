local fix = require("auto-fix-return.fix")

local M = {}

local command_id = 0
local registered_ts_cbs_bufs = {}

M.setup_user_commands = function()
  vim.api.nvim_create_user_command("AutoFixReturn", function(opts)
    if #opts.fargs == 0 then
      fix.wrap_golang_return()
    elseif opts.fargs[1] == "enable" then
      M.enable_tree_cbs()
    elseif opts.fargs[1] == "disable" then
      M.disable_ts_cbs()
    end
  end, {
    nargs = "?",
    complete = function()
      return { "enable", "disable" }
    end,
  })
end

M.enable_tree_cbs = function()
  if command_id ~= 0 then
    vim.notify("AutoFixReturn: handlers already enabled", vim.log.levels.INFO)
    return
  end

  command_id = vim.api.nvim_create_autocmd({ "BufReadPost" }, { callback = M.register_buf_handler })

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

  vim.notify("AutoFixReturn: Enabled on buffers", vim.log.levels.INFO)
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
        M.wrap_golang_return()
        processing = false
      end)
    end,
  }, false)
end

function M.disable_buf_ts_cbs()
  for bufnr, _ in pairs(registered_ts_cbs_bufs) do
    registered_ts_cbs_bufs[bufnr] = false
  end
  vim.notify("AutoFixReturn: Disabled on buffers", vim.log.levels.INFO)
end

function M.disable_ts_cbs()
  if command_id == 0 then
    vim.notify("AutoFixReturn: already disabled", vim.log.levels.INFO)
    return
  end

  vim.api.nvim_del_autocmd(command_id)
  command_id = 0

  M.disable_buf_ts_cbs()
end

return M
