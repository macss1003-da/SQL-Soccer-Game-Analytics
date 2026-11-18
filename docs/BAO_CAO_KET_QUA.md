# SQL Soccer Game Analytics — Báo cáo kết quả cuối cùng

Ngày tổng hợp: 24/09/2026. Khoảng thời gian dữ liệu: **2008/2009–2015/2016**. Đây là phân tích dữ liệu lịch sử, không phản ánh bóng đá hiện tại.

## 1. Dự án đã hoàn thành những gì?

Bộ dự án trả lời năm câu hỏi: các giải ghi bao nhiêu bàn mỗi trận; đội nào dẫn đầu theo điểm/trận trong từng giải–mùa; kết quả sân nhà khác sân khách ra sao; đội nào cải thiện giữa hai mùa liên tiếp; và cách so sánh các giải sau khi kiểm tra độ bao phủ dữ liệu.

Đã hoàn thành 14 file SQL theo bước, một file SQL tổng hợp, 38 bảng kết quả CSV, bảng Excel, 6 biểu đồ PNG/SVG, báo cáo và README tiếng Anh. Đã thực thi **52 câu lệnh SQL**, đạt **22/22 kiểm tra đối chiếu**. Mã nguồn và kết quả sẵn sàng để bạn đưa lên GitHub; repository chưa được xuất bản.

Nhánh FIFA, sự kiện XML, odds và machine learning mới dừng ở kiểm tra khả năng sử dụng dữ liệu, chưa có mô hình hoặc kết luận phân tích riêng. Những nhánh này không nằm trong năm câu hỏi chính của phiên bản portfolio này.

## 2. Dữ liệu và kiểm tra chất lượng

| Bảng | Số dòng |
| --- | --- |
| Country | 11 |
| League | 11 |
| Match | 25.979 |
| Team | 299 |
| Player | 11.060 |
| Player_Attributes | 183.978 |
| Team_Attributes | 1.458 |

Tổng cộng 7 bảng và 199 cột. Có 11 giải thuộc 11 quốc gia, 299 mã đội xuất hiện trong trận đấu, 8 mùa, và 88 tổ hợp giải–mùa. Ngày trận sớm nhất là 18/07/2008, muộn nhất là 25/05/2016.

Kiểm tra trên các trường lõi không phát hiện mã trận trùng, giá trị bắt buộc bị thiếu, tỷ số âm/không nguyên, ngày không phân tích được, đội tự đấu với chính mình, hay mã đội/giải/quốc gia không nối được. Các phép JOIN giữ nguyên **25.979 trận**. Bảng góc nhìn đội–trận có **51.958 dòng**, đúng hai dòng cho một trận.

“Không có lỗi ở các trường lõi” không có nghĩa mọi cột hoặc mọi mùa đều đầy đủ. Bốn trường hợp cần được ghi rõ khi đọc kết quả:

| Giải | Mùa | Trận quan sát | Đội | Trận/đội |
| --- | --- | --- | --- | --- |
| Belgium Jupiler League | 2013/2014 | 12 | 4 | 6–6 |
| Italy Serie A | 2011/2012 | 358 | 20 | 34–38 |
| Italy Serie A | 2014/2015 | 379 | 20 | 37–38 |
| Switzerland Super League | 2011/2012 | 162 | 10 | 18–34 |

Belgium 2013/2014 vẫn có thể vượt qua kiểm tra vòng tròn hai lượt khi chỉ xét 4 đội quan sát. Vì vậy, kết quả kiểm tra cấu trúc không chứng minh đây là toàn bộ mùa giải. Switzerland và Scotland có cấu trúc gặp nhau khác mẫu hai lượt đơn giản. Các giai đoạn thi đấu cũng cần được xem xét riêng.

**Mẫu so sánh có lịch quan sát cân bằng** gồm England, France, Germany, Netherlands và Spain: 40 giải–mùa, **14.016 trận**. Trong từng giải–mùa này, mỗi cặp đội gặp nhau hai lần với hai vai trò sân nhà/sân khách. Đây là kiểm tra nội bộ dữ liệu; chưa đối chiếu toàn bộ lịch thi đấu chính thức và chưa điều chỉnh sức mạnh đối thủ.

## 3. Chỉ số và cách tính

