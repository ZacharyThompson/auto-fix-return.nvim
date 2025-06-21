# 🧰 auto-fix-return.nvim
Adds or removes parenthesis from Golang return defintions as you type. 

Supports 
- Functions
- Methods
- Interfaces
- Single returns 
- Multi returns 
- Named returns 
- Channel returns

Coming soon: 
- Closures

and hopefully all combinations of the above. If you find a bug please report it as an issue. 

## Preview
![high_res_final](https://github.com/user-attachments/assets/a5b9b50d-cbc7-42a6-b3f7-e20795c93823)

> [!IMPORTANT]
> The plugin attempts to add parenthesis as you type. Which means that its mostly working off of invalid parse trees.
> This is very nice to use but makes it very difficult to cover all edgecases from a parsing standpoint, as different error states of the tree can be matched incorectly. 
> If you find an error state that is not covered please report it as an issue. 
> 
> You can run the command `AutoFixReturn disable` to turn off the autocommnd and make whatever changes you need to that line. 
> Then reenable the plugin with `AutoFixReturn enable` and the line will not be edited unless you touch the declarations return definition again.

> [!TIP]
> You can always invoke the fix manually with `AutoFixReturn` as long as your cursor is in the return definition.

## Compatibility

Due to attempting to use in progress or invalid parse trees this plugin is very sensitive to changes in the compiled version of the underlying Go treesitter parer.


> [!IMPORTANT]
> The current tested version of the Go parser that this plugin was written against is [5e73f476efafe5c768eda19bbe877f188ded6144](https://github.com/tree-sitter/tree-sitter-go/commit/5e73f476efafe5c768eda19bbe877f188ded6144)

> [!NOTE]
> If you are using `nvim-treesitter` you can view your installed Go parser version with the following command
> ```
> :lua vim.print(io.open(require("nvim-treesitter.configs").get_parser_info_dir() .. "/go.revision"):read("*a"))
> ```

Using an untested parser version may or may not work in all scenarios. The plugin will not write the fix back to the buffer in the case the fix will generate an invalid parse tree. So an untested parser version will refuse to make fixes in some circumstances. 

## Installation

> [!IMPORTANT]  
> Requires the Go treesitter parser to be installed.
> You can run `TSInstall go` if using nvim-treesitter.

#### Lazy
```lua
return {
  "Jay-Madden/auto-fix-return.nvim",

  -- nvim-treesitter is optional, the plugin will work fine without it as long as 
  -- you have a valid Go parser in $rtp/parsers.
  -- However due to the Go grammar not being on Treesitter ABI 15 without 'nvim-treesitter' 
  -- we are unable to detect and warn if an invalid parser version is being used.
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },

  config = function()
    require("auto-fix-return").setup({})
  end
}
```

## ⚙️ Configuration

#### Defaults
```lua
require("auto-fix-return").setup({
  -- Enable or disable the autofix on type behvaior
  enabled = true, 
})
```

### Commands

`AutoFixReturn`: Format the function definition under the cursor, adding or removing parenthesis as needed

`AutoFixReturn enable`: Enable the autofix on type behavior

`AutoFixReturn disable`: Disable the autofix on type behavior
