require("plenary.test_harness")
local eq = assert.are.same

local autofix = require("auto-fix-return")
autofix.setup({ enable_autocmds = false })

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
---
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
local function get_win_lines(winid)
  local bufnr = vim.api.nvim_win_get_buf(winid)
  return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

---@param winid integer
---@return integer,integer
local function get_cursor_coords(winid)
  local row, col = unpack(vim.api.nvim_win_get_cursor(winid))
  return row, col
end

---@param winid integer
---@return string
local function get_cursor_char(winid)
  local row, col = get_cursor_coords(winid)
  local char = get_win_lines(winid)[row]:sub(col+1,col+1)
  return char
end

--- Setup the test buffer with the provided string as the value
--- Additionally interpret `|` as the position we wish to simulate the cursor being in
---@param value string|string[]
---@return integer
local function set_test_window_value(value)
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
local function cleanup_test(winid)
  vim.api.nvim_win_close(winid, true)
end

describe("test functions with body defined", function()
  describe("when a single return is started with cursor at the end of the first type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() i| {}")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() i {}", lines[1])
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("i", char)
    end)
  end)

  describe("when a single channel return is started with cursor at the end of the first type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() chan i| {}")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() chan i {}", lines[1])
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("i", char)
    end)
  end)

  describe("when a single send only channel return is started with cursor at the end of the first type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() chan<- i| {}")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() chan<- i {}", lines[1])
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("i", char)
    end)
  end)

  describe("when a single recieve only channel return is started with cursor at the end of the first type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() <-chan i| {}")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() <-chan i {}", lines[1])
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("i", char)
    end)
  end)

  describe("when a single named channel return is started with cursor at the end of the first type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() c chan i| {}")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() (c chan i) {}", lines[1])
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("i", char)
    end)
  end)

  describe("when a single named send only channel return is started with cursor at the end of the first type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() c chan<- i| {}")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() (c chan<- i) {}", lines[1])
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("i", char)
    end)
  end)

  describe("when a single named recieve only channel return is started with cursor at the end of the first type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() c <-chan i| {}")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() (c <-chan i) {}", lines[1])
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("i", char)
    end)
  end)

  describe("when a single return has parenthesis ", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() (i|) {}")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() i {}", lines[1])
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("i", char)
    end)
  end)

  describe("when a single return has no name and a valid return definition", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func |() i {}")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not touch anything", function()
      local lines = get_win_lines(winid)
      eq("func () i {}", lines[1])
    end)

    it("should keep the cursor on the i", function()
      local char = get_cursor_char(winid)
      eq(" ", char)
    end)
  end)

  describe("when a single return with comma has an invalid proceeding type definition with cursor in return definition", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value({"func Foo() i,| {}",
        "",
        "type foo"}
      )
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type as the fix parse contains errors and we are not sure it is safe", function()
      local lines = get_win_lines(winid)
      local expected = {
        "func Foo() i, {}",
        "",
        "type foo"
      }
      eq(expected, lines)
    end)

    it("should make sure the cursor stays in front of the comma", function()
      local char = get_cursor_char(winid)
      eq(",", char)
    end)
  end)

  describe("when a single return with comma has an invalid proceeding type definition with cursor in invalid type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value({"func Foo() i, {}",
        "",
        "type f|oo"}
      )
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      local expected = {
        "func Foo() i, {}",
        "",
        "type foo"
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("f", char)
    end)
  end)

  describe("when a single return with comma has an invalid proceeding type definition with cursor in the function name", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value({"func Fo|o() i, {}",
        "",
        "type foo"}
      )
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      local expected = {
        "func Foo() i, {}",
        "",
        "type foo"
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("o", char)
    end)
  end)

  describe(
    "when a single return is started with cursor at the end of the first type with a comma",
    function()
      local winid = 0
      before_each(function()
        winid = set_test_window_value("func Foo() i,| {}")
        vim.cmd("AutoFixReturn")
      end)

      it("should add parentheses around the return type", function()
        local lines = get_win_lines(winid)
        eq("func Foo() (i,) {}", lines[1])
      end)

      it("should set the cursor to inside the parens", function()
        local char = get_cursor_char(winid)
        eq(",", char)
      end)
    end
  )

  describe("when a multi return is started with cursor at the end of the second type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() int, s| {}")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() (int, s) {}", lines[1])
    end)

    it("should set the cursor to inside the parens", function()
      local char = get_cursor_char(winid)
      eq("s", char)
    end)
  end)

  describe("when a multi channel return is started with cursor at the end of the second type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() chan i, t| {}")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() (chan i, t) {}", lines[1])
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("t", char)
    end)
  end)

  describe("when a multi channel return with multiple channels is started with cursor at the end of the second type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() chan i, chan t| {}")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() (chan i, chan t) {}", lines[1])
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("t", char)
    end)
  end)

  describe("when a multi send only channel return is started with cursor at the end of the second type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() chan<- i, t| {}")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() (chan<- i, t) {}", lines[1])
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("t", char)
    end)
  end)

  describe("when a multi recieve only channel return is started with cursor at the end of the second type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() <-chan i, t| {}")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() (<-chan i, t) {}", lines[1])
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("t", char)
    end)
  end)

  describe("when a multi return exists with cursor at the start of the first type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() i|nt, s {}")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() int, s {}", lines[1])
    end)

    it("not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("i", char)
    end)
  end)

  describe("when a multi return has parenthesis and only one body brace", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() (i,s) {|")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not modify anything", function()
      local lines = get_win_lines(winid)
      eq("func Foo() (i,s) {", lines[1])
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("{", char)
    end)
  end)

  describe("when a multi return exists with cursor not in the return definition", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func F|oo() int, s {}")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() int, s {}", lines[1])
    end)

    it("not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("F", char)
    end)
  end)

  describe("when a multi return exists with cursor in the body definition", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() int, s {|}")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() int, s {}", lines[1])
    end)

    it("not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("{", char)
    end)
  end)
