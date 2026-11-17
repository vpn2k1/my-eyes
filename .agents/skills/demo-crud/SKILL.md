---
name: demo-crud
description: "Thiết kế, triển khai, review và test chức năng tạo, đọc, sửa, xóa dữ liệu theo spec trong dự án demo. Dùng cho danh sách, form, API, quyền truy cập và dữ liệu game như hồ sơ, save slot, kho đồ hoặc tiến trình."
---

# CRUD cho dự án demo

Đọc spec và quy ước sẵn có của dự án. Xác định thực thể, nơi lưu dữ liệu, người dùng và thao tác nằm trong phạm vi. Dùng stack hiện có hoặc đã chọn. Với dữ liệu game có lưu trạng thái, đọc thêm [dữ liệu game](references/game-data.md). Xem [nguồn tham khảo](references/sources.md) để biết quy trình dựa trên những phần nào của hai repo.

## Thực hiện từng thực thể

| Bước | Kết quả |
| --- | --- |
| Spec | Ghi ID thực thể, trường bắt buộc, kiểu, giá trị mặc định, giới hạn, quan hệ và vòng đời. Tạo mã tiêu chí cho mỗi hành vi tạo, đọc danh sách/chi tiết, sửa, xóa hoặc lưu trữ thuộc phạm vi. Ghi ai có quyền thực hiện và điều gì xảy ra với dữ liệu liên quan. Đặc tả tìm kiếm, lọc, sắp xếp và phân trang khi cần. |
| Plan | Liệt kê schema/lưu trữ, quy tắc nghiệp vụ, API hoặc điểm vào của ứng dụng, màn hình và ca test cho từng tiêu chí. Làm phần dữ liệu cha trước phần phụ thuộc khi có quan hệ. Xác định dữ liệu cũ bị ảnh hưởng và cách chuyển đổi. |
| Code | Hoàn thành một luồng từ thao tác thực tế đến dữ liệu và kết quả hiển thị. Kiểm tra đầu vào tại ranh giới xử lý có thẩm quyền, dùng chung hợp đồng dữ liệu giữa UI và API, cập nhật UI sau khi ghi thành công. Dùng dữ liệu mẫu và chọn lưu cục bộ hoặc backend theo spec. |
| Review | Đối chiếu diff với spec và tiêu chí. Kiểm tra xác thực, phạm vi danh sách, quyền trên từng bản ghi và trường hợp ghi/xóa ảnh hưởng nhiều dữ liệu nếu có. Với app có nhiều tài khoản, áp dụng quyền ở lớp xử lý dữ liệu; trạng thái nút trên UI chỉ phản ánh quyền. Xử lý lỗi giữa chừng để dữ liệu và giao diện giữ trạng thái nhất quán. |
| Test | Ánh xạ từng tiêu chí đến ca test. Chạy luồng qua điểm vào thật: tạo rồi đọc lại, sửa rồi kiểm tra kết quả, xóa/lưu trữ rồi kiểm tra danh sách và dữ liệu liên quan. Theo spec, thử dữ liệu rỗng hoặc sai, ID không tồn tại, trùng lặp, quyền của hai tài khoản và lưu qua lần mở lại. Chạy test UI/API và kiểm tra build, kiểu dữ liệu, lint theo stack nếu có. Ghi lệnh, kết quả và ca chưa chạy. |

## Điều chỉnh theo stack và phạm vi

- Nếu stack đã chọn là Go + React, dùng quy ước hiện có của dự án cho route, nghiệp vụ, truy vấn, form và đồng bộ bộ nhớ đệm. Có thể dùng Playwright cho luồng qua trình duyệt khi stack và môi trường phù hợp. Với stack khác, chọn công cụ tương đương.
- Chỉ thêm tài khoản, đăng nhập, vai trò, chia sẻ hoặc triển khai khi spec cần. Nếu cần phân quyền, ghi quyền theo vai trò, chủ sở hữu, quan hệ cha/con hoặc quyền được chia sẻ, rồi kiểm thử cả trường hợp được phép và bị từ chối.
- Khi spec đổi, cập nhật mã tiêu chí và plan. Đồng bộ schema hoặc migration, hành vi trong code, fixture và test theo ảnh hưởng thực tế. Review và chạy lại test của chức năng cùng phần phụ thuộc, ghi bằng chứng vào hồ sơ kiểm chứng của dự án.
- Khi bàn giao, ghi cách chạy app, khởi tạo dữ liệu và chạy test trong README. Trỏ từ tiêu chí tới mã triển khai và kết quả test, ghi rõ dữ liệu hoặc quyền nào được mô phỏng.
