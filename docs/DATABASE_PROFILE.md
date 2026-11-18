# Kiểm tra database — SQL Soccer Game Analytics

Đã đọc trực tiếp file database.sqlite bên trong tệp ZIP bạn cung cấp. Báo cáo này dùng số liệu thực tế, không dùng dữ liệu giả lập. Trạng thái: hoàn thành kiểm tra nền tảng và tạo dữ liệu phân tích; các phân tích chuyên sâu, biểu đồ và xuất bản GitHub vẫn là các bước tiếp theo.

## 1. Quy mô và phạm vi

| Table | Rows | Columns |
| --- | --- | --- |
| Country | 11 | 2 |
| League | 11 | 3 |
| Match | 25979 | 115 |
| Player | 11060 | 7 |
| Player_Attributes | 183978 | 42 |
| Team | 299 | 5 |
| Team_Attributes | 1458 | 25 |

Tổng cộng 7 bảng nghiệp vụ và 199 cột. Match có 25.979 dòng và 25.979 match_api_id khác nhau, bao phủ 11 giải, 88 tổ hợp giải–mùa, 8 mùa từ 2008/2009 đến 2015/2016. Ngày trận sớm nhất là 2008-07-18, muộn nhất là 2016-05-25. Các mốc này chỉ mô tả bảng Match; bảng thuộc tính có thời gian khác.

| Table | Một dòng đại diện cho |
| --- | --- |
| Country | Một quốc gia theo phân loại trong nguồn dữ liệu. |
| League | Một giải đấu; country_id liên kết với Country. |
| Match | Một trận đấu; match_api_id duy nhất trong file đã kiểm tra. |
| Player | Một cầu thủ theo player_api_id. |
| Player_Attributes | Một lần ghi nhận thuộc tính cầu thủ; cầu thủ và ngày chưa tạo thành khóa duy nhất. |
| Team | Một bản ghi đội theo team_api_id; không tự gộp theo tên hoặc mã FIFA. |
| Team_Attributes | Một lần ghi nhận thuộc tính đội; đội và ngày chưa tạo thành khóa duy nhất. |

## 2. Chất lượng dữ liệu lõi

| Kiểm tra | Kết quả |
| --- | --- |
| PRAGMA quick_check | ok — kiểm tra cấu trúc tệp, không chứng minh số liệu bóng đá là chính xác. |
| Thiếu mã trận, quốc gia, giải, mùa, ngày hoặc mã hai đội | 0 |
| Thiếu một trong hai tỷ số | 0 |
| Tỷ số âm, không nguyên hoặc lưu kiểu phi số | 0 |
| Ngày trận không phân tích được bằng date() | 0 |
| Nhóm match_api_id bị trùng | 0 |
| Nhóm khóa Team.team_api_id, League.id, Country.id bị trùng | 0 |
| Nhóm trùng tổ hợp giải–mùa–ngày–đội nhà–đội khách | 0 |
| Mã đội, giải hoặc quốc gia của Match không tìm thấy ở bảng tương ứng | 0 |
| Quốc gia của trận khác quốc gia của giải | 0 |
| Trận có đội chủ nhà trùng đội khách | 0 |
| Số dòng sau JOIN bốn bảng lõi | 25979 |

Kết luận thực hành: giữ nguyên cả 25.979 trận khi chuẩn bị dữ liệu kết quả cơ bản. Không cần điền tỷ số hoặc xóa dòng do các lỗi đã kiểm tra ở trên. Sự đầy đủ của từng trường không chứng minh toàn bộ lịch thi đấu của mỗi mùa đã được thu thập.

## 3. Độ bao phủ giải–mùa

Premier League có 3.040 trận, mỗi mùa 20 đội, 380 trận, 38 trận mỗi đội. Mỗi cặp có thứ tự đội nhà–đội khách xuất hiện đúng một lần trong từng mùa. Đây là căn cứ nội bộ để chọn mẫu học ban đầu; chưa đối chiếu lịch thi đấu chính thức bên ngoài.

