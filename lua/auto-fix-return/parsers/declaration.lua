local shared = require("auto-fix-return.parsers.shared")

local M = {}

-- Parse function and method declarations and return the definition grid if applicable
---@param cursor_row number The cursor row (1-indexed as from nvim_win_get_cursor)
---@return TextGrid?
function M.parse_declaration(cursor_row)
  -- cursor coordinates need to be converted from row native 1 indexed to 0 indexed for treesitter
  cursor_row = cursor_row - 1
  local query = vim.treesitter.query.parse(
    "go",
    [[
    [
      ;; The following code 
      ;;
      ;; func Foo() i, 
      ;;
      ;; type foo
      ;;
      ;; parses with the error token ABOVE the function declaration 
      ;; so we handle that in a seperate match
      (ERROR
        (function_declaration
          _?
          (ERROR)? @error_start
          result: (_) @result
          (ERROR)? @error_end
          body: (_)? @body
        ) @func
      ) @outside_error_start
      (
        (function_declaration
          _?
          (ERROR)? @error_start
          result: (_) @result
          (ERROR)? @error_end
          body: (_)? @body
        ) @func
        .
        ;; The following definition `func Foo() i,|` parses
        ;; with the final error token for the , outside of the function_declaration
        (ERROR)? @outside_error_end
      )

      ;; For functions that are created above existing valid declarations treesitter
      ;; parses the tree with the error token outside the function declaration and no result field
      ;; so we need to handle that here
      ;; func Foo() i,| 
      ;; 
      ;; func Bar() {}
      (
        (function_declaration
          name: (_)
          parameters: (_) 
          !result
        ) @func
        .
        (ERROR)? @outside_error_end
      )

      ;; For the following code
      ;; func Foo() (string, int| {}
      ;; There is no 'result' node parsed, the error token contains the entire thing
      ;; so we need to special case this input
      (
        (function_declaration
          name: (_)
          parameters: (_) 
          (ERROR)? @result
          !result
          body: (_)
        ) @func
      )

      ;; The following code 
      ;;
      ;; func (b *Bar) Foo() i, 
      ;;
      ;; type foo
      ;;
      ;; parses with the error token ABOVE the function declaration 
      ;; so we handle that in a seperate match
      (ERROR
        (method_declaration
          _?
          (ERROR)? @error_start
          result: (_) @result
          (ERROR)? @error_end
          body: (_)? @body
        ) @func
      ) @outside_error_start
      (
        (method_declaration
          _?
          (ERROR)? @error_start
          result: (_) @result
          (ERROR)? @error_end
          body: (_)? @body
        ) @func
        .
        ;; The following definition `func (b *Bar) Foo() i,|` parses
        ;; with the final error token for the , outside of the method_declaration
        (ERROR)? @outside_error_end
      )

      ;; For the following code
      ;; func (b *Bar) Foo() (string, int| {}
      ;; There is no 'result' node parsed, the error token contains the entire thing
      ;; so we need to special case this input
      (
        (method_declaration
          name: (_)
          parameters: (_) 
          (ERROR)? @result
          !result
          body: (_)
        ) @func
      )

      ;; For methods that are created above existing valid declarations treesitter
      ;; parses the tree with the error token outside the function declaration and no result field
      ;; so we need to handle that here
      ;; func (s *string) Foo() i,| 
      ;; 
      ;; func (s *string) Bar() {}
      (
        (method_declaration
          name: (_)
          parameters: (_) 
          !result
        ) @func
        .
        (ERROR)? @outside_error_end
      )
    ]
  ]]
  )

  local tree = vim.treesitter.get_parser(0):parse(false)[1]

  local final_start_col, final_end_col = 0, 0

  -- Find the initial func capture so we can bail out
  -- if the cursor is not on the same row as a `func`
  --
  -- We need to know upfront if a given parse is even valid to be fixed
  -- as we dont know the order we will detect the matches in the match iterator
  if not shared.find_node_on_cursor_row(query, tree, cursor_row, "func") then
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
    -- The parse tree for `func Foo() int,|` contains the ERROR object OUTSIDE the function_declaration
    -- which contains the final trailing comma so we match this here to extend our match to include the typed comma
    elseif
      capture_name == "error_end"
      or capture_name == "outside_error_start"
      or capture_name == "outside_error_end"
    then
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
