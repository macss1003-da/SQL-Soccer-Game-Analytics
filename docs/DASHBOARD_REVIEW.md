# Kiểm tra dashboard trước khi hoàn thiện portfolio

Checklist dưới đây dành cho lần kiểm tra trực tiếp trên máy của bạn. Các mục chưa được đánh dấu thay cho bạn.

## HTML

- [ ] Mở `docs/index.html` bằng trình duyệt.
- [ ] Khi chưa lọc: 25.979 trận, 70.287 bàn, 299 đội; bàn/trận khoảng 2,71; chủ nhà thắng khoảng 45,9%.
- [ ] Chọn Premier League + 2015/2016: 380 trận, 1.026 bàn thắng.
- [ ] Kiểm tra 5 trang, bộ lọc và tải CSV.
- [ ] Sau khi bật GitHub Pages, mở URL công khai bằng cửa sổ ẩn danh và thử bộ lọc.

## Power BI Desktop

- [ ] Ghi phiên bản Power BI Desktop đã dùng: __________.
- [ ] Mở `powerbi/SoccerAnalytics.pbip`, nạp dữ liệu bằng Refresh thành công.
- [ ] KPI tổng quan khớp số liệu trên; 5 trang không có thông báo lỗi visual.
- [ ] Bộ lọc giải/mùa/đội hoạt động; bỏ lọc trả về tổng ban đầu.
- [ ] Trang 02, Leicester City 2015/2016: 81 điểm, 38 trận, PPG khoảng 2,132; hạng PPG = 1.
- [ ] Trang 02, Arsenal 2015/2016: hạng PPG vẫn = 2 khi chỉ chọn Arsenal.
- [ ] Trang 03, Manchester United 2010/2011: 55 điểm nhà và 25 điểm khách, mỗi bên 19 trận.
- [ ] Trang 04, Leicester City 2015/2016: tăng 40 điểm, tăng khoảng 1,053 PPG.
- [ ] Trang 04, mùa 2008/2009 không tạo cặp so sánh giả với mùa trước.
- [ ] Trang 05: 22 kiểm tra đạt, 0 kiểm tra không đạt, 38 bảng SQL.
- [ ] Các đội trùng tên có mã API khác nhau vẫn có thể phân biệt ở slicer.
- [ ] Đã chụp ảnh thực tế vào `assets/powerbi/`.

Ngày kiểm tra: __________. Người kiểm tra: __________.

Sau khi kiểm thử thực tế thành công, cập nhật trạng thái trong README và ghi rõ phiên bản Desktop, ngày kiểm thử cùng hạn chế còn lại. Báo cáo `powerbi/docs/validation.json` là bằng chứng kiểm tra cấu trúc/dữ liệu khi đóng gói; giữ nguyên nội dung lịch sử của báo cáo đó.
