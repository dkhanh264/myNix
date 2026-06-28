{ config, pkgs, ... }:

{
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    globals.mapleader = " ";
    opts = {
      number = true;
      relativenumber = true;
      wrap = false;
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      smartindent = true;
      swapfile = false;
      guicursor = "";
      ignorecase = true;
      scrolloff = 10;
      winborder = "rounded";
    };

    extraPlugins = with pkgs.vimPlugins; [
      cord-nvim
    ];


    extraPackages = with pkgs; [
      tree-sitter
      git
      ripgrep
      fd
      nixpkgs-fmt
      kdePackages.qtdeclarative
      kdlfmt
    ];

    autoCmd = [
      {
        event = "BufWritePost";
        pattern = "*.kdl";
        command = "!kdlfmt -i %";
      }
    ];

    plugins.web-devicons = {
      enable = true;
    };

    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        transparent_background = true;
        integrations = {
          cmp = true;
          gitsigns = true;
          treesitter = true;
          harpoon = true;
          telescope = true;
          notify = true;
        };
        custom_highlights = ''
          function(colors)
            return {
              NormalFloat = { bg = "NONE" },
              FloatBorder = { bg = "NONE" },
            }
          end
        '';
      };
    };

    plugins.dashboard = {
      enable = true;
      settings = {
        theme = "doom";
        config = {
          header = [
            "        "
            "        "
            "        "
            "        "
            "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⢀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
            "⠀⠀⠀⠀⠀⣀⣀⠀⠠⣄⣉⡶⢿⣷⣿⣷⣶⣶⣮⣄⡠⡀⡀⣠⣄⡀⠀⠀⠀⠀"
            "⠀⠀⠀⣄⡾⣫⢒⢾⣾⣿⢟⢥⣶⣶⣶⣮⣖⠾⡙⢿⣿⣦⡊⡲⣶⣆⠀⠀⠀⠀"
            "⠀⠀⠀⢬⣾⢣⣳⣿⡿⢑⣵⣿⣿⣷⠹⣿⣿⣿⣮⡳⡝⣿⣿⡔⠙⣿⣇⠀⠀⠀"
            "⠀⠀⢠⣿⡏⢲⣿⡿⣱⣿⣿⡿⡻⣱⣿⣝⢞⢿⢿⣿⣮⠎⣿⣿⡔⠸⣿⠀⠀⠀"
            "⠀⠀⡜⣾⠁⣿⣿⢳⡿⡛⠁⠌⢾⣿⣿⣿⣧⠀⠑⢝⢿⣏⠘⣿⣷⠀⣿⡆⠀⠀"
            "⠀⢀⢻⡟⣷⣿⣿⣈⣼⣾⣿⣮⣹⣿⣿⣿⣿⣾⣿⣮⣳⢝⣴⢻⣿⢸⢹⣧⡆⠀"
            "⣀⣘⣿⣧⢿⣿⣿⢿⣿⠋⠉⠉⣿⣿⣿⣿⣿⡙⠉⠙⣿⡇⢸⢸⣿⢨⠬⠭⠤⠤"
            "⢢⣝⢿⣯⡝⢿⡟⣼⣿⣿⣿⣿⣿⣿⡉⢙⣿⣿⣿⣿⣿⡏⢄⣿⡟⢰⣿⡿⡧⠇"
            "⡄⣎⣵⡙⡧⢏⢷⢑⢻⣿⣿⣿⣿⣿⣿⡿⢿⣿⣿⣿⣿⠁⣼⠏⠠⠛⣱⣴⡆⡏"
            "⣧⣿⣿⣿⣷⡉⠈⠣⢻⣿⣿⣿⣯⣟⣻⣇⣿⣿⣿⣿⡿⢑⠁⠁⢲⣿⣿⣿⣇⣷"
            "⢸⣿⣿⣿⣿⣇⠀⠀⠈⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠑⠁⠀⠀⢸⣿⣿⣿⣿⣿"
            "⢸⣿⣿⣿⣿⣿⠀⠀⠀⣀⠀⠈⠹⠛⣻⣛⠻⠉⠀⡀⢸⣀⠀⠀⣸⣿⣿⠿⢨⣿"
            "⢸⡏⣿⣿⣿⣿⣧⢰⣿⢸⡄⠁⠢⠀⣤⣤⣤⡲⠟⡁⣾⣿⣿⢸⡟⣛⣵⡇⡼⡿"
            "⢀⣟⠹⠻⣟⣛⢿⣾⢧⢀⣿⡸⢣⢾⣟⢿⢣⣼⣶⣠⣟⣛⣻⣴⡆⣿⣿⢁⠇⣦"
            "        "
            "        "
            "        "
          ];
          center = [
            { icon = " "; desc = "Find File              "; action = "Telescope find_files"; key = "f"; }
            { icon = " "; desc = "Quit Neovim          "; action = "qa"; key = "q"; }
          ];
        };
      };
    };

    plugins.indent-blankline = {
      enable = true;
      settings.exclude.filetypes = [ "dashboard" ];
    };

    plugins.neoscroll = {
      enable = true;
      settings = {
        easing = "linear";
        cursor_scrolls_alone = true;
        mappings = [ "<C-u>" "<C-d>" ];
        duration_multiplier = 0.5;
      };
    };

    plugins.notify = {
      enable = true;
      settings = {
        background_colour = "#000000";
        render = "compact";
        stages = "fade";
        timeout = 2000;
        max_width = 60;
      };
    };

    plugins.telescope = {
      enable = true;
      keymaps = {
        "<leader>ff" = { action = "find_files"; options.desc = "Telescope Find Files"; };
        "<leader>fg" = { action = "live_grep"; options.desc = "Telescope Live Grep"; };
        "<leader>fb" = { action = "buffers"; options.desc = "Telescope Buffers"; };
        "<leader>fh" = { action = "help_tags"; options.desc = "Telescope Help"; };
      };
    };

    plugins.oil = {
      enable = true;
      settings = {
        default_file_explorer = true;
        columns = [ "icon" ];
        delete_to_trash = false;
        skip_confirm_for_simple_edits = false;
        view_options = {
          show_hidden = false;
        };
        float = {
          padding = 2;
          max_width = 0;
          max_height = 0;
          border = "rounded";
        };
        keymaps = {
          "g?" = "actions.show_help";
          "<CR>" = "actions.select";
          "-" = "actions.parent";
          "_" = "actions.open_cwd";
        };
      };
    };

    plugins.ts-autotag = {
      enable = true;
    };

    plugins.nvim-autopairs.enable = true;

    plugins.gitsigns = {
      enable = true;
      settings.signs = {
        add = { text = "┃"; };
        change = { text = "┃"; };
        delete = { text = "_"; };
        topdelete = { text = "‾"; };
        changedelete = { text = "~"; };
      };
    };

    plugins.blink-cmp = {
      enable = true;
    }; 

    plugins.conform-nvim = {
      enable = true;

      settings = {
        formatters_by_ft = {
          nix = [ "nixfmt" ];

          javascript = [ "prettier" ];
          javascriptreact = [ "prettier" ];

          typescript = [ "prettier" ];
          typescriptreact = [ "prettier" ];

          html = [ "prettier" ];
          css = [ "prettier" ];
          json = [ "prettier" ];
          yaml = [ "prettier" ];
        };
      };
    };

    plugins.comment.enable = true;

    plugins.which-key.enable = true;

    plugins.lualine.enable = true;

    plugins.treesitter = {
      enable = true;

      settings = {
        highlight.enable = true;
        indent.enable = true;
      };

      nixGrammars = false;
      package = pkgs.vimPlugins.nvim-treesitter.withAllGrammars;
    };

    plugins.lsp = {
      enable = true;
      servers = {
        html.enable = true;
        cssls.enable = true;
        tailwindcss = {
          enable = true;
          settings = {
            tailwindCSS.experimental.classRegex = [
              "class\\s*=\\s*['\"]([^'\"]*)['\"]"
            ];
          };
        };
        jsonls = {
          enable = true;
        };
        nixd = {
          enable = true;
        };
        ts_ls.enable = true;

        qmlls = {
          enable = true;
          filetypes = [ "qmljs" "qml" ];
        };
      };
    };
    extraConfigLua = ''
      local signs = { Error = "󰅚 ", Warn = "󰀪 ", Hint = "󰌶 ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end
    '';

    plugins.harpoon = {
      enable = true;
      enableTelescope = true;
    };


    keymaps = [
      {
        mode = "n";
        key = "<leader>a";
        action.__raw = "function() require('harpoon'):list():add() end";
        options.desc = "Harpoon Add File";
      }
      {
        mode = "n";
        key = "<leader>h";
        action.__raw = "function() local harpoon = require('harpoon'); harpoon.ui:toggle_quick_menu(harpoon:list()) end";
        options.desc = "Harpoon Menu";
      }
      {
        mode = "n";
        key = "<M-1>";
        action.__raw = "function() require('harpoon'):list():select(1) end";
        options.desc = "Harpoon File 1";
      }
      {
        mode = "n";
        key = "<M-2>";
        action.__raw = "function() require('harpoon'):list():select(2) end";
        options.desc = "Harpoon File 2";
      }
      {
        mode = "n";
        key = "<M-3>";
        action.__raw = "function() require('harpoon'):list():select(3) end";
        options.desc = "Harpoon File 3";
      }
      {
        mode = "n";
        key = "<M-4>";
        action.__raw = "function() require('harpoon'):list():select(4) end";
        options.desc = "Harpoon File 4";
      }
      {
        mode = "n";
        key = "<S-Tab>";
        action.__raw = "function() require('harpoon'):list():next() end";
        options.desc = "Harpoon Next";
      }
      {
        mode = "n";
        key = "<Tab>";
        action.__raw = "function() require('harpoon'):list():prev() end";
        options.desc = "Harpoon Prev";
      }
      # regular keymaps
      { mode = "n"; key = "<leader>w"; action = "<cmd>w<CR>"; options.desc = "Save"; }
      { mode = "n"; key = "<leader>q"; action = "<cmd>cclose<CR>"; options = { silent = true; desc = "Close Quickfix"; }; }
      { mode = "n"; key = "<leader>o"; action = "<cmd>update<CR><cmd>source %<CR>"; options.desc = "Update and Source"; }
      { mode = "v"; key = "<C-j>"; action = ":m '>+1<CR>gv=gv"; options = { silent = true; desc = "Move line down"; }; }
      { mode = "v"; key = "<C-k>"; action = ":m '<-2<CR>gv=gv"; options = { silent = true; desc = "Move line up"; }; }
      { mode = "n"; key = "<leader>lf"; action = "<cmd>Format<CR>"; options.desc = "Format"; }
      { mode = "n"; key = "-"; action = "<cmd>Oil<CR>"; options.desc = "Open Parent Directory"; }
      { mode = "n"; key = "<leader>l"; action = "<cmd>lua require('notify').dismiss({ silent = true, pending = true })<CR>"; options.desc = "Dismiss Notifications"; }
      { mode = "n"; key = "[d"; action = "<cmd>lua vim.diagnostic.goto_prev()<CR>"; }
      { mode = "n"; key = "]d"; action = "<cmd>lua vim.diagnostic.goto_next()<CR>"; }
      { mode = "n"; key = "<leader>d"; action = "<cmd>lua vim.diagnostic.open_float()<CR>"; }
      {
        mode = "n";
        key = "<leader>ll";
        action = "\\lv";
        options = {
          remap = true;
          desc = "VimTeX Preview";
        };
      }
    ];
  };
}
