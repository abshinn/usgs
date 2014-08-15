# California Earthquakes with R 

### Fetching the data 

As an example of how to use the Python USGS Earthquake API wrapper, I decided to do a bit of data exploration around major California earthquakes in the last 30 years. Specifically, I will look at earthquakes within 200 km of San Francisco and Los Angeles.

To pull down the data using Python3, I first navigate to the usgs home directory, and call the APIquery with the desired parameters. All parameters are [defined here](http://comcat.cr.usgs.gov/fdsnws/event/1/) and an online query form can be [found here](http://earthquake.usgs.gov/earthquakes/search/).

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

Switching over to use R, I then read the CSVs into dataframes. For convenience, I define an area label and combine the dataframes into one.

```R
SFquakes = read.csv('usgsQuery_SF_83-12.csv', header = TRUE, stringsAsFactors = FALSE)
LAquakes = read.csv('usgsQuery_LA_83-12.csv', header = TRUE, stringsAsFactors = FALSE)
SFquakes$area = "SF"
LAquakes$area = "LA"
quakes = rbind(SFquakes, LAquakes)
```

### Data scrubbing

```R
# remove columns with all NA values
quakes = quakes[,-7:-10]

# create column with time object
quakes$ptime = as.POSIXlt(strptime(quakes$time, "%Y-%m-%dT%T"))

# remove instances of mwb, an alternative form of magnitude measurement
quakes = quakes[-which(quakes$magType == "mwb"),]

# create columns with year bins
quakes$yearbins = strftime(cut(quakes$ptime, "year", right = F), "%Y")

# create columns with half and whole magnitude bins
quakes$Mhalfbins = cut(quakes$mag, seq(2.0,7.5,.5), right = F)
quakes$Mwholebins = cut(quakes$mag, seq(2.0,8.0,1), right = F)

# create a column with varied magnitude bins, necessary if plotting without a log scale
quakes$Mvariedbins = cut(quakes$mag, c(2.0,2.5,3.0,3.5,4.0,5.0,7.5), right = F)
```

### Magnitude-energy conversion

One way to comprehend the destructive force of earthquakes is to convert from earthquake magnitude to a more imaginative unit of energy: the ton of TNT. To do this conversion, we need to be able to convert from magnitude to energy, perhaps with the help of Beno and Charles. Also, it is useful to know that one ton of TNT is equivalent to about 4.184e9 Joules.

The [Gutenberg and Richter](https://www2.bc.edu/john-ebel/GutenberRichterMagnitude.pdf) energy-magnitude relation (in Joules):

> E[M] = 10^(1.5\*M + 4.8)

```R
quakes$Ejoules = 10^(1.5*quakes$mag + 4.8) # units of Joules
quakes$Etnt = quakes$Ejoules/4.184e9       # units of kilotonnes, TNT
```

### Calculate distance from epicenter to city center

```R
# calculate distance from center of major city by converting latitude and latitude from polar coordinates
# to cartesian, and using the distance formula
Rearth = (6378 + 6356)/2.0 # average polar and equatorial radii for approximate radius, units in km
latrad = 2*pi*quakes$latitude/360  # units of radians
lonrad = 2*pi*quakes$longitude/360 # units of radians
xyz = cbind( Rearth*sin(latrad)*cos(lonrad), # earthquake event cartesian position Nx3 matrix
             Rearth*sin(latrad)*sin(lonrad), #   units: km
             Rearth*cos(latrad) )
SFrad = list("lat" = 2*pi*37.77/360, "lon" = 2*pi*-122.44/360)
SFxyz = cbind( Rearth*sin(SFrad$lat)*cos(SFrad$lon), # San Francisco cartesian coordinates in 1x3 vector
               Rearth*sin(SFrad$lat)*sin(SFrad$lon), #   units: km
               Rearth*cos(SFrad$lat) )
# prepare SFxyz as Nx3 martix for matrix arithmetic, where N = number of SF events
SFxyz = matrix(SFxyz, nrow = nrow(quakes[quakes$area == "SF",]), ncol = 3, byrow = TRUE)
SFdiff = (xyz[quakes$area == "SF",] - SFxyz)
LArad = list("lat" = 2*pi*34.05/360, "lon" = 2*pi*-118.26/360)
LAxyz = cbind( Rearth*sin(LArad$lat)*cos(LArad$lon), # Los Angeles cartesian coordinates in 1x3 vector
               Rearth*sin(LArad$lat)*sin(LArad$lon), #   units: km
               Rearth*cos(LArad$lat) )
# prepare LAxyz as Nx3 martix for matrix arithmetic, where N = number of LA events
LAxyz = matrix(LAxyz, nrow = nrow(quakes[quakes$area == "LA",]), ncol = 3, byrow = TRUE)
LAdiff = (xyz[quakes$area == "LA",] - LAxyz)
quakes$dist = NA # initialize distance column in quakes data frame
quakes$dist[quakes$area == "SF"] = sqrt(apply(SFdiff*SFdiff, 1, sum))
quakes$dist[quakes$area == "LA"] = sqrt(apply(LAdiff*LAdiff, 1, sum))
```

## Questions

### What were the largest quakes?

```R
quakes = quakes[order(quakes$mag, decreasing = TRUE),] # sort by magnitude
print(quakes[quakes$mag >= 6.0,c("ptime", "mag", "area", "Etnt", "dist")])
```

*_Output (with annotation):_*

```R
                    ptime mag area       Etnt      dist
10599 1992-06-28 11:57:38 7.3   LA 1344028.02 108.72365 <-- Landers
7349  1999-10-16 09:46:46 7.2   LA  951498.97 125.37017 <-- Hector Mine
3705  1989-10-18 00:04:16 6.9   SF  337604.58  86.18342 <-- Loma Prieta
9184  1994-01-17 12:30:55 6.7   LA  169203.10  22.88980 <-- Northridge
10587 1992-06-28 15:05:33 6.5   LA   84802.44  93.89301 <-- related to Landers
4538  1984-04-24 21:15:20 6.1   SF   21301.41  71.59790 <-- Morgan Hill
10869 1992-04-23 04:50:23 6.1   LA   21301.41 110.10355 <-- Joshua Tree, preceeded Landers
```

The Landers earthquake had an explosive force of 1.3 megatonnes of TNT, while the Loma Prieta had about 340 kilotonnes of explosive force. Interestingly, the location of these earthquakes are a huge factor to their destructive power, the Landers quake was about 109 km away in the Mojave desert and did not cause nearly as much damage to the LA metro area as the Northridge quake 22 km away, and about 4.0 (10^.6) times less powerful.

### Which city was most affected by earthquakes?

```R
# Mean distance, magnitude, and Energy in TNT
print(aggregate(data = quakes, cbind(dist, mag, Etnt) ~ area, mean))
```

*_Output:_*

```R
  area     dist      mag      Etnt
1   LA  96.97176 3.104314 368.69829
2   SF 103.93985 2.959269  84.71983
```

The question of which city has been more affected is more complex than a simple calculation of the 30-year mean of distance and magnitude. However, on average, the earthquakes surrounding LA have been about 10% closer, 1.4 (10^.15) times more severe in magnitude, and with over 4 times more explosive force than Bay Area earthquakes.

### What is the combined yearly mean distance, magnitude, and energy?

```R
# yearly averages
print(aggregate(data = quakes, cbind(dist, mag, Etnt) ~ yearbins, mean))
```

*_Output:_*

```R
    yearbins      dist      mag        Etnt
 1      1983 110.42223 3.292727    4.506520
 2      1984  91.83969 3.351741  118.236847
 3      1985 103.25207 3.106047    7.779889
 4      1986 104.19157 3.196345   57.913989
 5      1987  84.14808 3.090076   28.177762
 6      1988 103.51438 3.134848   14.505230
 7      1989  89.93265 3.223005  804.548631
 8      1990  95.09126 3.072021   23.281553
 9      1991  99.12376 3.020319   24.002774
 10     1992 114.22599 3.236533  982.619831
 11     1993 106.61878 2.986907    2.706447
 12     1994  57.93635 3.157971  168.194017
 13     1995 121.07506 3.124582   17.246275
 14     1996 113.05173 3.138735    6.002731
 15     1997 100.18213 3.156890    6.668820
 16     1998 101.29559 3.114228    6.726535
 17     1999 130.72798 3.256908 1310.867030
 18     2000 122.30836 3.105828    4.814266
 19     2001 117.22567 3.147203    7.012212
 20     2002 101.02247 3.076856    4.366177
 21     2003 104.42577 3.115162    6.349083
 22     2004 103.80259 3.097368    8.930705
 23     2005 104.87369 3.138785   13.896986
 24     2006 107.67465 3.050495    3.925653
 25     2007 101.79036 3.046964   19.888577
 26     2008  99.01679 2.963265   12.969126
 27     2009  83.34869 2.678468    3.110633
 28     2010  88.89121 2.525352    1.134227
 29     2011  86.99431 2.606379    1.477807
 30     2012  90.10570 2.533573    1.094880
```

Due to the exponential nature of the data, the Etnt feature is a clear indicator for seismologically active years. Also, it appears we are seeing increased detection efficiency in the last few years with the average magnitude decreasing.


### What is the magnitude-frequency distribution for the two areas of interest?

```R
freqSF = as.data.frame(table(quakes[quakes$area == "SF","Mhalfbins"]))
names(freqSF) = c("magSF", "freqSF")
freqLA = as.data.frame(table(quakes[quakes$area == "LA","Mhalfbins"]))
names(freqLA) = c("magLA", "freqLA")

# event frequency
print(cbind(freqSF, freqLA))
```

*_Output:_*

```R
     magSF freqSF   magLA freqLA
1  [2,2.5)    476 [2,2.5)    444
2  [2.5,3)   1838 [2.5,3)   2383
3  [3,3.5)   1505 [3,3.5)   2813
4  [3.5,4)    455 [3.5,4)   1045
5  [4,4.5)    173 [4,4.5)    360
6  [4.5,5)     42 [4.5,5)     84
7  [5,5.5)      9 [5,5.5)     34
8  [5.5,6)      2 [5.5,6)     10
9  [6,6.5)      1 [6,6.5)      1
10 [6.5,7)      1 [6.5,7)      2
11 [7,7.5)      0 [7,7.5)      2
```

Note: the units for frequency are in Event Counts per 30 years.

I am not an expert in seismology. However, my guess would be that this magnitude-frequency should theoretically follow a power-law where at one end, as the magnitude approaches zero, the frequency increases exponentially, and at the other end, as the magnitude exceeds 10 the frequency diminishes to almost 0. The fact that the frequency distribution peaks between [3,3.5) and falls off as the magnitude approaches 0, given my uneducated guess, suggests that the detection efficiency (exponentially) decreases as it approaches 0. See plot magVfreq below.

## Plots

Time for some plots. Let's have a look at the following correlations:

- time vs. magnitude
- year vs. event count
- magnitude-frequency correlation

Load ggplot. The "scales" package is necessary for log tick marks.

```R
library("ggplot2")
library("scales")
```

### time vs. magnitude

```R
png("SF-LA_timeVmag.png", width = 1000, height = 800)
timeVmag = ggplot(na.omit(quakes), aes(ptime, mag)) +
           geom_point(aes(size = mag, color = dist)) +
           ggtitle("SF and LA Earthquakes, 1983-2012") +
           xlab("time") +
           ylab("earthquake magnitude") + 
           guides(size = guide_legend(title = "magnitude")) +
           guides(color = guide_legend(title = "distance [km]")) +
           scale_color_gradient(low = "red", high = "dark gray") +
           theme_grey(base_size = 12) +
           theme(text = element_text(size = 22)) +
           facet_wrap(~ area, ncol = 1)
print(timeVmag)
dev.off()
```

*_Output:_*

![alt text](https://github.com/abshinn/usgs/blob/master/exploration/SF-LA_timeVmag.png "Magnitude over Time")

The major earthquakes that pop out in this plot are: Landers in 1992, Loma Prieta in 1989, and Northridge at the beginning of 1994. What is also interesting is the amount of aftershocks and related earthquakes for the major Los Angeles area earthquakes. Another interesting aspect of this plot is the increased detection efficiency of 2 to 2.5 magnitude earthquakes since 2009. Perhaps this is due to the [Quake-Catcher Network (QCN)](http://qcn.stanford.edu/wp-content/uploads/2011/10/2009-Cochran_et_al_IEEE_QCN_smaller.pdf)?

### year vs. event count

```R
png("SF-LA_yrVcount.png", width = 1000, height = 800)
yrVcount = ggplot(na.omit(quakes), aes(yearbins)) +
           geom_bar(aes(fill = Mvariedbins), color = "black") +
           ggtitle("SF and LA Earthquakes, 1983-2012") +
           xlab("year") +
           ylab("event count") + 
           guides(fill = guide_legend(title = "magnitude")) +
           scale_y_log10(breaks = trans_breaks("log10", function(x) 10^x),
                         labels = trans_format("log10", math_format(10^.x))) +
           scale_fill_brewer(palette = 'BuPu') + 
           scale_x_discrete("year", breaks = c(as.character(seq(1985,2010,5)))) +
           theme_grey(base_size = 12) +
           theme(text = element_text(size = 22)) +
           facet_wrap(~ area, ncol = 1)
print(yrVcount)
dev.off()
```

*_Output:_*

![alt text](https://github.com/abshinn/usgs/blob/master/exploration/SF-LA_yrVcount.png "Year Count")

This is a cleaner way of looking at the magnitude size distribution per year. This plot also shows the increased detection efficiency for low-magnitude earthquakes in recent years. Also, it is interesting how the major LA earthquakes seemingly increased the events per year by about 10^4.

### magnitude-frequency correlation

```R
freq = as.data.frame(table(quakes[quakes$mag >= 2.0,c("area","mag")]))
freq = freq[order(freq$area),]
freq[freq$Freq == 0.0,] = NA # bins with zero counts cause log plot issues
png("SF-LA_magVfreq.png", width = 1000, height = 800)
magVfreq = ggplot(na.omit(freq), aes(mag, Freq)) +
           geom_point(aes(color = area), size = 4) + 
           ggtitle("SF and LA Earthquakes, 1983-2012") + 
           ylab("frequency [event count per 31 years]") + 
           scale_y_log10(breaks = trans_breaks("log10", function(x) 10^x),
                         labels = trans_format("log10", math_format(10^.x))) +
           scale_x_discrete("magnitude", breaks = seq(2,7.5,.5)) + 
           geom_smooth(method = "loess", aes(group = 1), color = "black") +
           theme_grey(base_size = 12) + 
           theme(text = element_text(size = 22))
print(magVfreq)
dev.off()
```

*_Output:_*

![alt text](https://github.com/abshinn/usgs/blob/master/exploration/SF-LA_magVfreq.png "Magnitude versus Frequency")

The correlation between magnitude and frequency for most of the Richter scale has a slope of about 10^1 events over one order of magnitude. Also, as expected, when the magnitude increases, the spread of the data increases due to the insufficient amount of counts. As mentioned in the above section, I am not certain, but I believe the decreasing amount of event counts from magnitude 3.0 to 2.0 is due to detection efficiency of low-magnitude earthquakes, and theoretically, should increase as the magnitude approaches 0.
