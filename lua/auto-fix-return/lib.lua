local M = {}

local command_id = 0

M.setup_user_commands = function()
  vim.api.nvim_create_user_command("AutoFixReturn", function()
    M.wrap_golang_return()
  end, {})

  vim.api.nvim_create_user_command("AutoFixReturnEnable", function()
    M.enable_autocmds()
  end, {})

  vim.api.nvim_create_user_command("AutoFixReturnDisable", function()
    M.disable_autocomds()
  end, {})
end

M.enable_autocmds = function()
  if command_id ~= 0 then
    vim.notify("AutoFixReturn autocommands already enabled", vim.log.levels.INFO)
    return
  end

  command_id = vim.api.nvim_create_autocmd(
    { "TextChangedI", "TextChanged" },
    { callback = M.wrap_golang_return }
  )
end

function M.disable_autocomds()
  if command_id == 0 then
    vim.notify("AutoFixReturn autocommands already disabled", vim.log.levels.INFO)
    return
  end

  vim.api.nvim_del_autocmd(command_id)
  command_id = 0
end

---@class TextGrid
---@field start_row number
---@field start_col number
---@field end_row number
---@field end_col number

-- Parse function declarations and return the definition grid if applicable
---@return TextGrid?
function M.parse_function()
  local query_str = [[
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
        
        ;; The following definition `func Foo() i,|` parses
        ;; with the final error token for the , outside of the function_declaration
        (ERROR)? @outside_error_end
      )
    ]
  ]]

  local cursor_row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  -- cursor coordinates need to be converted from row native 1 indexed to 0 indexed for treesitter
  cursor_row = cursor_row - 1
  local query = vim.treesitter.query.parse("go", query_str)

  local tree = vim.treesitter.get_parser(0):parse(false)[1]

  local final_start_col, final_end_col = 0, 0

  -- Find the initial func capture so we can bail out
  -- if the cursor is not on the same row as a `func`
  -- 
  -- We need to know upfront if a given parse is even valid to be fixed 
  -- as we dont know the order we will detect the matches in the match iterator
  local found = false
  for id, node, _, _ in query:iter_captures(tree:root(), 0) do
    local capture_name = query.captures[id]
    if capture_name == "func" then
      local start_row, _, _, _= node:range()
      if cursor_row == start_row then
        found = true
        break
      end
    end
  end

  if not found then
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
    elseif capture_name == "error_end" or capture_name == "outside_error_start" or capture_name == "outside_error_end" then
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

---Validate if a given fix is syntactically valid by testing it in a scratch buffer first
---@param curr_bufnr integer
---@param parse_fix ParseFixValues
---@returns boolean
function M.validate_fix(curr_bufnr, parse_fix)

  -- Build a scratch buffer to test the fix first before we apply it to the user buffer
  local new_bufnr = vim.api.nvim_create_buf(true, true)
  vim.bo[new_bufnr].filetype = "go"
  vim.api.nvim_buf_set_lines(new_bufnr, 0, -1, false, vim.api.nvim_buf_get_lines(curr_bufnr, 0, -1, false))

  vim.api.nvim_buf_set_text(
    new_bufnr,
    parse_fix.grid.start_row,
    parse_fix.grid.start_col,
    parse_fix.grid.end_row,
    parse_fix.grid.end_col,
    { parse_fix.text_value }
  )

  -- Test if there are any ERROR tokens in the parse tree, we should not generate invalid parses
  local error_query = "(ERROR)"
  local query = vim.treesitter.query.parse("go", error_query)
  local tree = vim.treesitter.get_parser(new_bufnr):parse(false)[1]
  local error_found = false

  for _ in query:iter_matches(tree:root(), 0) do
    error_found = true
    break
  end

  vim.api.nvim_buf_delete(new_bufnr, {force = true})

  return not error_found
end

---@class ParseFixValues
---@field grid TextGrid
---@field text_value string
---@field final_cursor_column number

