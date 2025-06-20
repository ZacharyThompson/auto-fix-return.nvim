local M = {}

---@class TextGrid
---@field start_row number
---@field start_col number
---@field end_row number
---@field end_col number

---Check if cursor is on the same row as any node with the specified capture name
---@param query vim.treesitter.Query The parsed TreeSitter query
---@param tree TSTree The parse tree root
---@param cursor_row number The cursor row (0-indexed for TreeSitter)
---@param capture_name string The capture name to look for (e.g., "func", "elem")
---@return boolean found
function M.find_node_on_cursor_row(query, tree, cursor_row, capture_name)
  for id, node, _, _ in query:iter_captures(tree:root(), 0) do
    local current_capture_name = query.captures[id]
    if current_capture_name == capture_name then
      local start_row, _, _, _ = node:range()
      if cursor_row == start_row then
        return true
      end
    end
  end
  return false
end

return M
