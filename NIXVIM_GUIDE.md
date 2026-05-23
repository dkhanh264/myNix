# Hướng dẫn sử dụng NixVim

Tài liệu này dành cho cấu hình NixVim trong repo này (`home/modules/dev/neovim.nix`), tập trung cho người mới.

## 1) Mở và thoát NixVim

- Mở editor:
  ```bash
  nvim
  ```
- `Space + w`: lưu file
- `Space + q`: đóng cửa sổ hiện tại
- `jk` (ở Insert mode): quay lại Normal mode

> Trong cấu hình này, **leader key = Space**.

## 2) Điều hướng file và tìm kiếm

- `Space + e`: bật/tắt cây thư mục (NvimTree)
- `Space + ff`: tìm file theo tên
- `Space + fg`: tìm text trong project
- `Space + fr`: mở file gần đây
- `Space + fb`: chuyển nhanh giữa các buffer
- `Space + fh`: tìm help tags
- `Space + fk`: tra cứu keymap hiện có

## 3) Làm việc với cửa sổ và buffer

- `Ctrl + h/j/k/l`: chuyển giữa các cửa sổ
- `Shift + h/l`: buffer trước/sau
- `Space + bd`: đóng buffer hiện tại

## 4) LSP và code intelligence

- `gd`: đi tới definition
- `gD`: đi tới declaration
- `gr`: tìm references
- `gi`: đi tới implementation
- `K`: xem tài liệu nhanh (hover)
- `Space + rn`: đổi tên symbol
- `Space + ca`: code action
- `Space + d`: xem lỗi tại vị trí con trỏ
- `[d` / `]d`: chuyển qua lỗi trước/sau
- `Space + f`: format file

## 5) Tìm kiếm, highlight, và thao tác nhanh

- `Esc`: bỏ highlight sau khi search
- `Space + nh`: bỏ highlight sau khi search
- Trong Visual mode:
  - `<` / `>`: giảm/tăng indent và giữ vùng chọn
  - `J` / `K`: di chuyển block code xuống/lên

## 6) Tự động hỗ trợ đã bật sẵn

- Autocomplete (`nvim-cmp`)
- Snippets (`LuaSnip`)
- Auto pairs (tự đóng ngoặc/dấu nháy)
- Comment nhanh (`gcc`, `gc`)
- Git signs trong gutter
- Treesitter highlight
- Dashboard khi mở `nvim` không có file
- Which-key gợi ý phím khi bấm `Space`

## 7) Mẹo cho người mới

1. Bắt đầu bằng `Space + e` để mở cây thư mục.
2. Dùng `Space + ff` để mở file nhanh thay vì tìm thủ công.
3. Khi quên phím tắt, bấm `Space` và chờ popup gợi ý.
4. Nếu thấy nhiều lỗi, dùng `[d` và `]d` để duyệt từng lỗi.
5. Trước khi thoát, nhấn `Space + w` để lưu.