| Chỉ số | Công thức | Cách đọc |
| --- | --- | --- |
| Bàn/trận | Tổng bàn của hai đội / số trận | Mức ghi bàn trong các trận quan sát |
| Điểm | 3 × thắng + hòa | Điểm dựng lại từ tỷ số, chưa áp dụng điểm phạt |
| PPG | Điểm / số trận của đội | Points per game: hiệu suất điểm mỗi trận |
| Tỷ lệ thắng sân nhà | Số trận chủ nhà thắng / số trận | Mẫu số là trận đấu, không phải số đội |
| Chênh lệch tỷ lệ thắng | 100 × (thắng sân nhà − thắng sân khách) / số trận | Đơn vị: điểm phần trăm |
| Chênh lệch PPG sân nhà–khách | Điểm nhà/trận nhà − điểm khách/trận khách | Số dương: PPG sân nhà cao hơn |
| Thay đổi PPG qua mùa | PPG mùa hiện tại − PPG mùa ngay trước | Cùng team_api_id, cùng giải, hai năm bắt đầu liên tiếp |

SQL dùng `1.0` hoặc `100.0` để tránh chia số nguyên. Dữ liệu tính toán giữ đủ độ chính xác; báo cáo chỉ làm tròn khi hiển thị. Không lấy trung bình đơn giản của các tỷ lệ nếu mẫu số khác nhau; số tổng hợp dùng tổng tử số chia tổng mẫu số.

## 4. Kết quả tổng quan

| Chỉ tiêu | Kết quả |
| --- | --- |
| Trận đấu | 25.979 |
| Tổng bàn thắng | 70.287 |
| Bàn sân nhà / sân khách | 40.127 / 30.160 |
| Bàn/trận | 2,706 |
| Chủ nhà thắng | 11.917 — 45,87% |
| Hòa | 6.596 — 25,39% |
| Khách thắng | 7.466 — 28,74% |
| Chênh lệch tỷ lệ thắng nhà–khách | 17,13 điểm phần trăm |

**Kết luận:** kết quả thắng sân nhà xuất hiện thường xuyên hơn thắng sân khách trong tập dữ liệu. Đây là mô tả dữ liệu; các truy vấn chưa chứng minh nguyên nhân hoặc ước lượng tác động riêng của sân nhà.

Nguồn: `sql/08_overview_and_leagues.sql`, bảng `overview.csv`.

## 5. So sánh 11 giải đấu

| Giải | Trận | Bàn | Bàn/trận | Nhà thắng | Khách thắng |
| --- | --- | --- | --- | --- | --- |
| Netherlands Eredivisie | 2.448 | 7.542 | 3,081 | 47,83% | 28,43% |
| Switzerland Super League | 1.422 | 4.166 | 2,930 | 45,71% | 29,96% |
| Germany 1. Bundesliga | 2.448 | 7.103 | 2,902 | 45,22% | 30,39% |
| Belgium Jupiler League | 1.728 | 4.841 | 2,802 | 46,88% | 28,53% |
| Spain LIGA BBVA | 3.040 | 8.412 | 2,767 | 48,85% | 27,99% |
| England Premier League | 3.040 | 8.240 | 2,711 | 45,72% | 28,52% |
| Scotland Premier League | 1.824 | 4.804 | 2,634 | 41,67% | 33,83% |
| Italy Serie A | 3.017 | 7.895 | 2,617 | 46,64% | 26,98% |
| Portugal Liga ZON Sagres | 2.052 | 5.201 | 2,535 | 44,25% | 29,78% |
| France Ligue 1 | 3.040 | 7.427 | 2,443 | 44,70% | 27,04% |
| Poland Ekstraklasa | 1.920 | 4.656 | 2,425 | 45,31% | 27,34% |

**Eredivisie có trung bình cao nhất: 3,081 bàn/trận** trên 2.448 trận. Poland có trung bình thấp nhất trong toàn bộ mẫu quan sát: 2,425 bàn/trận trên 1.920 trận. Trong mẫu năm giải có lịch cân bằng, France thấp nhất với 2,443 bàn/trận.

Spain có tỷ lệ thắng sân nhà 48,85%, cao nhất trong 11 giải quan sát, và chênh lệch nhà–khách 20,86 điểm phần trăm. Điều này mô tả các trận có trong database, không đủ để kết luận giải nào mạnh hơn hoặc giải nào gây ra lợi thế sân nhà lớn hơn.

Nguồn: SQL 08, `league_summary.csv` và `stable_league_comparison.csv`. Biểu đồ: `assets/01_goals_by_league.png` và `assets/06_stable_leagues_scoring_trend.png`.

