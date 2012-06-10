metalprice
==========

Looking for historical prices of metal trading? 

Here is hitorical data before 2012. Open data/LondonFix.csv to get what you need.
The data are collected from www.kitco.com, which provides daily prices of gold,
silver, platinum, and palladium.

Format of the csv file:
Date,Gold:AM,Gold:PM,Silver,Platinum:AM,Platinum:PM,Palladium:AM,Palladium:PM
2011-12-29,1537.50,1531.00,26.1600,1364.00,1354.00,636.00,630.00

Need newest data?
We provide a perl program. Just run bin/kitco.pm. You only need perl installed
on your computer. The program gets newest data and appends it to
data/LondonFix.csv
