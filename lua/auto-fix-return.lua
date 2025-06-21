local lib = require("auto-fix-return.lib")

local M = {}

---@class AutoFixReturnConfig
---@field enabled boolean

---@return AutoFixReturnConfig
function M.get_default_config()
  local config = {
    enabled = true,
  }

  return config
end

---@param config AutoFixReturnConfig
function M.setup(config)
  local default_config = M.get_default_config()
  local final_config = vim.tbl_deep_extend("force", default_config, config)

  if final_config.enabled then
    lib.enable_tree_cbs()
  end

  lib.setup_user_commands()
end

return M