## 6. Premier League thay đổi qua từng mùa

| Mùa | Trận | Bàn | Bàn/trận | Nhà thắng | Hòa | Khách thắng | Chênh lệch (đpt) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2008/2009 | 380 | 942 | 2,479 | 45,53% | 25,53% | 28,95% | 16,58 |
| 2009/2010 | 380 | 1.053 | 2,771 | 50,79% | 25,26% | 23,95% | 26,84 |
| 2010/2011 | 380 | 1.063 | 2,797 | 47,11% | 29,21% | 23,68% | 23,42 |
| 2011/2012 | 380 | 1.066 | 2,805 | 45,00% | 24,47% | 30,53% | 14,47 |
| 2012/2013 | 380 | 1.063 | 2,797 | 43,68% | 28,42% | 27,89% | 15,79 |
| 2013/2014 | 380 | 1.052 | 2,768 | 47,11% | 20,53% | 32,37% | 14,74 |
| 2014/2015 | 380 | 975 | 2,566 | 45,26% | 24,47% | 30,26% | 15,00 |
| 2015/2016 | 380 | 1.026 | 2,700 | 41,32% | 28,16% | 30,53% | 10,79 |

Cả tám mùa đều có 380 trận quan sát. Mùa 2011/2012 có mức bàn/trận cao nhất trong mẫu Premier League: 1.066/380 = **2,805**. Mùa 2008/2009 thấp nhất: 942/380 = **2,479**.

Tỷ lệ thắng sân nhà giảm từ **45,53%** ở mùa 2008/2009 xuống **41,32%** ở mùa 2015/2016, tương đương giảm **4,21 điểm phần trăm** giữa hai đầu kỳ. Chỉ số dao động qua các năm, nên không gọi đây là mức giảm liên tục. Mùa cuối có khoảng cách nhà–khách **10,79 điểm phần trăm**, nhỏ nhất trong tám mùa Premier League quan sát.

Nguồn: SQL 09, `premier_league_seasons.csv`. Biểu đồ: `assets/02_epl_home_away_trend.png`.

## 7. Thành tích đội bóng và cách đọc thứ hạng

SQL tạo **1.481 dòng đội–giải–mùa** và xếp hạng theo PPG bằng `DENSE_RANK()` trong từng giải–mùa. Có **90 dòng dẫn đầu** cho 88 giải–mùa vì hai giải–mùa có đồng hạng theo PPG. Không dùng bảng này như bảng xếp hạng chính thức.

Các đội dẫn đầu PPG trong Premier League:

| Mùa | Đội | Trận | Điểm tính lại | PPG |
| --- | --- | --- | --- | --- |
| 2008/2009 | Manchester United | 38 | 90 | 2,368 |
| 2009/2010 | Chelsea | 38 | 86 | 2,263 |
| 2010/2011 | Manchester United | 38 | 80 | 2,105 |
| 2011/2012 | Manchester City | 38 | 89 | 2,342 |
| 2011/2012 | Manchester United | 38 | 89 | 2,342 |
| 2012/2013 | Manchester United | 38 | 89 | 2,342 |
| 2013/2014 | Manchester City | 38 | 86 | 2,263 |
| 2014/2015 | Chelsea | 38 | 87 | 2,289 |
| 2015/2016 | Leicester City | 38 | 81 | 2,132 |

Manchester City và Manchester United cùng có 89 điểm mùa 2011/2012, nên cùng hạng PPG. Truy vấn không dùng hiệu số bàn thắng hay luật phụ để chọn nhà vô địch.

Bảng Premier League mùa 2015/2016 tính từ dữ liệu:

