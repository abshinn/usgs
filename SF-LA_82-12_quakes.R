# USGS DATA EXPLORATION
#   Data exploration with R
#
#   These data are obtained using the USGS API through a python wrapper, the following parameters
#   were used:
#            startdate = 1982-01-01 00:00:00
#              enddate = 2013-01-01 00:00:00
#             latitude =   37.77;   34.05  #  SF; LA
#            longitude = -122.44; -118.26  #  SF; LA
#         minmagnitude = 0.1 # so not to include 0
#          maxradiuskm = 200
#         reviewstatus = reviewed
#               format = csv

# run usgsAPI python script, see above for parameter specifics
    system('./usgs.py')

# read data into data frame
    SFquakes = read.csv('usgsQuery_SF_83-12.csv', header = TRUE, stringsAsFactors = FALSE)
    LAquakes = read.csv('usgsQuery_LA_83-12.csv', header = TRUE, stringsAsFactors = FALSE)

# create columns containing the name of the area, and combine into one data frame for convenience
    SFquakes$area = "SF"
    LAquakes$area = "LA"
    quakes = rbind(SFquakes, LAquakes)


#
# DATA SCRUBBING
#

# remove columns with all NA values
    quakes = quakes[,-7:-10]

# remove events where magnitude is equal to NA
    quakes = quakes[-which(is.na(quakes$mag)),]

# create column with R's time object
    quakes$ptime = as.POSIXlt(strptime(quakes$time, "%Y-%m-%dT%T"))

# it turns out that there is one measurement with the mwb meathod, and it double counts 
#    quakes = quakes[-which(quakes$magType == "mwb"),]

# create columns with year bins
    quakes$yearbins = strftime(cut(quakes$ptime, "year", right = F), "%Y")

# create columns with half and whole magnitude bins
    quakes$Mhalfbins = cut(quakes$mag, seq(2.0,7.5,.5), right = F)
    quakes$Mwholebins = cut(quakes$mag, seq(2.0,8.0,1), right = F)

# create a column with varied magnitude bins, neccesary if plotting without a log scale
    quakes$Mvariedbins = cut(quakes$mag, c(2.0,2.5,3.0,3.5,4.0,5.0,7.5), right = F)

# calculate energy based on earthquake magnitude
#     equation: E[m] = 10^(1.5*m + 4.8) # yields Energy in Joules
#          and: one TNT exploded undground is equivalent to about 4.184e9 Joules
    quakes$Ejoules = 10^(1.5*quakes$mag + 4.8) # units of Joules
    quakes$Etnt = quakes$Ejoules/4.184e9       # units of kilotonnes, TNT

# calculate distance from center of major city by converting latitude and latitude from polar coordinates
# to cartesean, and using the distance formula
    Rearth = (6378 + 6356)/2.0 # average polar and equitorial radii for approximate radius, units in km
    latrad = 2*pi*quakes$latitude/360  # units of radians
    lonrad = 2*pi*quakes$longitude/360 # units of radians
    xyz = cbind( Rearth*sin(latrad)*cos(lonrad), # earthquake event cartesean position Nx3 matrix
                 Rearth*sin(latrad)*sin(lonrad), #   units: km
                 Rearth*cos(latrad) )
    SFrad = list("lat" = 2*pi*37.77/360, "lon" = 2*pi*-122.44/360)
    SFxyz = cbind( Rearth*sin(SFrad$lat)*cos(SFrad$lon), # San Francisco cartesean coordinates in 1x3 vector
                   Rearth*sin(SFrad$lat)*sin(SFrad$lon), #   units: km
                   Rearth*cos(SFrad$lat) )
    # prepare SFxyz as Nx3 martix for matrix arithmetic, where N = number of SF events
    SFxyz = matrix(SFxyz, nrow = nrow(quakes[quakes$area == "SF",]), ncol = 3, byrow = TRUE)
    SFdiff = (xyz[quakes$area == "SF",] - SFxyz)
    LArad = list("lat" = 2*pi*34.05/360, "lon" = 2*pi*-118.26/360)
    LAxyz = cbind( Rearth*sin(LArad$lat)*cos(LArad$lon), # Los Angeles cartesean coordinates in 1x3 vector
                   Rearth*sin(LArad$lat)*sin(LArad$lon), #   units: km
                   Rearth*cos(LArad$lat) )
    # prepare LAxyz as Nx3 martix for matrix arithmetic, where N = number of LA events
    LAxyz = matrix(LAxyz, nrow = nrow(quakes[quakes$area == "LA",]), ncol = 3, byrow = TRUE)
    LAdiff = (xyz[quakes$area == "LA",] - LAxyz)
    quakes$dist = NA # initialize distance column in quakes data frame
    quakes$dist[quakes$area == "SF"] = sqrt(apply(SFdiff*SFdiff, 1, sum))
    quakes$dist[quakes$area == "LA"] = sqrt(apply(LAdiff*LAdiff, 1, sum))

