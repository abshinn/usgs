#!/usr/bin/env python3 -B -tt
"""Script to run pull down data for SF & LA earthquake event comparison."""

if __name__ == "__main__":
    import os
    import sys
    sys.path.append("../code")

    import usgs

    # obtain data for the greater San Francisco area, 1983 through 2012
    usgs.APIquery(starttime = "1984-08-25", endtime = "2013-08-25",
                  minmagnitude = "0.1",
                  latitude = "37.77", longitude = "-122.44",
                  minradiuskm = "0", maxradiuskm = "200",
                  reviewstatus = "reviewed",
                  filename = "usgsQuery_SF_84-14.csv",
                  format = "csv")

    # obtain data for the greater Los Angeles area, 1983 through 2012
    usgs.APIquery(starttime = "1984-08-25", endtime = "2013-08-25",
                  minmagnitude = "0.1",
                  latitude = "34.05", longitude = "-118.26",
                  minradiuskm = "0", maxradiuskm = "200",
                  reviewstatus = "reviewed",
                  filename = "usgsQuery_LA_84-14.csv",
                  format = "csv")
