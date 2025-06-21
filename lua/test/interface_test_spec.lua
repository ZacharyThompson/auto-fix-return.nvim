require("plenary.test_harness")
local eq = assert.are.same
local utils = require("test.utils")

local autofix = require("auto-fix-return")
autofix.setup({ enable_autocmds = false })

describe("test interface method declarations", function()
  describe("when a single return is started with cursor at the end of the first type", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() i|",
        "}",
      })
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      utils.cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = utils.get_win_lines(winid)
      local expected = {
        "type Foo interface {",
        "  Bar() i",
        "}",
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = utils.get_cursor_char(winid)
      eq("i", char)
    end)
  end)

  describe("when a single return with comma is started", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() i,|",
        "}",
      })
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      utils.cleanup_test(winid)
    end)

    it("should add parentheses around the return type", function()
      local lines = utils.get_win_lines(winid)
      local expected = {
        "type Foo interface {",
        "  Bar() (i,)",
        "}",
      }
      eq(expected, lines)
    end)

    it("should set the cursor to inside the parens", function()
      local char = utils.get_cursor_char(winid)
      eq(",", char)
    end)
  end)

  describe("when a multi return is started with cursor at the end of the second type", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() int, err|",
        "}",
      })
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      utils.cleanup_test(winid)
    end)

    it("should add parentheses around the return type", function()
      local lines = utils.get_win_lines(winid)
      local expected = {
        "type Foo interface {",
        "  Bar() (int, err)",
        "}",
      }
      eq(expected, lines)
    end)

    it("should set the cursor to inside the parens", function()
      local char = utils.get_cursor_char(winid)
      eq("r", char)
    end)
  end)

  describe("when a single channel return is started", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() chan int|",
        "}",
      })
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      utils.cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = utils.get_win_lines(winid)
      local expected = {
        "type Foo interface {",
        "  Bar() chan int",
        "}",
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = utils.get_cursor_char(winid)
      eq("t", char)
    end)
  end)

  describe("when a single interface return is started", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() interface{}|",
        "}",
      })
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      utils.cleanup_test(winid)
    end)

    it("should not add parentheses around the return type", function()
      local lines = utils.get_win_lines(winid)
      local expected = {
        "type Foo interface {",
        "  Bar() interface{}",
        "}",
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = utils.get_cursor_char(winid)
      eq("}", char)
    end)
  end)

  describe("when a single return has parentheses already", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() (i|)",
        "}",
      })
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      utils.cleanup_test(winid)
    end)

    it("should remove parentheses around the return type", function()
      local lines = utils.get_win_lines(winid)
      local expected = {
        "type Foo interface {",
        "  Bar() i",
        "}",
      }
      eq(expected, lines)
    end)

    it("should keep cursor on the type", function()
      local char = utils.get_cursor_char(winid)
      eq("i", char)
    end)
  end)

  describe("when multiple interface methods exist", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() (int, err)",
        "  Baz() i,|",
        "  Bax() error",
        "}",
      })
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      utils.cleanup_test(winid)
    end)

    it("should only modify the method with cursor", function()
      local lines = utils.get_win_lines(winid)
      local expected = {
        "type Foo interface {",
        "  Bar() (int, err)",
        "  Baz() (i,)",
        "  Bax() error",
        "}",
      }
      eq(expected, lines)
    end)

    it("should set the cursor to inside the parens", function()
      local char = utils.get_cursor_char(winid)
      eq(",", char)
    end)
  end)

  describe("when cursor is not on a method signature", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {|",
        "  Bar() int, err",
        "}",
      })
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      utils.cleanup_test(winid)
    end)

    it("should not modify anything", function()
      local lines = utils.get_win_lines(winid)
      local expected = {
        "type Foo interface {",
        "  Bar() int, err",
        "}",
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = utils.get_cursor_char(winid)
      eq("{", char)
    end)
  end)

  describe("when interface method has named returns", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() result float64, err er|",
        "}",
      })
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      utils.cleanup_test(winid)
    end)

    it("should add parentheses around the named return types", function()
      local lines = utils.get_win_lines(winid)
      local expected = {
        "type Foo interface {",
        "  Bar() (result float64, err er)",
        "}",
      }
      eq(expected, lines)
    end)

    it("should keep cursor at end of type", function()
      local char = utils.get_cursor_char(winid)
      eq("r", char)
    end)
  end)
  
  describe("when interface method has a multi return with an empty interface and the cursor on the comma", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() interface{},|",
        "}",
      })
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      utils.cleanup_test(winid)
    end)

    it("should add parentheses around the named return types", function()
      local lines = utils.get_win_lines(winid)
      local expected = {
        "type Foo interface {",
        "  Bar() (interface{},)",
        "}",
      }
      eq(expected, lines)
    end)

    it("should keep cursor at end of type", function()
      local char = utils.get_cursor_char(winid)
      eq(",", char)
    end)
  end)

  describe("when interface method has complex return types", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        " Bar() map[string][]int, error|",
        "}",
      })
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      utils.cleanup_test(winid)
    end)

    it("should add parentheses around complex return types", function()
      local lines = utils.get_win_lines(winid)
      local expected = {
        "type Foo interface {",
        " Bar() (map[string][]int, error)",
        "}",
      }
      eq(expected, lines)
    end)

    it("should keep cursor at end", function()
      local char = utils.get_cursor_char(winid)
      eq("r", char)
    end)
  end)
end)
