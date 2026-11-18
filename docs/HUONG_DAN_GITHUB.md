# Đưa SQL Soccer Game Analytics lên GitHub từng bước

Mục tiêu là một repository thể hiện đủ câu hỏi phân tích → kiểm tra dữ liệu → SQL → kết quả → biểu đồ → giải thích và giới hạn. Bộ thư mục đi kèm đã gom SQL, kết quả, HTML và Power BI; chưa tạo hoặc đăng repository trên tài khoản GitHub của bạn.

## 1. Chuẩn bị trên máy

Tải và giải nén gói repository vào thư mục Downloads hoặc thư mục tạm. Bên trong có một thư mục `sql-soccer-game-analytics`. Giữ nguyên các tên tệp và thư mục, vì các script và liên kết trong README dùng các đường dẫn này.

| Vị trí | Vai trò |
|---|---|
| `README.md` | Trang giới thiệu bằng tiếng Anh, câu hỏi, phương pháp, phát hiện và hướng dẫn chạy lại |
| `sql/` | 14 file SQL, thứ tự 00 đến 13 |
| `ALL_SOCCER_ANALYSIS.sql` | Toàn bộ SQL trong một file để dùng với DB Browser for SQLite |
| `scripts/` | Chạy SQL, đối chiếu độc lập và tạo lại biểu đồ |
| `outputs/` | CSV, JSON, Excel và bằng chứng kiểm tra |
| `assets/` | 6 biểu đồ PNG/SVG đã tạo; thư mục `powerbi/` dành cho ảnh chụp thực tế sau này |
| `docs/` | Báo cáo, từ điển dữ liệu, lộ trình và `index.html` cho GitHub Pages |
| `powerbi/` | Toàn bộ dự án Power BI, giữ nguyên thư mục Report/SemanticModel đi kèm |
| `data/README.md` | Nguồn dữ liệu, vị trí đặt SQLite trên máy và SHA-256 |

File SQLite gốc có 313.090.048 byte, khoảng 298,6 MiB. Giữ nó trên máy và đặt tại `data/database.sqlite` khi cần chạy lại SQL. `.gitignore` đã loại database, bộ nhớ đệm Power BI và các bản xuất nhị phân. GitHub giới hạn file thông thường ở 100 MiB; dữ liệu nguồn được dẫn về Kaggle trong `data/README.md`.

## 2. Tạo repository bằng GitHub Desktop