# TODO
# try doing same calculation by calculating the arc between the two lat/lon coordinates

#
# Cursory exploraton
#

# what were the largest quakes?
    quakes = quakes[order(quakes$mag, decreasing = TRUE),] # sort by magnitude

    print("LARGEST QUAKES")
    print(quakes[quakes$mag >= 6.0,c("ptime", "mag", "area", "Etnt", "dist")])
    # Result:
    #                    ptime mag area       Etnt      dist
    # 5270 1992-06-28 11:57:38 7.3   LA 1344028.02 108.72365  <-- Landers
    # 892  1989-10-18 00:04:16 6.9   SF  337604.58  86.18342  <-- Loma Prieta
    # 6504 1994-01-17 12:30:55 6.7   LA  169203.10  22.88980  <-- Northridge
    # 5282 1992-06-28 15:05:33 6.5   LA   84802.44  93.89301  <-- related to Landers
    # 115  1984-04-24 21:15:20 6.1   SF   21301.41  71.59790  <-- Morgan Hill
    # 5237 1992-04-23 04:50:23 6.1   LA   21301.41 110.10355  <-- Joshua Tree, preceeded Landers
    #
    # Discussion:
    #    As expected, the biggest earthquakes in California's recent history pop out of the data set.
    #    The Landers earthquake had an (underground) explosive force of 1.3 megatonnes of TNT, while 
    #    the Loma Prieta had about 340 kilotonnes of explosive force.
    #    Interestingly, the location of these earthquakes are a huge factor to their destructive power,
    #    the Landers quake was about 109 km away in the Mojave desert and didn't cause nearly as much
    #    damage to the LA metro area as the Northridge quake 22 km away, and about 4.0 (10^.6) times less 
    #    powerful.

# which major city was most affected by earthquakes?
    print("MEAN distance, magnitude, and Energy in kilotonnes")
    print(aggregate(data = quakes, cbind(dist, mag, Etnt) ~ area, mean))
    # Result:
    #    area     dist      mag      Etnt
    #  1   LA 80.78188 3.074504 308.16626
    #  2   SF 98.11080 2.954712  89.93179
    #
    # Discussion:
    #    On average, for the last 31 years, SF events seem to happen about 10% further than around LA;
    #    the earthquakes around LA are about .12 in magnitude more severe, or 1.3 (10^.12) times more
    #    severe; and the earthquakes around LA have had about 344% more explosive force than around SF.

