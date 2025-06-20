local M = {}

---@param value string[]
---@return integer,integer,boolean
local function get_test_input_cursor_coords(value)
  local cursor_pos = nil
  for i, s in ipairs(value) do
    cursor_pos = string.find(s, "|")
    if cursor_pos ~= nil then
      --- Make sure to decrement the cursor position by two because we remove the | character below and also convert to zero indexing
      return i, cursor_pos - 2, true
    end
  end
  return 0,0,false
end

---@param value string[]
---@return string[]
local function replace_test_input_cursor_value(value)
  for i, s in ipairs(value) do
    local new_s, c = s:gsub("%|", "")
    if c > 0 then
      value[i] = new_s
      return value
    end
  end
  return value
end

---@param winid integer
---@return string[]
function M.get_win_lines(winid)
  local bufnr = vim.api.nvim_win_get_buf(winid)
  return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

---@param winid integer
---@return integer,integer
function M.get_cursor_coords(winid)
  local row, col = unpack(vim.api.nvim_win_get_cursor(winid))
  return row, col
end

---@param winid integer
---@return string
function M.get_cursor_char(winid)
  local row, col = M.get_cursor_coords(winid)
  local char = M.get_win_lines(winid)[row]:sub(col+1,col+1)
  return char
end

--- Setup the test buffer with the provided string as the value
--- Additionally interpret `|` as the position we wish to simulate the cursor being in
---@param value string|string[]
---@return integer
function M.set_test_window_value(value)
  if type(value) == "string" then
    value = {value}
  end

  local row, col, found = get_test_input_cursor_coords(value)

  if not found then
    error("Test value found without cursor placeholder set")
  end

  value = replace_test_input_cursor_value(value)
  local bufnr = vim.api.nvim_create_buf(true, false)
  local winid = vim.api.nvim_open_win(bufnr, true, {split = 'left',win = 0})
  vim.bo[bufnr].filetype = "go"

  vim.api.nvim_buf_set_lines(bufnr, 0, #value + 1, false,  value)

  vim.api.nvim_win_set_cursor(winid, { row, col})

  return winid
end

---@param winid integer
function M.cleanup_test(winid)
  vim.api.nvim_win_close(winid, true)
end

return M