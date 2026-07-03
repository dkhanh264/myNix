{ config, pkgs, ... }: {
  programs.mpv = {
    enable = true;
    
    config = {
      vo = "gpu";
      profile = "gpu-hq";
      gpu-context = "wayland";
      
      # Tự động kích hoạt giải mã phần cứng (Hardware Acceleration) an toàn dựa trên driver card đồ họa của bạn
      hwdec = "auto-safe"; 

      keep-open = "yes";           # Giữ cửa sổ mở sau khi video kết thúc thay vì tự tắt
      save-position-on-quit = true; # Tự động nhớ mốc thời gian đang xem dở khi tắt ứng dụng
      cursor-autohide = 1000;       # Tự động ẩn con trỏ chuột sau 1 giây nếu không di chuyển

      # Cấu hình ưu tiên ngôn ngữ mặc định cho Phụ đề & Âm thanh
      slang = "eng,vie";         
      alang = "eng,jpn,vie";       
    };

    scripts = with pkgs.mpvScripts; [
      # Bắt buộc phải có để tích hợp cụm phím Media và đồng bộ trạng thái bài hát/video lên Waybar
      mpris      
      
      # Tiện ích mở rộng cung cấp thanh điều khiển (UI) dạng nổi (floating) cực kỳ hiện đại, mượt mà
      uosc       
      
      # Tự động tạo ảnh thu nhỏ (thumbnail) khi bạn di chuột qua thanh tua video (kết hợp hoàn hảo với uosc)
      thumbfast  
    ];
  };
}
