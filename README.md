metalprice
==========

Looking for historical prices of metal trading? 

1. If you need only hitorical data before 2012, just use data/LondonFix.csv
The data are collected from www.kitco.com, which provides daily prices of gold, silver, platinum, and palladium.

Format of the csv file:
Date,Gold:AM,Gold:PM,Silver,Platinum:AM,Platinum:PM,Palladium:AM,Palladium:PM
2011-12-29,1537.50,1531.00,26.1600,1364.00,1354.00,636.00,630.00

2. If you need newest data, run kitco.pm. No installation. You only need
perl installed on your computer. The program gets newest data and appends it
to data/LondonFix.csv