| Hạng PPG | Đội | Trận | Thắng | Hòa | Thua | BT | BB | Điểm | PPG |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Leicester City | 38 | 23 | 12 | 3 | 68 | 36 | 81 | 2,132 |
| 2 | Arsenal | 38 | 20 | 11 | 7 | 65 | 36 | 71 | 1,868 |
| 3 | Tottenham Hotspur | 38 | 19 | 13 | 6 | 69 | 35 | 70 | 1,842 |
| 4 | Manchester City | 38 | 19 | 9 | 10 | 71 | 41 | 66 | 1,737 |
| 4 | Manchester United | 38 | 19 | 9 | 10 | 49 | 35 | 66 | 1,737 |
| 5 | Southampton | 38 | 18 | 9 | 11 | 59 | 41 | 63 | 1,658 |
| 6 | West Ham United | 38 | 16 | 14 | 8 | 65 | 51 | 62 | 1,632 |
| 7 | Liverpool | 38 | 16 | 12 | 10 | 63 | 50 | 60 | 1,579 |
| 8 | Stoke City | 38 | 14 | 9 | 15 | 41 | 55 | 51 | 1,342 |
| 9 | Chelsea | 38 | 12 | 14 | 12 | 59 | 53 | 50 | 1,316 |
| 10 | Everton | 38 | 11 | 14 | 13 | 59 | 55 | 47 | 1,237 |
| 10 | Swansea City | 38 | 12 | 11 | 15 | 42 | 52 | 47 | 1,237 |
| 11 | Watford | 38 | 12 | 9 | 17 | 40 | 50 | 45 | 1,184 |
| 12 | West Bromwich Albion | 38 | 10 | 13 | 15 | 34 | 48 | 43 | 1,132 |
| 13 | Bournemouth | 38 | 11 | 9 | 18 | 45 | 67 | 42 | 1,105 |
| 13 | Crystal Palace | 38 | 11 | 9 | 18 | 39 | 51 | 42 | 1,105 |
| 14 | Sunderland | 38 | 9 | 12 | 17 | 48 | 62 | 39 | 1,026 |
| 15 | Newcastle United | 38 | 9 | 10 | 19 | 44 | 65 | 37 | 0,974 |
| 16 | Norwich City | 38 | 9 | 7 | 22 | 39 | 67 | 34 | 0,895 |
| 17 | Aston Villa | 38 | 3 | 8 | 27 | 27 | 76 | 17 | 0,447 |

**Leicester City đứng đầu** với 81 điểm từ 23 thắng, 12 hòa và 3 thua: `(23 × 3 + 12) / 38 = 2,132 PPG`. Manchester City và Manchester United cùng hạng PPG 4; hạng tiếp theo theo `DENSE_RANK` là 5. Đây là quy tắc đồng hạng của chỉ số, không phải thứ tự chính thức của giải.

Nguồn: SQL 10; `team_season_rankings.csv` chứa đầy đủ 1.481 dòng, `league_season_ppg_leaders.csv` chứa toàn bộ 90 dòng dẫn đầu. Biểu đồ: `assets/03_epl_2015_16_points.png`.

## 8. Sân nhà và sân khách

Năm trường hợp có chênh lệch PPG sân nhà cao nhất trong 160 đội–mùa Premier League:

| Đội | Mùa | Trận nhà/khách | Điểm nhà/khách | PPG nhà | PPG khách | Chênh lệch |
| --- | --- | --- | --- | --- | --- | --- |
| Manchester United | 2010/2011 | 19/19 | 55/25 | 2,895 | 1,316 | 1,579 |
| Manchester City | 2008/2009 | 19/19 | 39/11 | 2,053 | 0,579 | 1,474 |
| Fulham | 2009/2010 | 19/19 | 36/10 | 1,895 | 0,526 | 1,368 |
| Stoke City | 2008/2009 | 19/19 | 35/10 | 1,842 | 0,526 | 1,316 |
| Sunderland | 2009/2010 | 19/19 | 34/10 | 1,789 | 0,526 | 1,263 |

**Manchester United 2010/2011** có chênh lệch lớn nhất: 55/19 − 25/19 = **1,579 PPG**. Cả hai mẫu đều có 19 trận, giúp tránh diễn giải nhầm do khác số trận sân nhà và sân khách. Vị trí thứ năm có đồng mức chênh lệch với Bolton Wanderers 2010/2011; CSV top 10 giữ cả hai trường hợp.

Riêng mùa 2015/2016, Newcastle có chênh lệch cao nhất, **1,000 PPG**. Everton, Bournemouth và Chelsea có PPG sân khách cao hơn sân nhà trong mẫu mùa này. Vì vậy, xu hướng chung của giải không có nghĩa đội nào cũng đạt kết quả sân nhà tốt hơn.

Nguồn: SQL 11; `team_home_away.csv` chứa đủ 1.481 dòng. Biểu đồ: `assets/04_epl_2015_16_venue_gap.png`.

## 9. Đội nào cải thiện nhiều nhất qua mùa?

