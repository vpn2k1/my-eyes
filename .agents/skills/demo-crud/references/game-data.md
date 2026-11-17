# CRUD cho dữ liệu lưu của game

Áp dụng khi spec có hồ sơ người chơi, ô lưu, kho đồ, preset hoặc tiến trình có thể lưu. Xác định hệ thống có quyền ghi, hệ thống chỉ đọc và vòng đời dữ liệu giữa các phiên. Ánh xạ thao tác theo trải nghiệm game. Ví dụ, tạo ô lưu mới, tải lại, ghi đè hoặc xóa khi spec cho phép.

- Dùng ID ổn định và phiên bản định dạng lưu. Khi đổi schema, đọc được dữ liệu từ các phiên bản còn hỗ trợ, kiểm tra dữ liệu cũ trước khi chuyển đổi và chuẩn bị cách phục hồi phù hợp. Nếu ghi tệp, dùng ghi tạm rồi thay thế nguyên tử khi nền tảng hỗ trợ.
- Với kho đồ và tiến trình, xác định cách xử lý giới hạn, quan hệ giữa vật phẩm và hồ sơ, lần ghi bị gián đoạn và yêu cầu lặp lại. Khi thao tác có thể cấp thưởng, kiểm tra ghi lặp không nhân đôi phần thưởng.
- Chạy kiểm tra lưu → đóng/mở → tải lại trên runtime phù hợp. Theo spec, thử save cũ, dữ liệu thiếu hoặc hỏng, lỗi khi ghi, xóa đúng ô lưu và dữ liệu không liên quan vẫn đọc được.
- Với demo có dữ liệu game lưu qua nhiều phiên, ghi trong `CODEX_HANDOFF.md` hoặc tài liệu bàn giao hiện có vị trí và phiên bản save, cách chạy thử migration/lưu lại, kết quả đã kiểm tra và phần còn mở. Khi lỗi dữ liệu khó tái hiện, ghi bước tái hiện, dữ liệu mẫu và kết quả trước khi thử cách sửa tiếp theo.
