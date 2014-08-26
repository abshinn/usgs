# California Earthquakes with R 

### Blog Post

As an example of how to use the Python USGS Earthquake API wrapper, I decided to do a bit of data exploration around major California earthquakes in the last 30 years. Specifically, I had a look at earthquakes within 200 km of San Francisco and Los Angeles.

Blog post: [*R and Quakes*](http://abshinn.github.io/r/2014/08/18/R-and-Quakes/)

### Using the USGS API with Python

To pull down the data using Python3, I first navigate to the usgs home directory, and call the APIquery with the desired parameters. All parameters are [defined here](http://comcat.cr.usgs.gov/fdsnws/event/1/) and an online query form can be [found here](http://earthquake.usgs.gov/earthquakes/search/).

For example the below script pulls down Earthquake event data from 1983 through 2012, within 200 km of San Francisco and Los Angeles. The `code` directory and this directory are both branches of the main repository, so I append the `code` directory to `sys.path` so it can find `../code/usgs.py`.

```python
import sys
sys.path.append("../code")

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
```

### Analysis in R

For analysis and plotting, I use R with the newly acquired earthquake data.

*See:* `quakes.R`

For the python script that pulls down the data, see `getquakes.py`. 

#### Plots Generated

![alt text](https://github.com/abshinn/usgs/blob/master/exploration/SF-LA_timeVmag.png "Magnitude over Time")
![alt text](https://github.com/abshinn/usgs/blob/master/exploration/SF-LA_yrVcount.png "Year Count")
![alt text](https://github.com/abshinn/usgs/blob/master/exploration/SF-LA_magVfreq.png "Magnitude versus Frequency")
