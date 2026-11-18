# Soccer Game Analytics — Power BI

Báo cáo gồm 5 trang có thể chỉnh sửa trong Power BI Desktop, chuyển từ dashboard HTML Soccer Analytics. Bao gồm 38 bảng kết quả SQL gốc, mô hình quan hệ, 44 measure DAX và biểu đồ gốc của Power BI.

## Mở lần đầu

1. Giải nén **toàn bộ** `Soccer_Analytics_PowerBI.zip` vào một thư mục ngắn, ví dụ `C:\SoccerBI`. Không mở trực tiếp trong ZIP và không di chuyển riêng file `.pbip`.
2. Dùng Power BI Desktop bản thường dành cho Windows, cập nhật gần đây. Nếu cần, vào **File → Options and settings → Options → Preview features**, bật **Power BI Project (.pbip) save option** và **Store reports using enhanced metadata format (PBIR)**, rồi khởi động lại. Tên tùy chọn có thể khác theo phiên bản; nếu tính năng đã được tích hợp thì không cần bật lại.
3. Mở **SoccerAnalytics.pbip**. Có thể dùng **File → Open → Browse** trong Power BI Desktop. Một cách khác là mở `SoccerAnalytics.Report/definition.pbir`.
4. Chọn **Home → Refresh** và chờ nạp dữ liệu. Lần đầu các biểu đồ có thể trống trước khi refresh, vì gói không chứa bộ nhớ đệm dữ liệu của Desktop.
5. Kiểm tra trang Tổng quan ở trạng thái chưa lọc: **25.979 trận**, **70.287 bàn thắng**, **2,71 bàn/trận**, **45,9% chủ nhà thắng**, **299 đội**.
6. Để có một file `.pbix`, chọn **File → Save As**, chọn loại **Power BI files (*.pbix)**, rồi lưu. File `.pbix` được tạo bằng Power BI Desktop sau khi nạp dữ liệu; gói tải xuống hiện tại là `.pbip`.

Dữ liệu đã nhúng trong Power Query: không phải sửa đường dẫn, không cần file SQLite, trình kết nối SQLite hay thông tin đăng nhập dữ liệu. Refresh đọc lại bản chụp kết quả có sẵn; **không tự chạy lại SQL hoặc tải dữ liệu mới từ Kaggle**.

## Các trang báo cáo

| Trang | Nội dung |
|---|---|
| 01 · Tổng quan giải đấu | KPI, mức ghi bàn theo giải, cơ cấu kết quả, xu hướng mùa và bảng tổng hợp |
| 02 · Thành tích đội bóng | PPG theo bộ lọc, top 10 đội, xu hướng theo mùa, 1.481 dòng đội–mùa |
| 03 · Sân nhà và sân khách | PPG nhà/khách, chênh lệch dương và âm, bảng chi tiết |
| 04 · Thay đổi qua mùa | 1.110 cặp mùa liên tiếp, cải thiện và suy giảm PPG |
| 05 · Dữ liệu và kiểm tra | 22 phép kiểm tra SQL, 4 lưu ý phạm vi, danh mục 38 bảng kết quả |

Các slicer giải, mùa và nhóm so sánh được đồng bộ giữa trang 01–04. Slicer đội chỉ xuất hiện ở trang 02–04. Chọn nhóm “5 giải có cấu trúc ổn định” để giới hạn vào Anh, Pháp, Đức, Hà Lan và Tây Ban Nha: toàn bộ mẫu này có **14.016 trận**. Dùng biểu tượng xóa lựa chọn trên slicer để bỏ lọc.

Trang 05 trình bày kiểm tra cho toàn bộ nguồn. Để xem tất cả dòng của một kết quả SQL, mở **Table view** và chọn bảng có tiền tố **SQL_**. Bảng kiểm tra rỗng vẫn giữ cấu trúc cột; đây là kết quả hợp lệ của truy vấn không tìm thấy trường hợp tương ứng.

## Cách hiểu chỉ số