Cài [GitHub Desktop](https://desktop.github.com/) và đăng nhập tài khoản GitHub. Tạo một repository mới trên máy với các thông tin:

| Trường | Giá trị đề xuất |
|---|---|
| Name | `sql-soccer-game-analytics` |
| Description | `SQLite analysis of 25,979 European football matches with interactive HTML and Power BI reports.` |
| Local path | `C:\Portfolio` hoặc một thư mục bạn muốn dùng lâu dài |
| Initialize with README | Bỏ chọn, vì bộ dự án đã có README |
| Git ignore | None; dùng file đã chuẩn bị trong gói |
| License | Có thể để None ở lần tạo này |

Ứng dụng tạo thư mục `C:\Portfolio\sql-soccer-game-analytics`. Sao chép **nội dung bên trong** thư mục đã giải nén vào đây. Tại thư mục gốc phải nhìn thấy ngay `README.md`, `sql`, `outputs`, `docs`, `powerbi`; tránh tạo thêm một tầng thư mục cùng tên.

Nếu bạn đã có một repository cùng tên, clone repository đó về máy và tích hợp các tệp vào bản clone, giữ các tài liệu riêng đã có; không cần tạo thêm repository trùng tên.

## 3. Kiểm tra trước khi đăng

Mở `docs/index.html` và thử bộ lọc. Mở `powerbi/SoccerAnalytics.pbip`, chọn Refresh và làm theo [checklist](DASHBOARD_REVIEW.md). Power BI đã được kiểm tra cấu trúc/dữ liệu, nhưng chưa chạy trực tiếp trong Desktop ở môi trường tạo gói, nên README đang ghi rõ trạng thái này.

Ở trạng thái không lọc, đối chiếu 25.979 trận, 70.287 bàn và 299 đội. Với Premier League 2015/16, đối chiếu 380 trận, 1.026 bàn; Leicester có 81 điểm trong 38 trận.

Trong GitHub Desktop, xem danh sách thay đổi. Các file SQL, README, CSV/JSON, HTML, hình ảnh và dự án Power BI phải xuất hiện; database và cache Power BI không nằm trong commit. Thư mục `powerbi/data/` chứa JSON kết quả đã nhúng và được giữ lại; thư mục `data/` gốc chỉ đưa README lên GitHub.

## 4. Hoàn thiện README theo đúng phần việc của bạn

README hiện đã có số liệu, liên kết SQL–kết quả, biểu đồ và các giới hạn. Trước khi dùng để ứng tuyển:

- Thêm tên tác giả và liên kết liên hệ mà bạn muốn công khai.
- Viết ngắn mục “What I learned” bằng lời của bạn: cách JOIN theo API ID, chuyển một trận thành hai dòng đội bằng UNION ALL, tính PPG, dùng DENSE_RANK và kiểm tra mùa liên tiếp bằng LAG.
- Đọc kỹ 3–5 phát hiện để giải thích được số liệu và mẫu so sánh trong phỏng vấn.
- Sau khi kiểm thử Power BI thực tế, thêm ảnh chụp và cập nhật trạng thái kiểm thử.
- Giữ phần hạn chế về Belgium 2013/14, lịch không đều, thứ hạng PPG khác thứ hạng chính thức và phạm vi phân tích hiện tại.

Nguồn dữ liệu và nguồn mã là hai nội dung khác nhau: luôn giữ ghi nguồn Kaggle. Gói này không tự thêm một giấy phép mới cho dữ liệu.

## 5. Commit và đăng lên GitHub

Trong GitHub Desktop, ghi nội dung commit, ví dụ `Add soccer SQL analysis and dashboards`, rồi commit vào nhánh hiện tại (thường là `main`). Commit là mốc lưu thay đổi trên máy.

Tiếp theo, dùng nút xuất bản repository để đưa dự án lên tài khoản cá nhân. Chọn chế độ Public khi bạn muốn dùng làm portfolio công khai; bỏ tùy chọn giữ mã riêng tư. Sau khi đăng, mở repository trên GitHub và kiểm tra README, biểu đồ cùng liên kết kết quả.

Những lần sửa tiếp theo: sửa file → lưu → xem thay đổi → commit với mô tả đúng việc đã làm → push. Không cần tạo lại repository. Ví dụ commit tiếp theo sau khi kiểm thử thực tế: `Add verified Power BI screenshots and test notes`.

## 6. Bật dashboard tương tác bằng GitHub Pages

Trong repository trên GitHub, vào **Settings → Pages**. Chọn xuất bản từ nhánh, dùng nhánh `main` (hoặc nhánh mặc định thực tế của repository) và thư mục `/docs`, rồi lưu. Gói đã có `docs/index.html` và `.nojekyll`.

Chờ tác vụ triển khai hoàn tất, lấy URL do GitHub hiển thị và mở thử. Dạng URL thường là:

```text
https://YOUR-USERNAME.github.io/sql-soccer-game-analytics/
```

Đây là mẫu địa chỉ, chưa phải URL đã được tạo. Sao chép URL thực tế vào trường Website của repository và bổ sung liên kết Live dashboard ở đầu README. Kiểm tra bằng cửa sổ ẩn danh để biết người xem portfolio truy cập được.

GitHub Pages hiển thị bản HTML. Người muốn chỉnh sửa báo cáo Power BI cần tải toàn bộ repository, rồi mở PBIP bằng Power BI Desktop. Link Sites riêng tư từ cuộc trò chuyện không thay cho URL Pages công khai.

## 7. Làm repository dễ xem

Gợi ý phần About: dùng description ở bước 2, Website là URL Pages đã triển khai, các topic có thể là `sql`, `sqlite`, `data-analysis`, `football-analytics`, `power-bi`, `data-visualization`, `portfolio`.

Ghim repository này lên trang cá nhân để dễ tìm. Khi cần gửi nhà tuyển dụng, cung cấp hai đường dẫn: repository để đọc phương pháp/mã nguồn và dashboard Pages để xem tương tác. Bạn có thể thêm file PBIX đã kiểm thử vào một GitHub Release để người khác tải; PBIP vẫn là bản mã nguồn được theo dõi trong repository.

## 8. Chạy lại phân tích khi cần

Sau khi đặt database đúng đường dẫn, mở terminal tại thư mục gốc và chạy:

```bash
python scripts/run_analysis.py --db data/database.sqlite
python scripts/verify_results.py --db data/database.sqlite
```

Hai lệnh dùng thư viện chuẩn của Python. Cần SQLite 3.25 trở lên cho window functions. Để tạo lại hình, cài thư viện trong `requirements-charts.txt`, rồi chạy `python scripts/make_charts.py`.

Bạn cũng có thể dùng DB Browser for SQLite theo [báo cáo kết quả](BAO_CAO_KET_QUA.md). Các view là TEMP: phải tạo chúng và chạy truy vấn phụ thuộc trong cùng kết nối.

Việc chạy lại SQL không tự cập nhật Excel, HTML hoặc dữ liệu nhúng trong Power BI. Khi đổi dữ liệu, cập nhật và đối chiếu các bản báo cáo này trước khi công bố số mới.

## Tài liệu thao tác

- [GitHub: tạo repository bằng Desktop](https://docs.github.com/en/desktop/overview/creating-your-first-repository-using-github-desktop)
- [GitHub: đẩy thay đổi từ Desktop](https://docs.github.com/en/desktop/making-changes-in-a-branch/pushing-changes-to-github-from-github-desktop)
- [GitHub: cấu hình nguồn cho Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)
- [GitHub: giới hạn file](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github)

Hướng dẫn đối chiếu với tài liệu GitHub ngày 25/09/2026; giao diện có thể thay đổi theo phiên bản ứng dụng.
