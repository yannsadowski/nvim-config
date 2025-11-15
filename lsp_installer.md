# First Step : Clone nvim-lspconfig
git clone https://github.com/neovim/nvim-lspconfig ~/.config/nvim/pack/nvim/start/nvim-lspconfig

# Second Step : Install Package Manager
    1. /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    2. curl -LsSf https://astral.sh/uv/install.sh | sh
    3. curl https://sh.rustup.rs -sSf | sh

# Third Step : Install of LSP for each langage
    1. npm install basedpyright
    2. npm i -g bash-language-server
    3. brew install lua-language-server
    4. brew install marksman
    5. nix profile install github:nix-community/nixd
    6. brew install texlab
    7. cargo install --git https://github.com/Myriad-Dreamin/tinymist --locked tinymist-cli
    8. uvx ty
