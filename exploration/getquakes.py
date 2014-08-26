#!/usr/bin/env python3 -B -tt
"""Script to run pull down data for SF & LA earthquake event comparison."""

if __name__ == "__main__":
    import os
    import sys
    sys.path.append("../code")

    import usgs

    # obtain data for the greater San Francisco area, start of 1984 through August 24, 2014 in PST
    usgs.APIquery(starttime = "1984-01-01T07:00:00", endtime = "2014-08-25T07:00:00",
                  minmagnitude = "1.5",
                  latitude = "37.77", longitude = "-122.44",
                  minradiuskm = "0", maxradiuskm = "200",
                  reviewstatus = "reviewed",
                  filename = "usgsQuery_SF_84-14.csv",
                  format = "csv")

    # obtain data for the greater Los Angeles area, start of 1984 through August 24, 2014 in PST
    usgs.APIquery(starttime = "1984-01-01T07:00:00", endtime = "2014-08-25T07:00:00",
                  minmagnitude = "1.5",
                  latitude = "34.05", longitude = "-118.26",
                  minradiuskm = "0", maxradiuskm = "200",
                  reviewstatus = "reviewed",
                  filename = "usgsQuery_LA_84-14.csv",
                  format = "csv")