---@return ParseFixValues?
function M.parse_return()
  -- This query attempts to match all valid and also most common invalid or inprogress syntax trees for a function declaration
  -- short_var_declaration is for the edge case of named returns
  -- EXAMPLE: func foo() err error { }
  -- local query_str = [[
  -- [
  --     (
  --        ;; The default case for most method/function declarations, they are the only ones that have the named field "result"
  --        ;; so we can generally rely on that to be accurate with the (ERROR) tokens preceeding or proceeding it to give us the
  --        ;; complete range of the intended return declaration
  --       (_
  --        (ERROR)? @error_start
  --        result: (_) @result
  --        (ERROR)? @error_end
  --        )
  --        ;; The in progress parse tree for interface method declarations places the error token
  --        ;; one level up in the tree
  --        ;; type: (interface_type ; [15, 9] - [17, 1]
  --        ;;   (method_elem ; [16, 2] - [16, 11]
  --        ;;     name: (field_identifier) ; [16, 2] - [16, 5]
  --        ;;     parameters: (parameter_list) ; [16, 5] - [16, 7]
  --        ;;     result: (type_identifier)) ; [16, 8] - [16, 11]
  --        ;;   (ERROR)))) ; [16, 11] - [16, 12]
  --        ;; We need to handle this case specifically so we anchor it to the ancestor node for interface
  --        (
  --          (ERROR)? @error_interface_end (#has-parent? @error_interface_end interface_type)
  --        )
  --     )
  --     ;; This is a weird edgecase in regards to handling multi returns, an in progress multireturn on a top level function is
  --     ;; parsed intermediately as a short_var_declaration so we have to anchor it to the actual function declaration itself
  --     ;; to prevent incorrect matches on non method syntaxes E.G a for loop
  --     (
  --       (function_declaration)
  --       (short_var_declaration
  --           left: (expression_list
  --               (identifier) @named_result
  --               (ERROR (identifier) @error_end)?
  --           )
  --       )
  --     )
  -- ]
  -- ]]
  --
  -- local query = vim.treesitter.query.parse("go", query_str)
  local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
  -- cursor coordinates need to be converted from row native 1 indexed to 0 indexed for treesitter
  cursor_row = cursor_row - 1
  --
  -- -- We make sure to call the entire parse again to make sure we have the most up to date tree
  -- -- NOTE: without this the bugs are a bit nasty
  -- local tree = vim.treesitter.get_parser(0):parse(true)[1]
  --
  -- local final_start_row, final_start_col, final_end_row, final_end_col = 0, 0, 0, 0
  --
  -- for id, node, _, _ in query:iter_captures(tree:root(), 0) do
  --   local start_row, _, end_row, end_col = node:range()
  --
  --   -- Multiline return statements are very finicky to parse correctly
  --   if cursor_row < start_row + 1 or cursor_row > end_row + 1 then
  --     goto continue
  --   end
  --
  --   local capture_name = query.captures[id]
  --
  --   -- If we find a start error then we know we are possibly doing a named return
  --   if capture_name == "error_start" then
  --     final_start_row, final_start_col, final_end_row, final_end_col = node:range()
  --   elseif capture_name == "result" and final_end_row == 0 then
  --     final_start_row, final_start_col, final_end_row, final_end_col = node:range()
  --   elseif capture_name == "named_result" then
  --     final_end_col = end_col + 1
  --     final_end_row = end_row
  --   elseif capture_name == "result" and final_end_row ~= 0 then
  --     final_end_col = end_col
  --     final_end_row = end_row
  --   elseif capture_name == "error_end" or capture_name == "error_interface_end" then
  --     final_end_col = end_col
  --     final_end_row = end_row
  --   end
  --
  --   ::continue::
  -- end

  local return_def_coords = M.parse_function()

  if return_def_coords == nil then
    return
  end

  local line = vim.api.nvim_buf_get_text(
    0,
    return_def_coords.start_row,
    return_def_coords.start_col,
    return_def_coords.end_row,
    return_def_coords.end_col,
    {}
  )[1]

  if line == "" then
    return
  end

  -- Here we rebuild the entire return statement to a syntactically correct version
  -- splitting on commas to decide if there is a parameter list or a single value
  -- Strip the parens off, we will add them back if we need to
  local value = string.gsub(line, "%(", "")
  value = string.gsub(value, "%)", "")

  -- We will need to move the cursor depending on the action that we take,
  -- grab the current cusor position so we can adjust it below
  local final_cursor_col = cursor_col

  -- If there are any commas in the return definition we know we will need parenthesis
  local returns = vim.split(value, ",")

  local function trim_end(s)
    return s:gsub("%s+$", "")
  end

  -- If we do not have any commas we might still be doing a named return
  -- `E.G func foo() err e` <- once the e is typed we know a named return has been
  -- initiated and we should lex it again,
  -- however, we need to trim the leading space so we dont surround the return after you have hit space with
  -- JUST a type return
  if #returns == 1 then
    local trimmed = trim_end(value)

    local temp_returns = {}
    local curr_word = ""

    -- We iterate over the string and split it on spaces to build up a possible named return
    -- but `chan` syntax is unique in that a single return that is a channel type DOES NOT
    -- require parenthesis, this is for all forms of channel including `chan` `<-chan` and `chan<-`
    for c in trimmed:gmatch(".") do
      -- This technically does not handle a case like `func foo() chan<- int a b c` but as this will never be syntactically valid go code we can ignore it
      if c == " " and not (curr_word:find("^chan") ~= nil or curr_word:find("chan$") ~= nil) then
        temp_returns[#temp_returns + 1] = curr_word
        curr_word = ""
      end

      curr_word = curr_word .. c
    end

    if curr_word ~= "" then
        temp_returns[#temp_returns + 1] = curr_word
    end

    returns = temp_returns
  end

  local new_line = line

  -- If returns just equals one we know we have a single return and do
  -- not need parenthesis
  -- Here we also need to set the offset for the CURSOR to be placed after we do the text replacement
  if #returns == 1 then
    final_cursor_col = final_cursor_col - 1
    new_line = value
  else
    final_cursor_col = final_cursor_col + 1
    new_line = "(" .. value .. ")"
  end

  -- If the line has not changed or theres nothing to add then we just bail out here
  if line == new_line then
    return
  end

  -- If the cursor is positioned outside of the immediate return declaration match then we do not want to touch it as this can
  -- cause weird behavior when editing parts of a function that are unrelated to the return declaration and if there is a weird edge that triggers
  --
  -- We offset the final column start value to avoid edgecases with regards to using 'daw' or similar on a method_declaration
  -- E.G
  --              daw
  -- func (f Foo) B|ar() int {}
  -- ->
  -- func (f Foo) () int {}
  -- This parse will break without the final_start_col offset
  if cursor_col < return_def_coords.start_col + 1 or cursor_col > return_def_coords.end_col then
    return
  end

  return {
    grid=return_def_coords,
    text_value = new_line,
    final_cursor_column = final_cursor_col,
  }
end

function M.wrap_golang_return()
  if vim.bo.filetype ~= "go" then
    return
  end

  local parse_fix = M.parse_return()
  if parse_fix == nil then
    return
  end

  local valid_fix = M.validate_fix(0, parse_fix)
  if not valid_fix then
    vim.notify("AutoFixReturn: Invalid return fix, not applying", vim.log.levels.DEBUG)
    return
  end

  vim.api.nvim_buf_set_text(
    0,
    parse_fix.grid.start_row,
    parse_fix.grid.start_col,
    parse_fix.grid.end_row,
    parse_fix.grid.end_col,
    { parse_fix.text_value }
  )

  vim.api.nvim_win_set_cursor(0, { parse_fix.grid.end_row + 1, parse_fix.final_cursor_column })
end

return M