# what is the combined yearly mean distance, magnitude, and energy?
    aggregate(data = quakes, cbind(dist, mag, Etnt) ~ yearbins, mean)
    # Result:
    #     yearbins      dist      mag         Etnt
    #  1      1982  93.15950 3.264885    5.7472692
    #  2      1983  83.31311 3.249351    3.4959748
    #  3      1984  86.29367 3.336066  128.6009299
    #  4      1985  94.09149 3.090323    8.2884103
    #  5      1986 100.65188 3.187845   60.9108753
    #  6      1987  75.82107 3.100000   31.1957782
    #  7      1988  94.76313 3.145217   14.8301755
    #  8      1989  85.86780 3.235891  848.2279505
    #  9      1990  91.12053 3.066201   24.9439241
    #  10     1991  89.89959 3.001382   27.3745578
    #  11     1992 109.14567 3.257696 1321.4610828
    #  12     1993 100.96255 2.986047    2.6543001
    #  13     1994  52.15689 3.161694  178.5699951
    #  14     1995  98.10505 3.094098    3.5495913
    #  15     1996  95.77659 3.120812    4.4104884
    #  16     1997  92.42586 3.160784    6.3721943
    #  17     1998  96.53752 3.112335    7.1156948
    #  18     1999 103.51849 3.161502    3.0994531
    #  19     2000  92.24905 3.129167    7.1887467
    #  20     2001 102.93127 3.164679    8.6260385
    #  21     2002  87.13736 3.063243    4.7872511
    #  22     2003  96.08838 3.117012    7.0513544
    #  23     2004  95.92813 3.100000    6.6613839
    #  24     2005  98.88026 3.131606   13.9743310
    #  25     2006  91.88851 3.041975    4.1241082
    #  26     2007  86.74442 2.998544   22.4215377
    #  27     2008  91.93543 2.892193   11.3023367
    #  28     2009  77.73185 2.602614    1.7107952
    #  29     2010  80.67209 2.493587    0.9741442
    #  30     2011  80.14414 2.560538    1.3208688
    #  31     2012  82.59109 2.497595    1.1432444
    #
    # Discussion:
    #    Due to the exponential nature of the data, the Etnt column seems to be an
    #    excellent indicator for major events in any given year. Interestingly, the
    #    average magnitude has decreased in recent years. I imagine this is due to
    #    an increase in detection efficiency.

# 3.5
# what is the magnitude-frequency distribution for the two areas of interest?
    freqSF = as.data.frame(table(quakes[quakes$area == "SF","Mhalfbins"]))
    names(freqSF) = c("magSF", "freqSF")
    freqLA = as.data.frame(table(quakes[quakes$area == "LA","Mhalfbins"]))
    names(freqLA) = c("magLA", "freqLA")

    print("EVENT FREQUENCY")
    print(cbind(freqSF, freqLA))
    # Result:
    #          magSF freqSF   magLA freqLA
    #     1  [2,2.5)    462 [2,2.5)    418
    #     2  [2.5,3)   1662 [2.5,3)   1817
    #     3  [3,3.5)   1423 [3,3.5)   2095
    #     4  [3.5,4)    448 [3.5,4)    764
    #     5  [4,4.5)    165 [4,4.5)    264
    #     6  [4.5,5)     40 [4.5,5)     60
    #     7  [5,5.5)      9 [5,5.5)     25
    #     8  [5.5,6)      2 [5.5,6)      8
    #     9  [6,6.5)      1 [6,6.5)      1
    #     10 [6.5,7)      1 [6.5,7)      2
    #     11 [7,7.5)      0 [7,7.5)      1
    #
    # Note: the units for frequency are in Event Counts per 31 years.
    # Discussion:
    #    Admittedly, I am not an expert in seismology. However, my educated guess would be that 
    #    this magnitude-frequency should follow a power-law where at one end, as the magnitude
    #    approaches zero, the frequency increases exponentially, and at the other end, as the
    #    magnitude exceeds 10+ the frequency diminishes to almost 0. The fact that the frequency
    #    distribution peaks between [3,3.5) and falls off as the magnitude approaches 0, given my
    #    educated guess, suggests that the detection efficiency (exponentially) decreases as it
    #    approaches 0. 
    #    This correlation will be discussed with figure 4.3.