`LAG()` tìm mùa quan sát trước của cùng đội trong cùng giải. SQL chỉ giữ cặp có năm bắt đầu chênh nhau đúng 1 để không nối qua một mùa vắng mặt. Có **1.110 cặp mùa liên tiếp** trên toàn dữ liệu, **578 cặp** trong mẫu năm giải cân bằng, và **119 cặp** Premier League.

Năm mức cải thiện đầu tiên trong Premier League:

| Đội | Từ mùa | Đến mùa | Điểm trước | Điểm sau | Tăng điểm | Tăng PPG |
| --- | --- | --- | --- | --- | --- | --- |
| Leicester City | 2014/2015 | 2015/2016 | 41 | 81 | +40 | +1,053 |
| Liverpool | 2012/2013 | 2013/2014 | 61 | 84 | +23 | +0,605 |
| Tottenham Hotspur | 2008/2009 | 2009/2010 | 51 | 70 | +19 | +0,500 |
| Newcastle United | 2010/2011 | 2011/2012 | 46 | 65 | +19 | +0,500 |
| Manchester City | 2010/2011 | 2011/2012 | 71 | 89 | +18 | +0,474 |

**Leicester City 2014/2015–2015/2016** tăng từ 41 lên 81 điểm, tức **+40 điểm**, PPG từ **1,079 lên 2,132**, tăng **1,053**. Đây là mức tăng PPG lớn nhất trong 119 cặp Premier League, đồng thời lớn nhất trong mẫu 578 cặp thuộc năm giải cân bằng. So sánh giữa các giải vẫn chưa điều chỉnh sức mạnh đối thủ.

Nguồn: SQL 12; `consecutive_season_changes.csv` có đầy đủ 1.110 dòng cùng ghi chú coverage ở cả hai mùa. Biểu đồ: `assets/05_epl_improvements.png`.

## 10. Các câu lệnh cần chạy và ý nghĩa

| File SQL | Mục đích | Đầu ra chính |
| --- | --- | --- |
| 00_inspect_database.sql | Đọc cấu trúc trước khi viết JOIN | 7 bảng, 199 cột, 31 dòng ánh xạ khóa ngoại khai báo |
| 01_profile_core.sql | Kiểm tra NULL, mã trùng, tỷ số, ngày và quan hệ | Không phát hiện lỗi lõi trong bản dữ liệu này |
| 02_coverage_audit.sql | Kiểm tra phạm vi từng giải–mùa | 88 dòng coverage, số đội/trận/cặp đối đầu |
| 03_build_analysis_views.sql | JOIN tên giải/đội; UNION ALL tạo hai góc nhìn | v_matches: 25.979; v_team_matches: 51.958 |
| 04_validate_views.sql | Đối chiếu số dòng, bàn, thắng–thua, điểm | 10 kiểm tra đạt |
| 05_first_analysis.sql | Bài thực hành Premier League ban đầu | 8 mùa, 380 trận/mùa |
| 06_extension_audit.sql | Kiểm tra điều kiện mở rộng FIFA/XML | Khóa entity–date trùng và coverage sự kiện |
| 07_build_summary_views.sql | Tổng hợp đội–mùa, giải–mùa; DENSE_RANK; LAG | Các view chuẩn cho phân tích |
| 08_overview_and_leagues.sql | Trả lời câu hỏi tổng quan và so sánh giải | Tổng quan, 11 giải, mẫu so sánh 5 giải |
| 09_season_trends.sql | Đọc biến động theo mùa | 88 giải–mùa; Premier League 8 mùa |
| 10_team_rankings.sql | Xếp hạng theo PPG trong giải–mùa | 1.481 đội–mùa; 90 dòng dẫn đầu |
| 11_home_away.sql | Tính PPG ở từng sân và chênh lệch | 1.481 dòng đội–mùa, ví dụ Premier League |
| 12_consecutive_season_changes.sql | Đánh giá thay đổi giữa hai mùa kề nhau | 1.110 cặp mùa và các mức tăng lớn |
| 13_validate_aggregates.sql | Đối chiếu tổng hợp và điều kiện so sánh | 12 kiểm tra đạt |

`ALL_SOCCER_ANALYSIS.sql` chứa toàn bộ các file theo đúng thứ tự. Trong DB Browser for SQLite:

