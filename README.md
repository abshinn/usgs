usgs
====

USGS earthquake API python3 wrapper

### Usage

To obtain earthquake events surrounding San Francisco (within 200 km) since 2013, minimum magnitude of 2.5, in geojson format:

```python
import code.usgs

usgs.APIquery(starttime = "2013-01-01", endtime = "",
              minmagnitude = "2.5",
              latitude = "37.77", longitude = "-122.44",
              minradiuskm = "0", maxradiuskm = "200",
              format = "geojson")
```

USGS Earthquake Data Exploration
- See exploration/quakes.R for an example of USGS data exploration using R. 
