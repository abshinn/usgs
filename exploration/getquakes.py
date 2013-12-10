#!/usr/bin/env python3
"""Script to run pull down data for SF & LA earthquake event comparrison."""

import os
os.chdir("../")

import usgs

# obtain data for the greater San Francisco area, 1983 through 2012
usgs.APIquery(starttime = "1983-01-01", endtime = "2013-01-01",
              minmagnitude = "0.1",
              latitude = "37.77", longitude = "-122.44",
              minradiuskm = "0", maxradiuskm = "200",
              reviewstatus = "reviewed",
              filename = "usgsQuery_SF_83-12.csv",
              format = "csv")

# obtain data for the greater Los Angeles area, 1983 through 2012
usgs.APIquery(starttime = "1983-01-01", endtime = "2013-01-01",
              minmagnitude = "0.1",
              latitude = "34.05", longitude = "-118.26",
              minradiuskm = "0", maxradiuskm = "200",
              reviewstatus = "reviewed",
              filename = "usgsQuery_LA_83-12.csv",
              format = "csv")

# move csv files to exploration folder
for item in os.listdir():
    if '.csv' in os.path.splitext(item)[-1]:
        os.rename(item, "exploration/{}".format(item))
