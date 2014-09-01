usgs
====

## USGS Earthquake API python3 wrapper

#### Usage

To obtain earthquake events surrounding San Francisco (within 200 km) since 2013, minimum magnitude of 2.5, in geojson format:

```python
import code.usgs

usgs.APIquery(starttime = "2013-01-01", endtime = "",
              minmagnitude = "2.5",
              latitude = "37.77", longitude = "-122.44",
              minradiuskm = "0", maxradiuskm = "200",
              format = "geojson")
```

## USGS Earthquake Data Exploration

- See [exploration](https://github.com/abshinn/usgs/tree/master/exploration) for an example of USGS data exploration with R. 
- Results from the exploration are discussed [here](http://abshinn.github.io/r/2014/08/18/R-and-Quakes/) on [abshinn.github.io](http://abshinn.github.io).

## quakes Shell Command

Also within this repository is a shell script which uses curl to pull down the latest earthquakes from USGS's earthquake feed.

The simplest way to call the USGS feed is with the following curl command, which asks for earthquake events equal to or greater than 2.5 magnitude within the last 24 hours:

```bash
$ curl -s http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_day.csv
```

The script `code/quakes.sh` uses the above curl, but allows a few options such as `-s` for sorting by magnitude, and `-H` for showing earthquake events within the last hour. For help, use the `-h` option.

The script can be aliased within your respective shell profile such as `~/.bash_profile`, like so:

```bash
$ echo alias quakes="~/{wherever you cloned this repo}/usgs/code/quakes.sh" >> ~/.bash_profile
```

Then, whenever you would like to be up-to-date on earthquakes:

```bash
$ quakes -H
```
```
time                      latitude  longitude  depth  mag  place
2014-09-01T16:47:32.000Z  50.5447   -174.485   25.6   2.7  "184km S of Atka - Alaska"
```

Or, to see earthquake events that have occurred in California in the past 24 hours: 

```bash
$ quakes | grep California
```
```
2014-09-01T16:10:37.400Z  36.9793   -121.464   5.4     3.5  "9km ESE of Gilroy - California"
```