| Giải–mùa | Quan sát trong file | Quyết định cho dự án |
| --- | --- | --- |
| Belgium 2013/2014 | 12 trận, 4 đội, mỗi đội 6 trận. | Giữ dữ liệu gốc; gắn cờ mẫu hẹp, chưa đưa vào so sánh đại diện cho cả giải–mùa. |
| Italy 2011/2012 | 358 trận, 20 đội; đội có 34–38 trận. | Cần kiểm chứng coverage trước khi dùng như một mùa đầy đủ. |
| Italy 2014/2015 | 379 trận, 20 đội; đội có 37–38 trận. | Cần kiểm chứng coverage; điểm tính từ các trận quan sát được. |
| Switzerland 2011/2012 | 162 trận; đội có 18–34 trận. | Gắn cờ bất cân xứng; chưa suy đoán nguyên nhân. |
| Scotland và Switzerland, các mùa khác | Có cặp đội lặp lại nhiều hơn một lần theo cùng chiều sân. | Không áp dụng một cấu trúc hai lượt chung cho mọi giải. |

Giả định một giải có N đội và mỗi cặp gặp nhau hai lượt cho số trận N×(N−1). Đây là phép kiểm tra có điều kiện, không phải quy tắc áp cho mọi giải. Belgium 2013/2014 vẫn thỏa công thức với bốn đội quan sát được, cho thấy công thức tự nó không xác nhận độ đầy đủ của mùa giải. Không tự tạo thêm trận hoặc tỷ số để đạt một số đếm kỳ vọng.

## 4. Các bảng thuộc tính và nhóm cột mở rộng

| Nhóm dữ liệu | Kết quả thực tế | Hệ quả khi phân tích |
| --- | --- | --- |
| Player_Attributes | 183.978 dòng, 11.060 cầu thủ; 835 nhóm player_api_id–date lặp, 836 dòng vượt mức một dòng/nhóm. | Kiểm tra nội dung từng nhóm trước khi chọn quy tắc; không JOIN rồi dùng DISTINCT để che việc tăng dòng. |
| Player overall_rating | 836 giá trị NULL. | Không thay rating thiếu bằng 0; ghi rõ mẫu số khi tổng hợp. |
| Player attribute dates | 2007-02-22 đến 2016-07-07. | Khi dùng thuộc tính trước trận, loại bản ghi tương lai và xử lý trùng thời điểm. |
| Team_Attributes | 1.458 dòng cho 288 mã đội; 1 nhóm team_api_id–date lặp. | 11 mã đội trong Team không có thuộc tính; giữ bằng LEFT JOIN nếu câu hỏi cần toàn bộ mẫu. |
| Team attribute dates | 6 ngày ghi nhận khác nhau, từ 2010-02-22 đến 2015-09-10. | Không coi bảng này là dữ liệu cập nhật hàng tuần; các trận trước lần ghi nhận đầu tiên không có snapshot quá khứ phù hợp. |
| Team.team_fifa_api_id | 11 NULL và 3 nhóm mã lặp. | Ưu tiên team_api_id cho quan hệ trận–đội; không tự gộp đội theo tên hoặc mã FIFA. |
| Team buildUpPlayDribbling | 969 NULL trên 1.458 dòng. | Chưa dùng trường này như một biến đầy đủ cho mọi đội/mọi thời điểm. |
| Đội hình | 21.374/25.979 trận có đủ 22 mã cầu thủ. | Thiếu ít nhất một mã ở 4.605 trận; cần báo cáo tỷ lệ bao phủ khi tính rating đội hình. |
| Tọa độ | 24.140/25.979 trận có đủ 44 tọa độ X/Y. | Đủ tọa độ và đủ mã cầu thủ là hai kiểm tra riêng, chưa khẳng định đủ cả hai cùng lúc. |

Các vị trí cầu thủ không NULL trong Match đều khớp Player.player_api_id. Các bản ghi thuộc tính đều khớp entity tương ứng bằng mã API. Điều này không làm cho quan hệ theo thời gian trở thành một-một.

## 5. Sự kiện XML và odds

| Cột | Không NULL | XML rỗng ở phần tử gốc | Có phần tử con | Lỗi cú pháp XML |
| --- | --- | --- | --- | --- |
| goal | 14217 | 993 | 13224 | 0 |
| shoton | 14217 | 5754 | 8463 | 0 |
| shotoff | 14217 | 5754 | 8463 | 0 |
| foulcommit | 14217 | 5752 | 8465 | 0 |
| card | 14217 | 441 | 13776 | 0 |
| cross | 14217 | 5752 | 8465 | 0 |
| corner | 14217 | 5753 | 8464 | 0 |
| possession | 14217 | 5798 | 8419 | 0 |