#
#   Plots
#      - time vs. magnitude
#      - year vs. event count
#      - magnitude-frequency correlation

    # load ggplot2, and scales packages for log tick marks
    library("ggplot2")
    library("scales")

    # time vs. magnitude
    tiff("SF-LA_timeVmag.tiff", width = 900, height = 700)
    timeVmag = ggplot(na.omit(quakes), aes(ptime, mag)) +
               geom_point(aes(size = mag, color = dist)) +
               ggtitle("SF and LA Earthquakes, 1982-2012, Fig. 4.1") +
               xlab("time") +
               ylab("earthquake magnitude") + 
               guides(size = guide_legend(title = "magnitude")) +
               guides(color = guide_legend(title = "distance [km]")) +
               scale_color_gradient(low = "red", high = "dark gray") +
               theme_grey(base_size = 12) +
               facet_wrap(~ area, ncol = 1)
    dev.off()
    # Discussion:
    #    Initially, I expected distance to be random, but that is not the case for major events
    #    becuase aftershocks happen near to the major event. The major earthquakes that pop out 
    #    in this plot are, of course, those that were discussed in 3.2: Landers in 1992, Loma
    #    Prieta in 1989, and Northridge at the beginning of 1994. What's also interesting is the
    #    amount of aftershocks and related earthquakes for the major Los Angeles area earthquakes.
    #    Finally, another interesting aspect of this plot is the increased detection efficiency of
    #    2 to 2.5 magnitude earthquakes in recent years.
               
    #  binned year vs. event count
    tiff("SF-LA_yrVcount.tiff", width = 900, height = 700)
    yrVcount = ggplot(na.omit(quakes), aes(yearbins)) +
               geom_bar(aes(fill = Mvariedbins), color = "black") +
               ggtitle("SF and LA Earthquakes, 1982-2012, Fig. 4.2") +
               xlab("year") +
               ylab("event count") + 
               guides(fill = guide_legend(title = "magnitude")) +
               scale_y_log10(breaks = trans_breaks("log10", function(x) 10^x),
                             labels = trans_format("log10", math_format(10^.x))) +
               scale_fill_brewer(palette = 'BuPu') + 
               scale_x_discrete("year", breaks = c(as.character(seq(1985,2010,5)))) +
               theme_grey(base_size = 12) +
               facet_wrap(~ area, ncol = 1)
    dev.off()
    # Discussion:
    #    This is a cleaner way of looking at the magnitude size distribution per year. This
    #    plot also shows the increased detection efficiency for low-magnitude earthquakes in
    #    recent years. Also, it is interesting how the major LA earthquakes seemingly increased
    #    the events per year by about 10^4.

    # magnitude-frequency correlation
    freq = as.data.frame(table(quakes[quakes$mag >= 2.0,c("area","mag")]))
    freq = freq[order(freq$area),]
    freq[freq$Freq == 0.0,] = NA # bins with zero counts cause log plot issues
    tiff("SF-LA_yrVcount.tiff", width = 900, height = 700)
    magVfreq = ggplot(na.omit(freq), aes(mag, Freq)) +
               geom_point(aes(color = area)) + 
               ggtitle("SF and LA Earthquakes, 1982-2012, Fig. 4.3") + 
               ylab("frequency [event count per 31 years]") + 
               scale_y_log10(breaks = trans_breaks("log10", function(x) 10^x),
                             labels = trans_format("log10", math_format(10^.x))) +
               scale_x_discrete("magnitude", breaks = seq(2,7.5,.5)) + 
               geom_smooth(method = "loess", aes(group = 1), color = "black") +
               theme_grey(base_size = 12)
    dev.off()
    # Discussion:
    #    Not suprisingly, the correlation between magnitude and frequency for most of the richter
    #    scale has a slope of about 10^1 events over one order of magnitude. Also, as expected, when
    #    the magnitude increases, the spread of the data increases due to the insufficient amount of
    #    counts. As mentioned in section, I am not certain, but I believe the decreasing amount of 
    #    counts from magnitude 3.0 to 2.0 is due to detection efficiency of low-magnitude earthquakes,
    #    and theoretically, should increase as the magnitude approaches 0.


library("RgoogleMaps")
    bb <- qbbox(quakes$latitude, quakes$longitude)
    # zoomlevel 4 works for my data (US only) 
    zoomlevel <- 4
    # grab the map
    map <- GetMap.bbox(bb$lonR, bb$latR,zoom=zoomlevel,maptype="mobile")
    # plot the points as circles 
    PlotOnStaticMap(map,lon=quakes$longitude,lat=quakes$latitude,col="blue",verbose=0)