end)

describe("test functions without a body defined", function()
  describe("when a single return is started with cursor at the end of the first type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() i|")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() i", lines[1])
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("i", char)
    end)
  end)

  describe("when a single return has parenthesis", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() (i|)")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should remove parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() i", lines[1])
    end)

    it("should keep the cursor on the i", function()
      local char = get_cursor_char(winid)
      eq("i", char)
    end)
  end)

  describe("when a single return has no name and a valid return definition", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func |() i")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not touch anything", function()
      local lines = get_win_lines(winid)
      eq("func () i", lines[1])
    end)

    it("should keep the cursor on the i", function()
      local char = get_cursor_char(winid)
      eq(" ", char)
    end)
  end)

  describe("when a single return with comma has an valid preceeding type definition with cursor in return definition", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value({"func Foo() i {}",
        "",
        "func Bar() i,|"}
      )
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      local expected = {
        "func Foo() i {}",
        "",
        "func Bar() (i,)"
      }
      eq(expected, lines)
    end)

    it("should make sure the cursor stays in front of the comma", function()
      local char = get_cursor_char(winid)
      eq(",", char)
    end)
  end)


  describe(
    "when a multi return is started with cursor at the end of the first type with a comma",
    function()
      local winid = 0
      before_each(function()
        winid = set_test_window_value("func Foo() i,|")
        vim.cmd("AutoFixReturn")
      end)

      after_each(function()
        cleanup_test(winid)
      end)

      it("should add parentheses around the return type and comma", function()
        local lines = get_win_lines(winid)
        eq("func Foo() (i,)", lines[1])
      end)

      it("should set the cursor to inside the parens", function()
        local char = get_cursor_char(winid)
        eq(",", char)
      end)
    end)


  describe("when a multi return is started with cursor at the end of the second type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() int, s|")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() (int, s)", lines[1])
    end)

    it("should set the cursor to inside the parens", function()
      local char = get_cursor_char(winid)
      eq("s", char)
    end)
  end)

  describe("when a multi return exists with cursor at the start of the first type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() i|nt, s")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() int, s", lines[1])
    end)

    it("not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("i", char)
    end)
  end)

  describe("when a multi return exists with cursor not in the return definition", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func F|oo() int, s")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() int, s", lines[1])
    end)

    it("not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("F", char)
    end)
  end)

  describe("when a multi channel return is started with cursor at the end of the second type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() chan i, t|")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() (chan i, t)", lines[1])
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("t", char)
    end)
  end)

  describe("when a multi channel return with multiple channels is started with cursor at the end of the second type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() chan i, chan t|")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() (chan i, chan t)", lines[1])
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("t", char)
    end)
  end)

  describe("when a multi send only channel return is started with cursor at the end of the second type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() chan<- i, t|")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() (chan<- i, t)", lines[1])
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("t", char)
    end)
  end)

  describe("when a multi recieve only channel return is started with cursor at the end of the second type", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value("func Foo() <-chan i, t|")
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = get_win_lines(winid)
      eq("func Foo() (<-chan i, t)", lines[1])
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("t", char)
    end)
  end)
end)

describe("test non function syntax constructs", function()
  describe("when editing a for loop initialization", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value({
        "package main",
        "",
        "import \"fmt\"",
        "",
        "func main() {",
        "  for i:=0|;i<10;i++{",
        "    fmt.Println(\"Hello\")",
        "  }",
        "}"
      })
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not modify the code", function()
      local lines = get_win_lines(winid)
      local expected = {
        "package main",
        "",
        "import \"fmt\"",
        "",
        "func main() {",
        "  for i:=0;i<10;i++{",
        "    fmt.Println(\"Hello\")",
        "  }",
        "}"
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("0", char)
    end)
  end)

  describe("when editing a for loop condition", function()
    local winid = 0
    before_each(function()
      winid = set_test_window_value({
        "package main",
        "",
        "import \"fmt\"",
        "",
        "func main() {",
        "  for i:=0;i<1|0;i++{",
        "    fmt.Println(\"Hello\")",
        "  }",
        "}"
      })
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      cleanup_test(winid)
    end)

    it("should not modify the code", function()
      local lines = get_win_lines(winid)
      local expected = {
        "package main",
        "",
        "import \"fmt\"",
        "",
        "func main() {",
        "  for i:=0;i<10;i++{",
        "    fmt.Println(\"Hello\")",
        "  }",
        "}"
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = get_cursor_char(winid)
      eq("1", char)
    end)
  end)
end)
