local lib = require("auto-fix-return.lib")

local M = {}

---@class AutoFixReturnConfig
---@field enable_autocmds boolean

---@return AutoFixReturnConfig
function M.get_default_config()
  local config = {
    enable_autocmds = true,
  }

  return config
end

---@param config AutoFixReturnConfig
M.setup = function(config)
  local default_config = M.get_default_config()
  local final_config = vim.tbl_deep_extend("force", default_config, config)

  if final_config.enable_autocmds then
    lib.enable_autocmds()
  end

  lib.setup_user_commands()
end

return M
