#!/usr/bin/env python3

import urllib.request, urllib.parse, time
#import pdb # DEBUG

class APIquery(object):
    """USGS Earthquake API Python3 Wrapper
    
    KEYWORD ARGUMENTS
        params** -- any USGS earthquake query paramter, for a list and
                    description of parameters, visit:
                        http://comcat.cr.usgs.gov/fdsnws/event/1/
                    for the USGS API web interface, go to:
                        http://earthquake.usgs.gov/earthquakes/search/
                        
    DEFAULT BEHAVIOR
        If query format is indicated as csv or text, a text file is
        written to disk, otherwise the result is returned with the
        call to usgs.APIquery()

    USAGE
        # obtain earthquake events surrounding San Francisco (within 
        # 200 km) since 2013, minimum magnitude of 2.5, in geojson format
        usgs.APIquery(starttime = "2013-01-01", endtime = "",
                      minmagnitude = "2.5",
                      latitude = "37.77", longitude = "-122.44",
                      minradiuskm = "0", maxradiuskm = "200",
                      format = "geojson")

    MODIFICATION
        Created by Adam Shinn, November 2013
    """

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

    def __init__(self, **params):
        for param in params.keys():
            if param in self.parameters.keys():
                self.parameters[param] = params[param]
            else:
                raise KeyError(param)
        self.result = self.query()
        if self.parameters["format"] == "csv" or self.parameters["format"] == "text":
            self.writeResult()
        else:
            self.returnResult()

    def query(self):
        """query USGS API at: http://comcat.cr.usgs.gov/fdsnws/event/1/query?"""
        url = "http://comcat.cr.usgs.gov/fdsnws/event/1/query?{}&".format(
                urllib.parse.urlencode(self.parameters,safe = "+:") )
        print("Querying USGS with: {}".format(url))
        with urllib.request.urlopen(url) as usgs:
            response = usgs.read() # binary string
        return response

    def returnResult(self):
        """return result from usgs.APIquery() call"""
        print("Returned in {} format, string of length {}".format(self.parameters["format"], len(self.result)))
        return self.result

    def writeResult(self):
        """write result from usgs.APIquery() call to text file"""
        filename = "usgsQuery_{}.{}".format(
                time.strftime("%Y-%m-%d_%H%M",time.localtime()), self.parameters["format"] )
        print("Writing results to: {}".format(filename))
        with open(filename, "wb") as btxt:
            btxt.write(self.result)

if __name__ == '__main__':
    print("USGS APIquery Example")
    APIquery(starttime = "2013-01-01", endtime = "",
             minmagnitude = "2.5",
             latitude = "37.77", longitude = "-122.44",
             minradiuskm = "0", maxradiuskm = "200",
             format = "geojson")
