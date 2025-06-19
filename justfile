fmt:
    stylua lua/ --config-path=stylua.toml

test:
    #!/bin/bash
    echo "===== Running Tests ====="
    
    if [[ ! -d "testbin/plenary.nvim" ]] ; then
        git clone --depth 1 https://github.com/nvim-lua/plenary.nvim testbin/plenary.nvim
    fi
    
    nvim --headless -u scripts/minimal_init.lua -c "PlenaryBustedDirectory lua/test/"