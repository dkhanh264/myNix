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
      softtabstop = 2;
      expandtab = true;
      smartindent = true;

      swapfile = false;
      undofile = true;
      guicursor = "";

      ignorecase = true;
      smartcase = true;

      scrolloff = 10;
      sidescrolloff = 8;

      splitright = true;
      splitbelow = true;

      signcolumn = "yes";
      cursorline = true;
      termguicolors = true;

      updatetime = 250;
      timeoutlen = 400;
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

      # React Native / TypeScript tooling
      nodejs
      typescript
      typescript-language-server
      vscode-langservers-extracted
      tailwindcss-language-server
      yaml-language-server

      # Formatter / linter executables
      prettier
      prettierd
      eslint_d
      nixfmt-rfc-style

      # Existing tooling
      kdePackages.qtdeclarative
      kdlfmt
    ];

    autoCmd = [
      {
        event = "BufWritePost";
        pattern = "*.kdl";
        command = "silent! !kdlfmt -i %";
      }
    ];

    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        transparent_background = true;

        integrations = {
          blink_cmp = true;
          gitsigns = true;
          treesitter = true;
          harpoon = true;
          telescope = true;
          notify = true;
          nvimtree = true;
          native_lsp.enabled = true;
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

    plugins = {
      web-devicons.enable = true;

      dashboard = {
        enable = true;
        settings = {
          theme = "doom";
          config = {
            header = [
              ""
              ""
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
              ""
            ];

            center = [
              {
                icon = " ";
                desc = "Find File";
                action = "Telescope find_files";
                key = "f";
              }
              {
                icon = " ";
                desc = "Recent Files";
                action = "Telescope oldfiles";
                key = "r";
              }
              {
                icon = " ";
                desc = "Find Text";
                action = "Telescope live_grep";
                key = "g";
              }
              {
                icon = " ";
                desc = "Quit Neovim";
                action = "qa";
                key = "q";
              }
            ];
          };
        };
      };

      indent-blankline = {
        enable = true;
        settings.exclude.filetypes = [
          "dashboard"
          "nvim-tree"
          "help"
          "terminal"
        ];
      };

      neoscroll = {
        enable = true;
        settings = {
          easing = "linear";
          cursor_scrolls_alone = true;
          mappings = [ "<C-u>" "<C-d>" ];
          duration_multiplier = 0.5;
        };
      };

      notify = {
        enable = true;
        settings = {
          background_colour = "#000000";
          render = "compact";
          stages = "fade";
          timeout = 2000;
          max_width = 60;
        };
      };

      telescope = {
        enable = true;

        extensions.fzf-native.enable = true;

        settings.defaults = {
          file_ignore_patterns = [
            "node_modules/"
            ".git/"
            ".expo/"
            "android/.gradle/"
            "android/app/build/"
            "ios/Pods/"
            "dist/"
            "coverage/"
          ];

          layout_config.prompt_position = "top";
          sorting_strategy = "ascending";
        };

        keymaps = {
          "<leader>ff" = {
            action = "find_files";
            options.desc = "Find files";
          };
          "<leader>fg" = {
            action = "live_grep";
            options.desc = "Search project";
          };
          "<leader>fb" = {
            action = "buffers";
            options.desc = "Find buffers";
          };
          "<leader>fr" = {
            action = "oldfiles";
            options.desc = "Recent files";
          };
          "<leader>fh" = {
            action = "help_tags";
            options.desc = "Search help";
          };
        };
      };

      # Oil remains available through "-", but NvimTree owns the default explorer.
      oil = {
        enable = true;
        settings = {
          default_file_explorer = false;
          columns = [ "icon" ];
          delete_to_trash = true;
          skip_confirm_for_simple_edits = false;

          view_options.show_hidden = false;

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

      nvim-tree = {
        enable = true;
        openOnSetup = false;

        settings = {
          hijack_cursor = true;
          sync_root_with_cwd = true;
          respect_buf_cwd = true;

          diagnostics.enable = true;
          git.enable = true;

          update_focused_file = {
            enable = true;
            update_root = false;
          };

          view = {
            width = 32;
            side = "left";
            preserve_window_proportions = true;
          };

          renderer = {
            group_empty = true;
            indent_markers.enable = true;

            icons.show = {
              git = true;
              folder = true;
              file = true;
              folder_arrow = true;
            };
          };

          filters = {
            dotfiles = false;
            custom = [
              "^.git$"
              "node_modules"
              ".cache"
              ".expo"
              "android/.gradle"
              "android/app/build"
              "ios/Pods"
            ];
          };

          actions.open_file = {
            quit_on_open = false;
            resize_window = true;
          };
        };
      };

      ts-autotag.enable = true;
      nvim-autopairs.enable = true;
      comment.enable = true;

      gitsigns = {
        enable = true;
        settings = {
          current_line_blame = true;
          current_line_blame_opts.delay = 500;

          signs = {
            add.text = "┃";
            change.text = "┃";
            delete.text = "_";
            topdelete.text = "‾";
            changedelete.text = "~";
          };
        };
      };

      blink-cmp = {
        enable = true;

        settings = {
          keymap.preset = "enter";

          appearance.nerd_font_variant = "mono";

          completion = {
            documentation = {
              auto_show = true;
              auto_show_delay_ms = 250;
              window.border = "rounded";
            };

            menu.border = "rounded";
          };

          signature = {
            enabled = true;
            window.border = "rounded";
          };

          sources.default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
          ];
        };
      };

      conform-nvim = {
        enable = true;

        settings = {
          notify_on_error = true;

          format_on_save = {
            timeout_ms = 1500;
            lsp_format = "fallback";
          };

          formatters_by_ft = {
            nix = [ "nixfmt" ];

            javascript = [ "prettierd" "prettier" ];
            javascriptreact = [ "prettierd" "prettier" ];
            typescript = [ "prettierd" "prettier" ];
            typescriptreact = [ "prettierd" "prettier" ];

            html = [ "prettierd" "prettier" ];
            css = [ "prettierd" "prettier" ];
            json = [ "prettierd" "prettier" ];
            jsonc = [ "prettierd" "prettier" ];
            yaml = [ "prettierd" "prettier" ];
            markdown = [ "prettierd" "prettier" ];
          };
        };
      };

      which-key = {
        enable = true;
        settings = {
          delay = 300;
          preset = "modern";

          spec = [
            {
              __unkeyed-1 = "<leader>f";
              group = "Find";
            }
            {
              __unkeyed-1 = "<leader>g";
              group = "Git";
            }
            {
              __unkeyed-1 = "<leader>l";
              group = "LSP";
            }
            {
              __unkeyed-1 = "<leader>x";
              group = "Diagnostics";
            }
          ];
        };
      };

      lualine = {
        enable = true;
        settings.options = {
          globalstatus = true;
          component_separators = {
            left = "│";
            right = "│";
          };
        };
      };

      treesitter = {
        enable = true;
        nixGrammars = false;
        package = pkgs.vimPlugins.nvim-treesitter.withAllGrammars;

        settings = {
          highlight.enable = true;
          indent.enable = true;
        };
      };

      treesitter-context = {
        enable = true;
        settings = {
          max_lines = 3;
          multiline_threshold = 2;
        };
      };

      lsp = {
        enable = true;

        servers = {
          ts_ls = {
            enable = true;

            settings = {
              javascript = {
                inlayHints = {
                  includeInlayEnumMemberValueHints = true;
                  includeInlayFunctionLikeReturnTypeHints = true;
                  includeInlayFunctionParameterTypeHints = true;
                  includeInlayParameterNameHints = "literals";
                  includeInlayPropertyDeclarationTypeHints = true;
                  includeInlayVariableTypeHints = false;
                };
              };

              typescript = {
                inlayHints = {
                  includeInlayEnumMemberValueHints = true;
                  includeInlayFunctionLikeReturnTypeHints = true;
                  includeInlayFunctionParameterTypeHints = true;
                  includeInlayParameterNameHints = "literals";
                  includeInlayPropertyDeclarationTypeHints = true;
                  includeInlayVariableTypeHints = false;
                };
              };
            };
          };

          eslint.enable = true;
          jsonls.enable = true;
          yamlls.enable = true;

          html.enable = true;
          cssls.enable = true;

          tailwindcss = {
            enable = true;

            settings = {
              tailwindCSS.experimental.classRegex = [
                "className\\s*=\\s*[\"']([^\"']*)[\"']"
                "className\\s*=\\s*\\{[\"']([^\"']*)[\"']\\}"
              ];
            };
          };

          nixd.enable = true;

          qmlls = {
            enable = true;
            filetypes = [ "qmljs" "qml" ];
          };
        };
      };

      trouble = {
        enable = true;
        settings = {
          focus = true;
          auto_close = true;
        };
      };

      todo-comments = {
        enable = true;
        settings.signs = true;
      };

      harpoon = {
        enable = true;
        enableTelescope = true;
      };
    };

    diagnostic.settings = {
      virtual_text = {
        spacing = 4;
        prefix = "●";
      };
      severity_sort = true;
      float = {
        border = "rounded";
        source = "if_many";
      };
      signs = true;
      underline = true;
      update_in_insert = false;
    };

    extraConfigLua = ''
      local signs = {
        Error = "󰅚 ",
        Warn = "󰀪 ",
        Hint = "󰌶 ",
        Info = "󰋽 ",
      }

      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, {
          text = icon,
          texthl = hl,
          numhl = "",
        })
      end

      -- Open NvimTree only when Neovim starts with a directory.
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function(data)
          if vim.fn.isdirectory(data.file) ~= 1 then
            return
          end

          vim.cmd.cd(data.file)
          require("nvim-tree.api").tree.open()
        end,
      })

      -- Cord needs an explicit setup call when loaded through extraPlugins.
      local cord_ok, cord = pcall(require, "cord")
      if cord_ok then
        cord.setup({})
      end
    '';

    keymaps = [
      # Harpoon
      {
        mode = "n";
        key = "<leader>a";
        action.__raw = "function() require('harpoon'):list():add() end";
        options.desc = "Harpoon add file";
      }
      {
        mode = "n";
        key = "<leader>h";
        action.__raw = "function() local harpoon = require('harpoon'); harpoon.ui:toggle_quick_menu(harpoon:list()) end";
        options.desc = "Harpoon menu";
      }
      {
        mode = "n";
        key = "<M-1>";
        action.__raw = "function() require('harpoon'):list():select(1) end";
        options.desc = "Harpoon file 1";
      }
      {
        mode = "n";
        key = "<M-2>";
        action.__raw = "function() require('harpoon'):list():select(2) end";
        options.desc = "Harpoon file 2";
      }
      {
        mode = "n";
        key = "<M-3>";
        action.__raw = "function() require('harpoon'):list():select(3) end";
        options.desc = "Harpoon file 3";
      }
      {
        mode = "n";
        key = "<M-4>";
        action.__raw = "function() require('harpoon'):list():select(4) end";
        options.desc = "Harpoon file 4";
      }
      {
        mode = "n";
        key = "<S-Tab>";
        action.__raw = "function() require('harpoon'):list():next() end";
        options.desc = "Harpoon next";
      }
      {
        mode = "n";
        key = "<Tab>";
        action.__raw = "function() require('harpoon'):list():prev() end";
        options.desc = "Harpoon previous";
      }

      # General
      {
        mode = "n";
        key = "<leader>w";
        action = "<cmd>w<CR>";
        options.desc = "Save";
      }
      {
        mode = "n";
        key = "<leader>q";
        action = "<cmd>cclose<CR>";
        options = {
          silent = true;
          desc = "Close quickfix";
        };
      }
      {
        mode = "n";
        key = "<leader>o";
        action = "<cmd>update<CR><cmd>source %<CR>";
        options.desc = "Update and source";
      }
      {
        mode = "v";
        key = "<C-j>";
        action = ":m '>+1<CR>gv=gv";
        options = {
          silent = true;
          desc = "Move line down";
        };
      }
      {
        mode = "v";
        key = "<C-k>";
        action = ":m '<-2<CR>gv=gv";
        options = {
          silent = true;
          desc = "Move line up";
        };
      }

      # Explorer
      {
        mode = "n";
        key = "-";
        action = "<cmd>Oil<CR>";
        options.desc = "Open parent directory";
      }
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>NvimTreeToggle<CR>";
        options.desc = "Toggle file tree";
      }
      {
        mode = "n";
        key = "<leader>ef";
        action = "<cmd>NvimTreeFindFile<CR>";
        options.desc = "Find current file in tree";
      }

      # Formatting
      {
        mode = [ "n" "v" ];
        key = "<leader>lf";
        action.__raw = ''
          function()
            require("conform").format({
              async = true,
              lsp_format = "fallback",
            })
          end
        '';
        options.desc = "Format file or selection";
      }

      # LSP
      {
        mode = "n";
        key = "gd";
        action.__raw = "vim.lsp.buf.definition";
        options.desc = "Go to definition";
      }
      {
        mode = "n";
        key = "gD";
        action.__raw = "vim.lsp.buf.declaration";
        options.desc = "Go to declaration";
      }
      {
        mode = "n";
        key = "gr";
        action.__raw = "vim.lsp.buf.references";
        options.desc = "Find references";
      }
      {
        mode = "n";
        key = "gi";
        action.__raw = "vim.lsp.buf.implementation";
        options.desc = "Go to implementation";
      }
      {
        mode = "n";
        key = "K";
        action.__raw = "vim.lsp.buf.hover";
        options.desc = "Hover documentation";
      }
      {
        mode = "n";
        key = "<leader>lr";
        action.__raw = "vim.lsp.buf.rename";
        options.desc = "Rename symbol";
      }
      {
        mode = [ "n" "v" ];
        key = "<leader>la";
        action.__raw = "vim.lsp.buf.code_action";
        options.desc = "Code action";
      }
      {
        mode = "n";
        key = "<leader>li";
        action = "<cmd>LspInfo<CR>";
        options.desc = "LSP info";
      }

      # Diagnostics
      {
        mode = "n";
        key = "[d";
        action.__raw = "vim.diagnostic.goto_prev";
        options.desc = "Previous diagnostic";
      }
      {
        mode = "n";
        key = "]d";
        action.__raw = "vim.diagnostic.goto_next";
        options.desc = "Next diagnostic";
      }
      {
        mode = "n";
        key = "<leader>d";
        action.__raw = "vim.diagnostic.open_float";
        options.desc = "Line diagnostic";
      }
      {
        mode = "n";
        key = "<leader>xx";
        action = "<cmd>Trouble diagnostics toggle<CR>";
        options.desc = "Workspace diagnostics";
      }
      {
        mode = "n";
        key = "<leader>xX";
        action = "<cmd>Trouble diagnostics toggle filter.buf=0<CR>";
        options.desc = "Buffer diagnostics";
      }

      # Git
      {
        mode = "n";
        key = "]h";
        action = "<cmd>Gitsigns next_hunk<CR>";
        options.desc = "Next Git hunk";
      }
      {
        mode = "n";
        key = "[h";
        action = "<cmd>Gitsigns prev_hunk<CR>";
        options.desc = "Previous Git hunk";
      }
      {
        mode = "n";
        key = "<leader>gp";
        action = "<cmd>Gitsigns preview_hunk<CR>";
        options.desc = "Preview Git hunk";
      }

      # TODOs
      {
        mode = "n";
        key = "<leader>ft";
        action = "<cmd>TodoTelescope<CR>";
        options.desc = "Find TODO comments";
      }

      # Notifications
      {
        mode = "n";
        key = "<leader>nd";
        action = "<cmd>lua require('notify').dismiss({ silent = true, pending = true })<CR>";
        options.desc = "Dismiss notifications";
      }

      # Existing VimTeX mapping
      {
        mode = "n";
        key = "<leader>ll";
        action = "\\lv";
        options = {
          remap = true;
          desc = "VimTeX preview";
        };
      }
    ];
  };
}

