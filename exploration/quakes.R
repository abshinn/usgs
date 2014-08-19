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
#
# USAGE
#   This script can be run in an interactive R session:
#     > source("quakes.R")

# run python script that pulls down the data, see above for parameter specifics
# (only needs to be run once)
#    system('./getquakes.py')

# read data into data frame
SFquakes = read.csv('usgsQuery_SF_83-12.csv', header = TRUE, stringsAsFactors = FALSE)
LAquakes = read.csv('usgsQuery_LA_83-12.csv', header = TRUE, stringsAsFactors = FALSE)

# create columns containing the name of the area, and combine into one data frame for convenience
SFquakes$area = "SF"
LAquakes$area = "LA"
quakes = rbind(SFquakes, LAquakes)

#
# DATA SCRUBBING/PREP
#

# remove columns with all NA values
quakes = quakes[,-7:-10]

# create column with R's time object
quakes$ptime = as.POSIXlt(strptime(quakes$time, "%Y-%m-%dT%T"))

# the Northridge quake is counted twice due to an alternate method of measurement, "mwb"
quakes = quakes[-which(quakes$magType == "mwb"),]

# create columns with year bins
quakes$yearbins = strftime(cut(quakes$ptime, "year", right = F), "%Y")

# create columns with half and whole magnitude bins
quakes$Mhalfbins = cut(quakes$mag, seq(2.0,7.5,.5), right = F)
quakes$Mwholebins = cut(quakes$mag, seq(2.0,8.0,1), right = F)

# create a column with varied magnitude bins, necessary if plotting without a log scale
quakes$Mvariedbins = cut(quakes$mag, c(2.0,2.5,3.0,3.5,4.0,5.0,7.5), right = F)

# calculate energy based on earthquake magnitude
#     equation: E[m] = 10^(1.5*m + 4.8) # yields Energy in Joules
#          and: one TNT exploded underground is equivalent to about 4.184e9 Joules
quakes$Ejoules = 10^(1.5*quakes$mag + 4.8) # units of Joules
quakes$Etnt = quakes$Ejoules/4.184e9       # units of kilotonnes, TNT

# ignore the fact that the earth is an oblate spheroid
Rearth = 6371 

# approximate city centroids
quakes$area_lon = 0
quakes$area_lon[quakes$area == "SF"] = -122.44
quakes$area_lon[quakes$area == "LA"] = -118.26
quakes$area_lat = 0
quakes$area_lat[quakes$area == "SF"] = 37.77
quakes$area_lat[quakes$area == "LA"] = 34.05

# Planar Approximation
x = (quakes$longitude - quakes$area_lon)*cos(pi*quakes$area_lat/180)*pi/180
y = (quakes$latitude  - quakes$area_lat)*pi/180
quakes$d_planar = Rearth * sqrt(x^2 + y^2)

# Haversine formula
lat1 = quakes$area_lat*pi/180
lat2 = quakes$latitude*pi/180
dlat = (quakes$area_lat - quakes$latitude)*pi/180
dlon = (quakes$area_lon - quakes$longitude)*pi/180
a = sin(dlat/2)*sin(dlat/2) + cos(lat1)*cos(lat2)*sin(dlon/2)*sin(dlon/2)
c = 2*atan2(sqrt(a), sqrt(1 - a))
quakes$dist = Rearth*c

#
# CURSORY EXPLORATION
#

# what were the largest quakes?
quakes = quakes[order(quakes$mag, decreasing = TRUE),] # sort by magnitude

print("LARGEST QUAKES")
print(quakes[quakes$mag >= 6.0, c("ptime", "mag", "area", "Etnt", "dist")])

# which major city was most affected by earthquakes?
print("MEAN distance, magnitude, and Energy in kilotonnes")
print(aggregate(data = quakes, cbind(dist, mag, Etnt) ~ area, mean))

# what is the combined yearly mean distance, magnitude, and energy?
print("YEARLY AVERAGES")
print(aggregate(data = quakes, cbind(dist, mag, Etnt) ~ yearbins, mean))

# what is the magnitude-frequency distribution for the two areas of interest?
freqSF = as.data.frame(table(quakes[quakes$area == "SF","Mhalfbins"]))
names(freqSF) = c("magSF", "freqSF")
freqLA = as.data.frame(table(quakes[quakes$area == "LA","Mhalfbins"]))
names(freqLA) = c("magLA", "freqLA")

print("EVENT FREQUENCY")
print(cbind(freqSF, freqLA))

#   PLOTS
#      - time vs. magnitude
#      - year vs. event count
#      - magnitude-frequency correlation

# load ggplot2, and scales packages for log tick marks
library("ggplot2")
library("scales")

# time vs. magnitude
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
           
#  binned year vs. event count
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

# magnitude-frequency correlation
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

print(head( quakes[c("d_planar", "dist")] ))