Ví dụ possession không NULL ở 14.217 trận, nhưng chỉ 8.419 chuỗi có phần tử con; 5.798 chuỗi có phần tử gốc rỗng. Có phần tử con cũng chưa xác nhận đủ các lần đo, phút thi đấu hoặc dữ liệu số hợp lệ. XML goal rỗng có thể phù hợp với trận không có bàn; không áp cùng một cách diễn giải cho mọi loại sự kiện. Không tính AVG trực tiếp trên XML hoặc biến NULL thành 0.

| Giải | Số trận | goal không NULL | possession không NULL |
| --- | --- | --- | --- |
| Belgium Jupiler League | 1728 | 0 | 0 |
| England Premier League | 3040 | 3040 | 3040 |
| France Ligue 1 | 3040 | 2026 | 2026 |
| Germany 1. Bundesliga | 2448 | 2448 | 2448 |
| Italy Serie A | 3017 | 3014 | 3014 |
| Netherlands Eredivisie | 2448 | 530 | 530 |
| Poland Ekstraklasa | 1920 | 7 | 7 |
| Portugal Liga ZON Sagres | 2052 | 0 | 0 |
| Scotland Premier League | 1824 | 13 | 13 |
| Spain LIGA BBVA | 3040 | 3039 | 3039 |
| Switzerland Super League | 1422 | 100 | 100 |

| Nhóm cột odds | Đủ H/D/A | Cả ba là số >1 |
| --- | --- | --- |
| B365 | 22592 | 22592 |
| BW | 22575 | 22575 |
| IW | 22520 | 22520 |
| LB | 22556 | 22556 |
| PS | 11168 | 11168 |
| WH | 22571 | 22571 |
| SJ | 17097 | 17097 |
| VC | 22568 | 22568 |
| GB | 14162 | 14162 |
| BS | 14161 | 14161 |

SQL 06 kiểm tra NULL và khóa theo thời gian. Script scripts/profile_xml.py tái tạo phép kiểm tra cấu trúc XML bằng thư viện chuẩn Python; chỉ cần dùng khi đi vào phần mở rộng.

## 6. Dữ liệu phân tích đã xác minh

- v_matches: 25.979 dòng, một dòng cho một trận.
- v_team_matches: 51.958 dòng, một dòng cho một đội trong một trận.
- Mỗi trận xuất hiện đúng hai dòng đội khác nhau.
- Tổng bàn thắng quan sát: 70.287; tổng goals_for và goals_against của dữ liệu đội–trận cùng bằng con số này.
- 10 kiểm tra đối chiếu trong SQL 04 đều đạt.

Các view là TEMP, tồn tại trong phiên kết nối; chạy lại SQL 03 sau khi mở lại database. Các bảng nguồn giữ nguyên. Điểm = 3×thắng + hòa là điểm tái tính từ dữ liệu; không mặc định trùng bảng xếp hạng chính thức hoặc các quy tắc trừ điểm, phân hạng.

## 7. Tái lập

Chạy SQL 00 → 01 → 02 → 03 → 04 → 05; SQL 06 là bước kiểm tra mở rộng. Các file SQL đã chạy thành công trên bản tải lên. Kết quả chi tiết nằm trong outputs/ và metadata/schema trong docs/DATA_DICTIONARY.md.

Nguồn được người dùng xác định: [European Soccer Database — Kaggle](https://www.kaggle.com/datasets/hugomathien/soccer). Ngày tải bản gốc và phiên bản Kaggle chưa được cung cấp. Thống kê trong báo cáo được tính từ file đã nhận, không suy ra từ trang mô tả.

File SQLite: 313,090,048 bytes. SHA-256: `4df8569777d59fdd690754b1cc8ca1f7989baf65f2eaddd0f1368285f11139a9`. Công cụ kiểm tra: Python sqlite3 với SQLite 3.53.1. Ngày kiểm tra: 2026-09-19. PRAGMA quick_check trả về ok. Không suy ra độ chính xác của mọi giá trị chỉ từ kiểm tra này.
