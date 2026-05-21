# home/modules/dev/neovim.nix
# Toàn bộ config Neovim khai báo bằng Nix.
# Không cần viết Lua thủ công — NixVim tự convert sang Lua.
# Nhưng nếu muốn viết Lua vẫn được, dùng extraConfigLua.
{ nixvim, pkgs, ... }:
{
  # Import NixVim Home Manager module
  imports = [ nixvim.homeModules.nixvim ];

  programs.nixvim = {
    enable      = true;
    defaultEditor = true;  # Đặt nvim làm $EDITOR mặc định

    # ── Colorscheme ─────────────────────────────────────────────────────
    # Cần pywal tạo màu trước khi mở Neovim (~/.cache/wal/colors-wal.vim).
    extraPlugins = with pkgs.vimPlugins; [
      wal-vim
    ];
    extraConfigLua = ''
      vim.cmd.colorscheme("wal")
    '';

    # ── Global Options ───────────────────────────────────────────────────
    # Tương đương với vim.opt.xxx = yyy trong Lua
    opts = {
      number         = true;   # Hiện số dòng tuyệt đối
      relativenumber = true;   # Hiện số dòng tương đối (tiện di chuyển)
      tabstop        = 2;      # Tab = 2 spaces
      shiftwidth     = 2;      # Indent = 2 spaces
      expandtab      = true;   # Dùng spaces thay vì tab
      smartindent    = true;   # Auto indent thông minh
      wrap           = false;  # Không wrap dòng dài
      cursorline     = true;   # Highlight dòng hiện tại
      scrolloff      = 8;      # Giữ 8 dòng khoảng cách khi scroll
      signcolumn     = "yes";  # Luôn hiện cột ký hiệu (LSP, git)
      updatetime     = 50;     # Thời gian cập nhật (ms)
      termguicolors  = true;   # Màu 24-bit đầy đủ
      undofile       = true;   # Lưu undo history vào file
      ignorecase     = true;   # Tìm kiếm không phân biệt hoa thường
      smartcase      = true;   # Nhưng phân biệt nếu gõ hoa
      splitright     = true;   # Split ngang mở sang phải
      splitbelow     = true;   # Split dọc mở xuống dưới
      clipboard      = "unnamedplus"; # Sync clipboard với hệ thống
    };

    # ── Global Variables ─────────────────────────────────────────────────
    # Tương đương vim.g.xxx = yyy
    globals = {
      mapleader      = " ";   # Space là leader key
      maplocalleader = " ";
    };

    # ── Keymaps ──────────────────────────────────────────────────────────
    # mode: "n" = normal, "i" = insert, "v" = visual, "x" = visual block
    keymaps = [
      # File navigation
      { mode = "n"; key = "<leader>e";  action = "<cmd>NvimTreeToggle<cr>";    options.desc = "Toggle file tree"; }
      { mode = "n"; key = "<leader>ff"; action = "<cmd>Telescope find_files<cr>"; options.desc = "Find files"; }
      { mode = "n"; key = "<leader>fg"; action = "<cmd>Telescope live_grep<cr>";  options.desc = "Live grep"; }
      { mode = "n"; key = "<leader>fb"; action = "<cmd>Telescope buffers<cr>";    options.desc = "Find buffers"; }
      { mode = "n"; key = "<leader>fh"; action = "<cmd>Telescope help_tags<cr>";  options.desc = "Help tags"; }

      # Buffer navigation
      { mode = "n"; key = "<S-h>"; action = "<cmd>bprevious<cr>"; options.desc = "Previous buffer"; }
      { mode = "n"; key = "<S-l>"; action = "<cmd>bnext<cr>";     options.desc = "Next buffer"; }
      { mode = "n"; key = "<leader>bd"; action = "<cmd>bdelete<cr>"; options.desc = "Delete buffer"; }

      # Window navigation — dùng Ctrl+hjkl như tmux
      { mode = "n"; key = "<C-h>"; action = "<C-w>h"; options.desc = "Move to left window"; }
      { mode = "n"; key = "<C-j>"; action = "<C-w>j"; options.desc = "Move to lower window"; }
      { mode = "n"; key = "<C-k>"; action = "<C-w>k"; options.desc = "Move to upper window"; }
      { mode = "n"; key = "<C-l>"; action = "<C-w>l"; options.desc = "Move to right window"; }

      # LSP keymaps — chỉ active khi có LSP
      { mode = "n"; key = "gd";  action = "<cmd>lua vim.lsp.buf.definition()<cr>";     options.desc = "Go to definition"; }
      { mode = "n"; key = "gD";  action = "<cmd>lua vim.lsp.buf.declaration()<cr>";    options.desc = "Go to declaration"; }
      { mode = "n"; key = "gr";  action = "<cmd>lua vim.lsp.buf.references()<cr>";     options.desc = "Find references"; }
      { mode = "n"; key = "gi";  action = "<cmd>lua vim.lsp.buf.implementation()<cr>"; options.desc = "Go to implementation"; }
      { mode = "n"; key = "K";   action = "<cmd>lua vim.lsp.buf.hover()<cr>";          options.desc = "Hover documentation"; }
      { mode = "n"; key = "<leader>ca"; action = "<cmd>lua vim.lsp.buf.code_action()<cr>"; options.desc = "Code action"; }
      { mode = "n"; key = "<leader>rn"; action = "<cmd>lua vim.lsp.buf.rename()<cr>";      options.desc = "Rename symbol"; }
      { mode = "n"; key = "<leader>d";  action = "<cmd>lua vim.diagnostic.open_float()<cr>"; options.desc = "Show diagnostic"; }
      { mode = "n"; key = "[d";  action = "<cmd>lua vim.diagnostic.goto_prev()<cr>"; options.desc = "Previous diagnostic"; }
      { mode = "n"; key = "]d";  action = "<cmd>lua vim.diagnostic.goto_next()<cr>"; options.desc = "Next diagnostic"; }

      # Format
      { mode = "n"; key = "<leader>f"; action = "<cmd>lua vim.lsp.buf.format()<cr>"; options.desc = "Format file"; }

      # Misc
      { mode = "n"; key = "<leader>nh"; action = "<cmd>nohl<cr>"; options.desc = "Clear search highlight"; }
      { mode = "i"; key = "jk";  action = "<ESC>"; options.desc = "Exit insert mode nhanh"; }
      { mode = "v"; key = "<";   action = "<gv"; options.desc = "Indent left và giữ selection"; }
      { mode = "v"; key = ">";   action = ">gv"; options.desc = "Indent right và giữ selection"; }
      # Di chuyển dòng lên/xuống trong visual mode
      { mode = "v"; key = "J";   action = ":m '>+1<CR>gv=gv"; options.desc = "Move line down"; }
      { mode = "v"; key = "K";   action = ":m '<-2<CR>gv=gv"; options.desc = "Move line up"; }
    ];

    # ── Plugins ───────────────────────────────────────────────────────────
    plugins = {

      # Treesitter — syntax highlighting tốt hơn mặc định
      # Parse code thành AST thay vì dùng regex
      treesitter = {
        enable = true;
        settings = {
          highlight.enable  = true;
          indent.enable     = true;
          # Tự động cài grammar cho các ngôn ngữ này
          ensure-installed  = [
            "nix" "lua" "python" "javascript" "typescript"
            "rust" "go" "c" "cpp" "html" "css" "json"
            "yaml" "toml" "markdown" "bash" "vim"
          ];
        };
      };
     
      web-devicons.enable = true;

      # Telescope — fuzzy finder mạnh nhất cho Neovim
      # Dùng Space+ff để tìm file, Space+fg để grep toàn project
      telescope = {
        enable = true;
        settings = {
          defaults = {
            prompt_prefix    = "  ";
            selection_caret  = " ";
            path_display     = [ "smart" ];
            # Layout rộng hơn cho màn hình lớn
            layout_config.horizontal.preview_width = 0.55;
          };
        };
      };

      # LSP — Language Server Protocol
      # Cung cấp: autocomplete, go-to-definition, hover docs,
      # rename, code actions, diagnostics
      lsp = {
        enable = true;
        servers = {
          # Nix LSP — cần thiết khi chỉnh config NixOS
          nixd.enable = true;

          # Python LSP
          pyright.enable = true;

          # JavaScript/TypeScript LSP
          ts_ls.enable = true;

          # Rust LSP — tự động cài rust-analyzer
          rust_analyzer = {
            enable              = true;
            installCargo        = true;
            installRustc        = true;
          };

          # Go LSP
          gopls.enable = true;

          # Lua LSP — cần khi viết config Neovim thuần Lua
          lua_ls = {
            enable = true;
            settings.Lua = {
              diagnostics.globals = [ "vim" ];
            };
          };

          # CSS/HTML LSP
          cssls.enable    = true;
          html.enable     = true;

          # JSON LSP với schema validation
          jsonls.enable   = true;

          # Bash LSP
          bashls.enable   = true;

          # YAML LSP
          yamlls.enable   = true;
        };
      };

      # Autocompletion — nvim-cmp với nhiều sources
      cmp = {
        enable = true;
        settings = {
          # Sources theo thứ tự ưu tiên
          sources = [
            { name = "nvim_lsp"; }   # Gợi ý từ LSP server
            { name = "luasnip"; }    # Gợi ý từ snippets
            { name = "buffer"; }     # Gợi ý từ text trong buffer
            { name = "path"; }       # Gợi ý đường dẫn file
          ];
          # Keymaps cho autocomplete menu
          mapping = {
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>"     = "cmp.mapping.close()";
            "<CR>"      = "cmp.mapping.confirm({ select = true })";
            "<Tab>"     = "cmp.mapping.select_next_item()";
            "<S-Tab>"   = "cmp.mapping.select_prev_item()";
            "<C-d>"     = "cmp.mapping.scroll_docs(4)";
            "<C-u>"     = "cmp.mapping.scroll_docs(-4)";
          };
        };
      };

      # Snippets engine cho cmp
      luasnip.enable            = true;
      cmp-nvim-lsp.enable       = true;
      cmp-buffer.enable         = true;
      cmp-path.enable           = true;
      cmp_luasnip.enable        = true;

      # File tree bên trái
      nvim-tree = {
        enable = true;
        settings = {
          view.width    = 30;
          renderer.group_empty = true;
          filters.dotfiles     = false;  # Hiện dotfiles
        };
      };

      # Statusline đẹp ở dưới cùng
      lualine = {
        enable = true;
        settings.options = {
          theme                = "auto";
          section_separators   = { left = ""; right = ""; };
          component_separators = { left = ""; right = ""; };
        };
      };

      # Buffer tabs ở trên cùng
      bufferline = {
        enable = true;
        settings.options = {
          diagnostics             = "nvim_lsp";
          show_buffer_close_icons = true;
          separator_style         = "slant";
        };
      };

      # Git signs trong gutter — hiện dòng nào được thêm/sửa/xóa
      gitsigns = {
        enable = true;
        settings = {
          signs = {
            add.text          = "│";
            change.text       = "│";
            delete.text       = "_";
            topdelete.text    = "‾";
            changedelete.text = "~";
          };
        };
      };

      # Auto pairs — tự động thêm ), ], }, ", '
      nvim-autopairs.enable = true;

      # Comment dễ dàng — gcc để comment dòng, gc trong visual mode
      comment.enable = true;

      # Indent guides — đường kẻ dọc để thấy rõ indent level
      indent-blankline.enable = true;

      # Which-key — hiện popup gợi ý khi bạn bắt đầu nhấn keybinding
      which-key.enable = true;

      # Null-ls — chạy linters và formatters như LSP
      none-ls = {
        enable = true;
        sources = {
          formatting = {
            # Python formatter
            black.enable      = true;
            isort.enable      = true;
            # JavaScript/TypeScript formatter
            prettier = {
              enable = true;
              disableTsServerFormatter = true;  
            };
            # Nix formatter
            nixpkgs_fmt.enable = true;
            # Shell formatter
            shfmt.enable      = true;
          };
        };
      };

      # Dashboard — màn hình welcome khi mở nvim không có file
      dashboard = {
        enable = true;
        settings = {
          theme = "doom";
          config = {
            header = [
              ""
              "  ███╗   ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗"
              "  ████╗  ██║██║╚██╗██╔╝██║   ██║██║████╗ ████║"
              "  ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║██║██╔████╔██║"
              "  ██║╚██╗██║██║ ██╔██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║"
              "  ██║ ╚████║██║██╔╝ ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║"
              "  ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝"
              ""
            ];
            shortcut = [
              { desc = "  Find File";    key = "f"; action = "Telescope find_files"; }
              { desc = "  Recent Files"; key = "r"; action = "Telescope oldfiles"; }
              { desc = "  Config";       key = "c"; action = "e /etc/nixos/home/home.nix"; }
              { desc = "  Quit";         key = "q"; action = "q"; }
            ];
          };
        };
      };

      # Highlight màu hex trực tiếp trong code
      colorizer.enable = true;

      # Smooth scrolling
      neoscroll.enable = true;
    };

    # ── Extra packages cần cho LSP và formatters ───────────────────────────
    extraPackages = with pkgs; [
      # Formatters
      black         # Python
      isort         # Python imports
      nodePackages.prettier  # JS/TS/HTML/CSS
      nixpkgs-fmt   # Nix
      shfmt         # Shell

      # Linters
      # python3Packages.flake8
      shellcheck

      # LSP dependencies
      nodePackages.typescript-language-server
      nodePackages.vscode-langservers-extracted  # HTML, CSS, JSON
      nodePackages.bash-language-server
      yaml-language-server
      gopls         # Go
      nixd          # Nix
      pyright       # Python
    ];
  };
}