- Bàn/trận = tổng bàn thắng ÷ tổng số trận. Tỷ lệ chủ nhà thắng = tổng trận chủ nhà thắng ÷ tổng số trận. Không lấy trung bình đơn giản của tỷ lệ từng giải–mùa.
- PPG = tổng điểm ÷ tổng lượt đội thi đấu; điểm tính theo thắng 3, hòa 1, thua 0. Khi chọn nhiều mùa, biểu đồ top đội so sánh PPG gộp có trọng số của các mùa được chọn.
- `ppg_rank` trong bảng là DENSE_RANK đã tính trong từng giải–mùa, không phải bảng xếp hạng chính thức. Lọc một đội không làm đội đó tự trở thành hạng 1. Chưa áp dụng luật phụ hoặc trừ điểm hành chính.
- Một số tên đội có nhiều `team_api_id`: Royal Excel Mouscron, Polonia Bytom và Widzew Łódź. Nhãn báo cáo thêm mã trong ngoặc vuông để giữ nguyên định danh nguồn; không tự hợp nhất các mã này. 38 bảng SQL gốc không bị đổi tên hoặc sửa giá trị.
- Ở trang 04, mùa lọc là **mùa sau**. Chỉ so sánh cùng đội, cùng giải, hai mùa liên tiếp. Không có mùa trước → không có cặp so sánh. Với mùa 2008/09, trang này trống là đúng. “Δ PPG trung bình” là trung bình cộng của các chênh lệch theo cặp.
- Belgium 2013/14 chỉ có 12 trận/4 đội; Italy 2011/12, Italy 2014/15 và Switzerland 2011/12 có lịch quan sát không đều. Các giải khác cũng cần được diễn giải theo thể thức và giai đoạn quan sát. Nhóm 5 giải không phải sự xác nhận độc lập rằng dữ liệu chính thức đầy đủ.
- Báo cáo mô tả dữ liệu, không chứng minh quan hệ nhân quả. Chưa bổ sung phân tích cầu thủ, thuộc tính FIFA, sự kiện XML hoặc tỷ lệ cược ngoài phạm vi kết quả SQL hiện có.

## Mô hình và tệp

Mô hình gồm ba bảng phân tích (`FactLeagueSeason`, `FactTeamSeason`, `FactSeasonChange`), ba bảng chiều dùng chung (`DimLeague`, `DimSeason`, `DimTeam`) với quan hệ một–nhiều và lọc một chiều. `DimOutcome` là nhãn kết quả rời, dùng với measure SWITCH. Bảng kiểm tra, danh mục, thông tin lần chạy và 38 bảng `SQL_` không nối vào bảng phân tích, nhằm tránh nhân đôi kết quả.

| Tệp/thư mục | Công dụng |
|---|---|
| `SoccerAnalytics.pbip` | Điểm mở dự án trong Power BI Desktop |
| `SoccerAnalytics.Report` | Các trang, biểu đồ, slicer và theme PBIR |
| `SoccerAnalytics.SemanticModel` | Mô hình TMSL, Power Query nhúng dữ liệu, DAX và quan hệ |
| `data/all_results.json` | 38 kết quả SQL nguyên gốc |
| `data/dashboard_snapshot.json` | Bản chụp để tái tạo dự án |
| `data/ALL_SOCCER_ANALYSIS.sql` | Toàn bộ câu lệnh SQL từ dashboard |
| `data/source_metadata.json` | Dấu vân tay SHA-256 và thông tin đối chiếu nguồn |
| `docs/measures.json` | Danh sách và công thức 44 measure |
| `docs/validation.json` | Phạm vi kiểm tra và kết quả kiểm tra bộ tệp |

Đã kiểm tra schema JSON công khai của Microsoft, tên trường và measure tham chiếu trong các biểu đồ, quan hệ và tính duy nhất khóa, dữ liệu nhúng, các tổng số và một số trường hợp đối chiếu. **Chưa mở hoặc chạy Refresh trong Power BI Desktop; chưa kiểm chứng trực tiếp việc thực thi DAX/Power Query và hiển thị biểu đồ trong ứng dụng.** Schema hợp lệ không thay thế kiểm thử Desktop. Nếu gặp lỗi, giữ nguyên thư mục và gửi ảnh thông báo lỗi cùng phiên bản Desktop để xác định chính xác tệp cần sửa.

## Dùng trong portfolio GitHub

Đưa toàn bộ cấu trúc dự án lên repository để người xem có thể mở báo cáo và đọc DAX/SQL. `.gitignore` đã loại bộ nhớ đệm và cài đặt máy cá nhân. Chưa đăng hoặc sửa repository GitHub trong lần chuyển đổi này.

Không cần chạy Python để sử dụng báo cáo. Nếu muốn tái tạo bộ tệp từ snapshot, chạy lệnh sau trong thư mục dự án bằng Python 3:

```bash
python docs/build_powerbi.py --input data/dashboard_snapshot.json --output rebuilt
```

## Nguồn và tài liệu định dạng

- Dữ liệu: [European Soccer Database — Hugo Mathien, Kaggle](https://www.kaggle.com/datasets/hugomathien/soccer). Nội dung, phạm vi và quyền sử dụng dữ liệu theo nguồn gốc; gói không chứa toàn bộ SQLite.
- [Microsoft: Power BI Desktop projects](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-overview)
- [Microsoft: Report folder và PBIR](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-report)
- [Microsoft: Semantic model folder](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-dataset)
- Schema được lấy ngày 25/09/2026 từ `developer.microsoft.com` và kho `microsoft/powerbi-desktop-samples`.
