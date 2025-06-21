local shared = require("auto-fix-return.parsers.shared")

local M = {}

-- Parse interface method declarations and return the definition grid if applicable
---@param cursor_row number The cursor row (1-indexed as from nvim_win_get_cursor)
---@return TextGrid?
function M.parse_interface(cursor_row)
  -- cursor coordinates need to be converted from row native 1 indexed to 0 indexed for treesitter
  cursor_row = cursor_row - 1

  local query = vim.treesitter.query.parse("go", [[
    [
      (
        (method_elem
          name: (_)
          parameters: (_)
          (ERROR)? @error_start
          result: (_) @result
        ) @elem
        .
        (ERROR)? @error_end
      )
      (
        (method_elem
          name: (_)
          parameters: (_)
          !result
        ) @elem
        .
        (ERROR)? @outside_error_end
      )
	]
  ]]
)

  local tree = vim.treesitter.get_parser(0):parse(false)[1]

  local final_start_col, final_end_col = 0, 0

  -- Find the initial elem capture so we can bail out
  -- if the cursor is not on the same row as the `method_elem` node
  --
  -- We need to know upfront if a given parse is even valid to be fixed
  if not shared.find_node_on_cursor_row(query, tree, cursor_row, "elem") then
    return nil
  end

  for id, node, _, _ in query:iter_captures(tree:root(), 0) do
    local capture_name = query.captures[id]
    local start_row, start_col, end_row, end_col = node:range()

    -- We only care about captures that are on the same row as the cursor
    -- as multiline returns are tricky to parse correctly
    if cursor_row ~= start_row or cursor_row ~= end_row then
      goto continue
    end

    if capture_name == "error_start" then
      final_start_col = start_col
    elseif capture_name == "result" then
      -- As result is the middle result if either start or end
      -- are already set we should do nothing
      if final_start_col == 0 then
        final_start_col = start_col
      end

      if final_end_col == 0 then
        final_end_col = end_col
      end
    elseif capture_name == "error_end" then
      final_end_col = end_col
    elseif capture_name == "outside_error_end" then
      -- Rarely the outside error will also include the starting range, see the ts query for the case where this happens
      if final_start_col == 0 then
        final_start_col = start_col
      end
      final_end_col = end_col
    end

    ::continue::
  end

  return {
    start_row = cursor_row,
    end_row = cursor_row,
    start_col = final_start_col,
    end_col = final_end_col,
  }
end

return M
