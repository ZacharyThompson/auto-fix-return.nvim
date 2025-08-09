require("plenary.test_harness")
local eq = assert.are.same
local utils = require("test.utils")

utils.initialize_test_nvim_opts()

local autofix = require("auto-fix-return")
autofix.setup({
  enabled = false,
  log_level = vim.log.levels.DEBUG,
})

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

  describe("when a single generic return has one paramater", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() foo[T]|",
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
        "  Bar() foo[T]",
        "}",
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = utils.get_cursor_char(winid)
      eq("]", char)
    end)
  end)

  describe("when a single generic return has two paramaters with a space", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() foo[T, V]|",
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
        "  Bar() foo[T, V]",
        "}",
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = utils.get_cursor_char(winid)
      eq("]", char)
    end)
  end)

  describe("when a single generic return has two paramaters without a space", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() foo[T,V]|",
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
        "  Bar() foo[T,V]",
        "}",
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = utils.get_cursor_char(winid)
      eq("]", char)
    end)
  end)

  describe("when a single generic return has one parameter with trailing comma", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() foo[T],|",
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
        "  Bar() (foo[T],)",
        "}",
      }
      eq(expected, lines)
    end)

    it("should set cursor at the comma", function()
      local char = utils.get_cursor_char(winid)
      eq(",", char)
    end)
  end)

  describe(
    "when a single generic return has two parameters with space and trailing comma",
    function()
      local winid = 0
      before_each(function()
        winid = utils.set_test_window_value({
          "type Foo interface {",
          "  Bar() foo[T, V],|",
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
          "  Bar() (foo[T, V],)",
          "}",
        }
        eq(expected, lines)
      end)

      it("should set cursor at the comma", function()
        local char = utils.get_cursor_char(winid)
        eq(",", char)
      end)
    end
  )

  describe(
    "when a single generic return has two parameters without space and trailing comma",
    function()
      local winid = 0
      before_each(function()
        winid = utils.set_test_window_value({
          "type Foo interface {",
          "  Bar() foo[T,V],|",
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
          "  Bar() (foo[T,V],)",
          "}",
        }
        eq(expected, lines)
      end)

      it("should set cursor at the comma", function()
        local char = utils.get_cursor_char(winid)
        eq(",", char)
      end)
    end
  )

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

  describe(
    "when interface method has a multi return with an empty interface and the cursor on the comma",
    function()
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
    end
  )

  describe(
    "when interface with multiple methods has a multi return with an empty interface and the cursor on the comma",
    function()
      local winid = 0
      before_each(function()
        winid = utils.set_test_window_value({
          "type Foo interface {",
          "  Bax() int",
          "  Bar() interface{},|",
          "  Baz() string",
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
          "  Bax() int",
          "  Bar() (interface{},)",
          "  Baz() string",
          "}",
        }
        eq(expected, lines)
      end)

      it("should keep cursor at end of type", function()
        local char = utils.get_cursor_char(winid)
        eq(",", char)
      end)
    end
  )

  describe(
    "when interface with multiple methods has a multi return with parentheses around an empty interface",
    function()
      local winid = 0
      before_each(function()
        winid = utils.set_test_window_value({
          "type Foo interface {",
          "  Bax() int",
          "  Bar() (interface{}|)",
          "  Baz() string",
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
          "  Bax() int",
          "  Bar() interface{}",
          "  Baz() string",
          "}",
        }
        eq(expected, lines)
      end)

      it("should keep cursor at end of type", function()
        local char = utils.get_cursor_char(winid)
        eq("}", char)
      end)
    end
  )

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

  describe("when a single send-only channel return is started", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() chan<- int|",
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
        "  Bar() chan<- int",
        "}",
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = utils.get_cursor_char(winid)
      eq("t", char)
    end)
  end)

  describe("when a single receive-only channel return is started", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() <-chan int|",
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
        "  Bar() <-chan int",
        "}",
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = utils.get_cursor_char(winid)
      eq("t", char)
    end)
  end)

  describe("when a single named bidirectional channel return is started", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() c chan int|",
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
        "  Bar() (c chan int)",
        "}",
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = utils.get_cursor_char(winid)
      eq("t", char)
    end)
  end)

  describe("when a single named send-only channel return is started", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() c chan<- int|",
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
        "  Bar() (c chan<- int)",
        "}",
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = utils.get_cursor_char(winid)
      eq("t", char)
    end)
  end)

  describe("when a single named receive-only channel return is started", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() c <-chan int|",
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
        "  Bar() (c <-chan int)",
        "}",
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = utils.get_cursor_char(winid)
      eq("t", char)
    end)
  end)

  describe("when an interface method has multi channel returns", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() chan int, chan string|",
        "}",
      })
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      utils.cleanup_test(winid)
    end)

    it("should add parentheses around the return types", function()
      local lines = utils.get_win_lines(winid)
      local expected = {
        "type Foo interface {",
        "  Bar() (chan int, chan string)",
        "}",
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = utils.get_cursor_char(winid)
      eq("g", char)
    end)
  end)

  describe("when an interface method has multi return with a channel and error", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() chan int, error|",
        "}",
      })
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      utils.cleanup_test(winid)
    end)

    it("should add parentheses around the return types", function()
      local lines = utils.get_win_lines(winid)
      local expected = {
        "type Foo interface {",
        "  Bar() (chan int, error)",
        "}",
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = utils.get_cursor_char(winid)
      eq("r", char)
    end)
  end)

  describe("when a single slice channel return is started", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() chan []int|",
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
        "  Bar() chan []int",
        "}",
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = utils.get_cursor_char(winid)
      eq("t", char)
    end)
  end)

  describe("when a single map channel return is started with cursor at the end", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() chan map[string]int|",
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
        "  Bar() chan map[string]int",
        "}",
      }
      eq(expected, lines)
    end)

    it("should not touch the cursor", function()
      local char = utils.get_cursor_char(winid)
      eq("t", char)
    end)
  end)

  describe("when a single channel return has unnecessary parentheses", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() (chan int|)",
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
        "  Bar() chan int",
        "}",
      }
      eq(expected, lines)
    end)

    it("should keep cursor on the type", function()
      local char = utils.get_cursor_char(winid)
      eq("t", char)
    end)
  end)

  describe("when a named channel return has necessary parentheses", function()
    local winid = 0
    before_each(function()
      winid = utils.set_test_window_value({
        "type Foo interface {",
        "  Bar() (c chan int|)",
        "}",
      })
      vim.cmd("AutoFixReturn")
    end)

    after_each(function()
      utils.cleanup_test(winid)
    end)

    it("should not modify the parentheses", function()
      local lines = utils.get_win_lines(winid)
      local expected = {
        "type Foo interface {",
        "  Bar() (c chan int)",
        "}",
      }
      eq(expected, lines)
    end)

    it("should keep cursor on the type", function()
      local char = utils.get_cursor_char(winid)
      eq("t", char)
    end)
  end)

  describe(
    "when multiple interface methods exist with channels with the middle being named and multi return",
    function()
      local winid = 0
      before_each(function()
        winid = utils.set_test_window_value({
          "type Foo interface {",
          "  Bar() chan int",
          "  Baz() c chan<- string,|",
          "  Bax() <-chan error",
          "}",
        })
        vim.cmd("AutoFixReturn")
      end)

      after_each(function()
        utils.cleanup_test(winid)
      end)

      it(
        "should not modify anything as the parse tree is completely broken at this point",
        function()
          local lines = utils.get_win_lines(winid)
          local expected = {
            "type Foo interface {",
            "  Bar() chan int",
            "  Baz() c chan<- string,",
            "  Bax() <-chan error",
            "}",
          }
          eq(expected, lines)
        end
      )

      it("should set the cursor to inside the parens", function()
        local char = utils.get_cursor_char(winid)
        eq(",", char)
      end)
    end
  )

  describe(
    "when a single function interface has multi return with only one starting parentheses",
    function()
      local winid = 0
      before_each(function()
        winid = utils.set_test_window_value({
          "type Foo interface {",
          "  Bar() (i,k|",
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
          "  Bar() (i,k)",
          "}",
        }
        eq(expected, lines)
      end)

      it("should set the cursor to inside the parens", function()
        local char = utils.get_cursor_char(winid)
        eq("k", char)
      end)
    end
  )

  describe(
    "when a single function interface has multi return with only one ending parentheses",
    function()
      local winid = 0
      before_each(function()
        winid = utils.set_test_window_value({
          "type Foo interface {",
          "  Bar() i|,k)",
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
          "  Bar() (i,k)",
          "}",
        }
        eq(expected, lines)
      end)

      it("should set the cursor to inside the parens", function()
        local char = utils.get_cursor_char(winid)
        eq("(", char)
      end)
    end
  )

  describe(
    "when a multiple function interface has multi return with only one starting parentheses",
    function()
      local winid = 0
      before_each(function()
        winid = utils.set_test_window_value({
          "type Foo interface {",
          "  Bax() int",
          "  Bar() (i,k|",
          "  Baz() string",
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
          "  Bax() int",
          "  Bar() (i,k)",
          "  Baz() string",
          "}",
        }
        eq(expected, lines)
      end)

      it("should set the cursor to inside the parens", function()
        local char = utils.get_cursor_char(winid)
        eq("k", char)
      end)
    end
  )

  describe(
    "when a multiple function interface has multi return with only one ending parentheses",
    function()
      local winid = 0
      before_each(function()
        winid = utils.set_test_window_value({
          "type Foo interface {",
          "  Bax() int",
          "  Bar() i|,k)",
          "  Baz() string",
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
          "  Bax() int",
          "  Bar() (i,k)",
          "  Baz() string",
          "}",
        }
        eq(expected, lines)
      end)

      it("should set the cursor to inside the parens", function()
        local char = utils.get_cursor_char(winid)
        eq("(", char)
      end)
    end
  )
end)