1. Mở file `database.sqlite` thật của bạn bằng **Open Database**.
2. Chạy từng truy vấn `SELECT` để đọc từng bảng. Bạn có thể đánh dấu đúng phần SQL cần chạy.
3. Chạy toàn bộ file 03 và 07 để tạo các view. Các truy vấn từ 08 đến 13 sử dụng chúng.
4. Giữ nguyên kết nối trong lúc chạy. Sau khi đóng/mở lại database, chạy lại 03 và 07 trước các phân tích.
5. Công cụ có thể chỉ hiển thị bảng cuối khi chạy nhiều `SELECT` cùng lúc. Muốn xem từng bảng, chạy riêng từng truy vấn; muốn xuất tất cả CSV, dùng script bên dưới.

Các view đều là `TEMP`, không sửa các bảng nguồn. SQL cần SQLite 3.25 trở lên vì dùng window functions; phiên bản 3.46.1 trong ảnh của bạn đáp ứng yêu cầu này. Lần chạy đối chiếu này dùng SQLite 3.53.1.

Từ thư mục gốc của project, cách xuất lại toàn bộ kết quả bằng Python:

```bash
python scripts/run_analysis.py --db data/database.sqlite
python scripts/verify_results.py --db data/database.sqlite
```

Hai script này chỉ dùng thư viện chuẩn của Python. Script đầu chạy toàn bộ SQL trong một kết nối rồi xuất CSV/JSON và danh mục `outputs/results/RESULT_INDEX.md`. Script thứ hai đối chiếu lại với bảng `Match` bằng cách tính độc lập, dùng phân số chính xác để kiểm tra đồng hạng.

Để vẽ lại biểu đồ khi môi trường có Matplotlib:

```bash
python scripts/make_charts.py
```

File `SOCCER_RESULTS.xlsx` là bản tổng hợp tiện xem, có 5 sheet: Overview, League seasons, Team seasons, Season changes, Coverage. Các tỷ lệ/PPG dùng công thức Excel. Hạng và các dòng lựa chọn là snapshot từ SQL; chỉnh một ô trong Excel không tự chạy lại SQL hay xếp lại toàn bộ dữ liệu. Khi đổi database cần chạy lại pipeline và làm mới bản xuất Excel. Bảng CSV đầy đủ là đầu ra tái lập chuẩn của dự án.

## 11. Giới hạn và hướng mở rộng

- Điểm được dựng từ tỷ số với quy tắc 3/1/0, chưa áp dụng trừ điểm, luật phụ, hoặc quy tắc các giai đoạn thi đấu.
- Tất cả kết luận là mô tả dữ liệu quan sát. Chưa có kiểm định ý nghĩa thống kê, mô hình dự báo hoặc ước lượng nhân quả.
- Không gộp đội theo tên hoặc `team_fifa_api_id`. `team_api_id` là khóa dùng cho JOIN với trận đấu.
- Player_Attributes có 835 nhóm khóa cầu thủ–ngày bị trùng, tương ứng 836 dòng dư; Team_Attributes có 1 nhóm đội–ngày bị trùng. Cần giải quyết trước khi JOIN theo thời gian.
- Non-NULL XML không đồng nghĩa sự kiện đã được ghi đầy đủ. Thời điểm ghi nhận odds chưa được xác minh. Phân tích nhánh này cần bước chuẩn hóa và kiểm tra riêng.
- Mốc phiên bản và ngày tải Kaggle ban đầu chưa được cung cấp. Định danh bản dữ liệu bằng SHA-256: `4df8569777d59fdd690754b1cc8ca1f7989baf65f2eaddd0f1368285f11139a9`; dung lượng 313.090.048 byte. File nguồn giữ nguyên sau lần chạy.

## 12. Hoàn thiện portfolio trên GitHub

Giải nén bộ dự án và dùng thư mục `sql-soccer-game-analytics` làm repository. Đặt database tại `data/database.sqlite` ở máy để chạy; `.gitignore` đã loại database và các bản ZIP dữ liệu thô. Giữ SQL, README, tài liệu, script, kết quả tổng hợp và biểu đồ trong repository.

README tiếng Anh đã có mục tiêu, phương pháp, năm phát hiện có số liệu, hình minh họa, giới hạn và cách tái lập. Bạn nên đọc và tự giải thích được `JOIN`, `CASE`, `GROUP BY`, `UNION ALL`, `DENSE_RANK` và `LAG` trước khi dùng dự án trong phỏng vấn. Phần phân tích và tài liệu đã hoàn tất; thao tác tạo repository và đẩy mã lên tài khoản GitHub của bạn vẫn cần thực hiện.
