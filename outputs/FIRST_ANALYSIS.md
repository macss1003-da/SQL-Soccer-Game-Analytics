# First exercise: Premier League season overview

Actual result of sql/05_first_analysis.sql after creating the temporary views. Source: the uploaded database; 3,040 matches across eight seasons. Percentages use all matches in each season, including draws. Rounded percentages may not sum to exactly 100.00. The gap is calculated before rounding.

| Season | Matches | Goals | Goals/match | Home wins | Draws | Away wins | Home win % | Draw % | Away win % | Home–away gap (pp) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2008/2009 | 380 | 942 | 2.479 | 173 | 97 | 110 | 45.53 | 25.53 | 28.95 | 16.58 |
| 2009/2010 | 380 | 1053 | 2.771 | 193 | 96 | 91 | 50.79 | 25.26 | 23.95 | 26.84 |
| 2010/2011 | 380 | 1063 | 2.797 | 179 | 111 | 90 | 47.11 | 29.21 | 23.68 | 23.42 |
| 2011/2012 | 380 | 1066 | 2.805 | 171 | 93 | 116 | 45.00 | 24.47 | 30.53 | 14.47 |
| 2012/2013 | 380 | 1063 | 2.797 | 166 | 108 | 106 | 43.68 | 28.42 | 27.89 | 15.79 |
| 2013/2014 | 380 | 1052 | 2.768 | 179 | 78 | 123 | 47.11 | 20.53 | 32.37 | 14.74 |
| 2014/2015 | 380 | 975 | 2.566 | 172 | 93 | 115 | 45.26 | 24.47 | 30.26 | 15.00 |
| 2015/2016 | 380 | 1026 | 2.700 | 157 | 107 | 116 | 41.32 | 28.16 | 30.53 | 10.79 |

Example check: 2015/2016 has 1,026 goals in 380 matches, or 2.700 goals per match. Its observed home win rate is 41.32% and away win rate is 30.53%; the gap is 10.79 percentage points. This is descriptive and does not estimate a causal venue effect.

Next exercises: aggregate points per team-season, rank within a league-season, calculate venue differences, and compare genuinely consecutive seasons. These follow-up analyses have not yet been completed in this package.
