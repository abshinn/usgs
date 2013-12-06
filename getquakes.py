#!/usr/bin/env python3

# PURPOSE
#   Provide simple python call to USGS earthquake API.
#
# DEFAULTS
#    start - "startdate" in the USGS query; set to beginning of 2013
#      end - "enddate" in the query; set to current time
#   minmag - "minmagnitude" in the query; set to 2.5
#  lat&lon - "latitude" and "longitude" in query; set to 37.44N 122.77W (San Francisco)
#   radius - "maxradius" in the query; set to 200km
#
# USAGE
#    usgsAPI(starttime = "2013-01-01", endtime = "",
#            minmagnitude = "2.5",
#            latitude = "37.77", longitude = "-122.44",
#            minradiuskm = "0", maxradiuskm = "200",
#            format = "geojson")
#
# MODIFICATION
#   - created November 2013 by Adam Shinn

import sys, urllib.request, urllib.parse, re, time
#import pdb

parameters = { "starttime": "",
                 "endtime": "",
             "updateafter": "",
           # rectangular box
             "minlatitude": "", 
             "maxlatitude": "",
            "minlongitude": "",
            "maxlongitude": "",
           # circle
                "latitude": "",
               "longitude": "",
               "minradius": "",
             "minradiuskm": "",
               "maxradius": "",
             "maxradiuskm": "",
           # other
                "mindepth": "",
                "maxdepth": "",
            "minmagnitude": "",
            "maxmagnitude": "",
       "includeallorigins": "",
    "includeallmagnitudes": "",
         "includearrivals": "",
           "includedelete": "",
                 "eventid": "",
                   "limit": "",
                  "offset": "",
                 "orderby": "", #time, time-asc, magnitude, magnitude-asc
                 "catalog": "",
             "contributor": "",
           # extensions
                  "format": "", #quakeml, csv, geojson, kml, xml, text
               "eventtype": "", #earthquake will limit non-earthquake events
            "reviewstatus": "",
                  "minmmi": "",
                  "maxmmi": "",
                  "mincdi": "",
                  "maxcdi": "",
                 "minfelt": "",
              "alertlevel": "",
                  "mingap": "",
                  "maxgap": "",
                  "maxsig": "",
             "producttype": ""}

class usgsAPI(object):
    def __init__(self, **params):
        self.parameters = parameters
        for param in params.keys():
            if param in self.parameters.keys():
                self.parameters[param] = params[param]
            else:
                raise KeyError(param)

        # USGS API Query
        # The documentation for this API can be found at:
        #   http://comcat.cr.usgs.gov/fdsnws/event/1/
        url = "http://comcat.cr.usgs.gov/fdsnws/event/1/query?{}&".format(
                urllib.parse.urlencode(self.parameters,safe = "+:") )
        
        print("Querying USGS with: {}".format(url))
        with urllib.request.urlopen(url) as usgs:
            response = usgs.read() # binary string

        # write the url response to a csv file
        filename = "quake_last3decades.{}".format(self.parameters['format'])
        print("Writing results to: {}".format(filename))
        with open(filename, "wb") as btxt:
            btxt.write(response)

if __name__ == '__main__':
    usgsAPI(starttime = "2013-01-01", endtime = "",
            minmagnitude = "2.5",
            latitude = "37.77", longitude = "-122.44",
            minradiuskm = "0", maxradiuskm = "200",
            format = "geojson")
