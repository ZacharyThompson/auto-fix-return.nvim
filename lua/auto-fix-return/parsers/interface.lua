local shared = require("auto-fix-return.parsers.shared")

local M = {}

-- Parse interface method declarations and return the definition grid if applicable
---@param cursor_row number The cursor row (1-indexed as from nvim_win_get_cursor)
---@return TextGrid?
function M.parse_interface(cursor_row)
  -- cursor coordinates need to be converted from row native 1 indexed to 0 indexed for treesitter
  cursor_row = cursor_row - 1

  local query = vim.treesitter.query.parse(
    "go",
    [[
    [
      ;; For the following interface
      ;; 
      ;; type baz interface {
      ;; 	Bax() int
      ;; 	Baz() interface{},|
      ;; 	Bax() int
      ;; }
      ;;
      ;; The node containg the END of the definition is
      ;; actually positioned as the ERROR parent node of the method_elem node
      ;; so we need to handle that edgecase here
      (ERROR
        (method_elem
          name: (_)
          parameters: (_)
          result: (_) @result
        ) @elem
      ) @outside_error_above
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

      ;; Special parsing cases for the following code
      ;; 
      ;; type baz interface {
      ;; 	Baz() i|,k)
      ;; }
      ;; ||
      ;; type baz interface {
      ;; 	Baz() (i,k
      ;; }
      ;; This is parsed as either the entire type return in the outside error or 
      ;; the initial type identifier found in result
      (
        (method_elem
          name: (_)
          parameters: (_) 
          result: (_)? @result
        ) @func
        .
        (ERROR) @outside_error_end
      )

      ;; This is a special case for a multi method interface type with a missing end parentheses
      ;; type Foo interface {
      ;;   Bax() int
      ;;   Baz() (i,k,l|
      ;;   Bar() string
      ;; }
      (
        (method_elem
          name: (_)
          parameters: (_) 
          result: (parameter_list
            (parameter_declaration
              name: (identifier) @name
            )
            (ERROR)?
          ) @result_start
        ) @func
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
    elseif capture_name == "name" then
      if end_col > final_end_col then
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

    -- These capture edge cases stretch token stretches across multiple rows so
    -- we need to check it every time even if the continue check above fires
    if capture_name == "outside_error_above" then
      final_end_col = end_col
    end
    if capture_name == "result_start" then
      final_start_col = start_col
    end
  end

  return {
    start_row = cursor_row,
    end_row = cursor_row,
    start_col = final_start_col,
    end_col = final_end_col,
  }
end

return M
