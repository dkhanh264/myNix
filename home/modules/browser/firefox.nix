{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    profiles.dk = {
      id = 0;
      name = "dk";
      isDefault = true;
      
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "layers.acceleration.force-enabled" = true;
        "gfx.webrender.all" = true;
      };

      userChrome = ''
        /* Import bảng màu động hệ thống từ Pywal */
        @import url("file:///home/dk/.cache/wal/colors.css");

        /* Cấu hình nền tổng thể của cửa sổ Firefox */
        #main-window, body {
            background-color: rgba(0, 0, 0, 0.1) !important;
        }

        /* Làm trong suốt phần vỏ bọc bên trên */
        #navigator-toolbox, #nav-bar, #TabsToolbar, #PersonalToolbar {
            background-color: transparent !important;
            border: none !important;
        }

        /* Khối hiển thị chính: Đẩy margin đều các góc để tạo khoảng trống lộ phần nền Blur */
        #browser {
            margin: 2vh 2vh 2vh 0vh !important;
            background-color: transparent !important;
        }

        #tabbrowser-tabpanels {
            background: none !important;
        }

        /* Hộp bọc nội dung trang web chính (ví dụ: khu vực hiển thị YouTube) */
        .browserContainer browser {
            border-radius: 12px !important;
            margin: 0vh !important;
            /* QUAN TRỌNG: Đặt màu tối mờ đục cho trang web để chữ không bị nhìn xuyên thấu gây nhức mắt */
            background-color: #1a1b26 !important; 
        }

        /* Áp dụng bo góc toàn diện cho các thành phần UI theo mẫu của bạn */
        * {
            border-radius: 10px !important;
        }

        .sidebar-button {
            border-radius: 0 !important;
        }

        #sidebar, notification-message {
            background-color: transparent !important;
            background: none !important;
            border-radius: 20px !important;
        }

        /* Điểm xuyết: Đồng bộ màu sắc thanh Tab đang chọn theo hình nền Pywal */
        .tab-background[selected] {
            background-color: var(--color4) !important;
            background-image: none !important;
        }
        
        .tab-label[selected] {
            color: var(--background) !important;
        }
      '';
    };
  };
}
