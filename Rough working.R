#https://www.epa.gov/clean-air-act-overview/air-pollution-current-and-future-challenges

library(tidyverse)
library(readr)


raw_data = read.csv('/Users/Alex/Documents/GitHub/comm2501Ass3/uspollution_pollution_us_2000_2016.csv')


attach(raw_data)
mean_data = raw_data %>%
  group_by(State, Date.Local) %>%
  summarise(no2=mean(NO2.Mean), no2_aqi=mean(NO2.AQI), o3=mean(O3.Mean), 
            o3_aqi=mean(O3.AQI), so2=mean(SO2.Mean), co=mean(CO.Mean), 
            so2_aqi=mean(SO2.AQI, na.rm=TRUE), co_aqi=mean(CO.AQI, na.rm=TRUE), 
            .groups='keep')

# Country data
sep_mean_data = mean_data %>%
  separate(col='Date.Local', into=c('year', 'month', 'day'), sep='-')
sep_mean_data$year_month = paste(sep_mean_data$year, sep_mean_data$month, sep='-')

country_data = sep_mean_data %>%
  filter(year != 2016) %>%
  group_by(year_month) %>% 
  summarise(no2=mean(no2), no2_aqi=mean(no2_aqi), so2=mean(so2), 
            so2_aqi=mean(so2_aqi), o3=mean(o3), o3_aqi=mean(o3_aqi), co=mean(co), 
            co_aqi=mean(co_aqi, na.rm=TRUE))

no2 = data.frame(country_data$year_month, emissions=country_data$no2, aqi=country_data$no2_aqi, type='NO2')
so2 = data.frame(country_data$year_month, emissions=country_data$so2, aqi=country_data$so2_aqi, type='SO2')
o3 = data.frame(country_data$year_month, emissions=country_data$o3, aqi=country_data$o3_aqi, type='O3')
co = data.frame(country_data$year_month, emissions=country_data$co, aqi=country_data$co_aqi, type='CO')
country_data = bind_rows(no2,so2,o3,co)

# Create line graphs for the country's overall pollutants
library(ggplot2)
attach(mean_data)
#years = paste('20', formatC(seq(0,15,1), width=2, flag='0'), '-01', sep='')
#ggplot(country_data, aes(x=year_month, xlab='Year', ylab='AQI', group=1))+
#  geom_line(aes(y=no2_aqi, alpha=0.7), color='darkred', )+
#  geom_line(aes(y=so2_aqi, alpha=0.7), color='steelblue')+
#  geom_line(aes(y=o3_aqi, alpha=0.7), color='palegreen4')+
#  geom_line(aes(y=co_aqi, alpha=0.7), color='orange1')+
#  geom_smooth(aes(y=no2_aqi), color='darkred')+
#  geom_smooth(aes(y=so2_aqi), color='steelblue')+
#  geom_smooth(aes(y=o3_aqi), color='palegreen4')+
#  geom_smooth(aes(y=co_aqi), color='orange1')+
#  ggtitle('Air Quality Index (AQI) of Common Pollutants in the US')+ 
#  scale_x_discrete(breaks=years)
  
# VISUALISATION 1
attach(country_data)
country_data$aqi = round(as.numeric(country_data$aqi),2)
data = country_data %>%
  rename(period=country_data.year_month, AQI = aqi)
years = paste('20', formatC(seq(0,15,1), width=2, flag='0'), '-01', sep='')
plot = ggplot(data, mapping=aes(period, AQI, group=type, 
                                 color=type))+
  geom_smooth()+
  geom_line(alpha=0.7)+
  ggtitle('Air Quality Index (AQI) of Common Pollutants in the US')+ 
  labs(y='AQI', x='Year', color='Pollutant')+
  theme(axis.text.x = element_text(angle = 90))+
  scale_x_discrete(breaks=years)
ggplotly(plot, tooltip=c("period", "AQI"))

write.csv(data, "/Users/Alex/Documents/GitHub/comm2501Ass3/A3_Website/overview_data.csv")
country_data = read.csv("countryData.csv")


# VISUALISATION 2 - NO2 by state (2015)
lat_long = read.csv('/Users/Alex/Documents/GitHub/comm2501Ass3/Lat and Long.csv')

recent_data = mean_data %>%
  mutate(month = format(as.Date(Date.Local), "%m"), year = format(as.Date(Date.Local), "%Y")) %>%
  filter(year == '2015') %>%
  group_by(State, year) %>%
  summarise(no2=mean(no2), no2_aqi=mean(no2_aqi), o3=mean(o3), 
            o3_aqi=mean(o3_aqi), so2=mean(so2), co=mean(co), 
            so2_aqi=mean(so2_aqi, na.rm=TRUE), co_aqi=mean(co_aqi, na.rm=TRUE),
            .groups='keep')

recent_data = merge(recent_data, lat_long, by='State')

library(RColorBrewer)
pal <- colorNumeric(
  palette = "Green",
  domain = recent_data$no3)


library("leaflet")
no2_chart = recent_data %>%
  leaflet() %>%
  addTiles() %>%
  addCircleMarkers(label = ~State,
                   popup = ~paste(round(no2, 2), 'parts per billion<br>AQI: ', round(no2_aqi)),
                   color = ~pal(no2),
                   opacity = ~(no2_aqi/max(recent_data$no2_aqi)),
                   radius = ~no2,
                   lng = ~Long,
                   lat = ~Lat)
save(no2_chart, file = "no2_map.RData")

# VISUALISATION 3 - SO2 by state (2015)
library(RColorBrewer)
pal <- colorNumeric(
  palette = "Purple",
  domain = c(-4, 7))

library("leaflet")
recent_data %>%
  leaflet() %>%
  addTiles() %>%
  addCircleMarkers(label = ~State,
                   popup = ~paste(round(so2, 2), 'parts per billion'),
                   color = ~pal(so2),
                   radius = ~so2*10,
                   lng = ~Long,
                   lat = ~Lat)

# VISUALISATION 4 - O3 by state (2015)
library(RColorBrewer)
pal <- colorNumeric(
  palette = "Blue",
  domain = recent_data$o3)

library("leaflet")
recent_data %>%
  leaflet() %>%
  addTiles() %>%
  addCircleMarkers(label = ~State,
                   popup = ~paste(round(o3, 4), 'parts per billion'),
                   color = ~pal(o3),
                   radius = ~o3*500,
                   lng = ~Long,
                   lat = ~Lat)

# VISUALISATION 5 - CO by state (2015)
library(RColorBrewer)
pal <- colorNumeric(
  palette = "Red",
  domain = c(recent_data$co))

library(leaflet)
recent_data %>%
  leaflet() %>%
  addTiles() %>%
  addCircleMarkers(label = ~State,
                   popup = ~paste(round(co, 4), 'parts per billion'),
                   color = ~pal(co),
                   radius = ~co*50,
                   lng = ~Long,
                   lat = ~Lat)

# VISUALISATION 6 AQI BY STATE (2015)
library(sf)
library(tigris)

# Downloading the shapefiles for states at the lowest resolution
states = states(cb=T) %>%
  filter(NAME %in% recent_data$State)

#recent_data = merge(recent_data, states, by.x=c('State'),
#                    by.y=c('NAME'))

merged_states <- geo_join(states, recent_data, "NAME", "State")

pal = colorNumeric(
  palette = "YlOrRd",
  domain = recent_data$no2_aqi)


leaflet() %>%
  addProviderTiles("CartoDB.Positron") %>%
  setView(-98.483330, 38.712046, zoom = 4) %>% 
  addPolygons(data = merged_states , 
              fillColor = ~pal(merged_states$no2_aqi), 
              fillOpacity = 0.7, 
              weight = 0.2, 
              smoothFactor = 0.2, 
              label = State,
              popup = ~paste('NO2 AQI is', round(no2_aqi, 4))) #%>%
  #addLegend(pal = pal, 
  #          values = merged_states$no2_aqi, 
  #          position = "bottomright", 
  #          title = "NO2 AQI")




# VISUALISATION 7 - NO2 by bar
plot = ggplot(data=recent_data)+
  geom_bar(aes(y=no2, x=reorder(State, -no2), fill=-no2_aqi), stat='identity')+
  theme(axis.text.x = element_text(angle = 90))+
  ggtitle('NO2 by US State in 2015')+ 
  labs(y='NO2 (Parts per billion)', x='State', color='NO2 AQI', fill="NO2 AQI")+
  scale_fill_gradient(low="darkgreen", high="palegreen1")
ggplotly(plot)



library(ggthemes)
data = recent_data %>%
  rename(NO2 = no2, AQI = no2_aqi)
data$AQI = round(data$AQI, 2)
data$NO2 = round(data$NO2, 2)
plot = ggplot(data=data, aes(label=State))+
  geom_point(aes(y=NO2, x=AQI))+
  ggtitle('Average NO2 by US State in 2015')+ 
  labs(y='NO2 (Parts per billion)', x='NO2 AQI')+
  theme_economist()
ggplotly(plot)

  
# Violin plot for NO2
high_no2 = mean_data %>%
  filter(State == 'Colorado' || State == 'Utah' || State == 'New York' ||
         State == 'Wyoming') %>%
  filter(grepl("2015-", Date.Local, fixed = TRUE))

plot = ggplot(high_no2, aes(x=State, y=no2_aqi, fill=State))+ 
  geom_boxplot()+
  ggtitle('States with the Worst AQI in 2015')+ 
  labs(y='AQI', x='State')
ggplotly(plot)
write.csv(high_no2, "/Users/Alex/Documents/GitHub/comm2501Ass3/A3_Website/content/post/highNo2.csv")


write.csv(mean_data, "meanData.csv")

high_o3 = mean_data %>%
  filter(State == 'Nevada' || State == 'Arizona' || State == 'Utah' ||
           State == 'Wyoming') %>%
  filter(grepl("2015-", Date.Local, fixed = TRUE))


plot = ggplot(high_o3, aes(x=State, y=o3_aqi, fill=State))+ 
  geom_boxplot()+
  ggtitle('States with the Worst AQI in 2015')+ 
  labs(y='AQI', x='State')
View(high_o3)
write.csv(high_o3, "/Users/Alex/Documents/GitHub/comm2501Ass3/A3_Website/content/post/highO3.csv")


high_co = mean_data %>%
  filter(State == 'Florida' || State == 'Alaska' || State == 'Colorado' ||
           State == 'Arizona') %>%
  filter(grepl("2015-", Date.Local, fixed = TRUE))

plot = ggplot(high_co, aes(x=State, y=co_aqi, fill=State))+ 
  geom_boxplot()+
  ggtitle('States with the Worst AQI in 2015')+ 
  labs(y='AQI', x='State')
ggplotly(plot)
write.csv(high_no2, "/Users/Alex/Documents/GitHub/comm2501Ass3/A3_Website/content/post/highCO.csv")


high_so2 = mean_data %>%
  filter(State == 'Alaska' || State == 'Ohio' || State == 'Kansas' ||
           State == 'Indiana') %>%
  filter(grepl("2015-", Date.Local, fixed = TRUE))

plot = ggplot(high_so2, aes(x=State, y=so2_aqi, fill=State))+ 
  geom_boxplot()+
  ggtitle('States with the Worst AQI in 2015')+ 
  labs(y='AQI', x='State')
ggplotly(plot)
write.csv(high_so2, "/Users/Alex/Documents/GitHub/comm2501Ass3/A3_Website/content/post/highSo2.csv")



mean_data %>% 
  group_by(State) %>%
  

#VISUALISATION 8 - Pollutant by Industry
library(plotly)
by_industry = read.csv('/Users/Alex/Documents/GitHub/comm2501Ass3/Summary By Industry.csv')

# create a dataset
Year <- by_industry$Year
Source <- by_industry$Source
NO2 <- by_industry$no2
SO2 <- by_industry$so2
CO <- by_industry$co
data <- data.frame(Year,Source,NO2, SO2, CO)

# Grouped
new_data = data %>%
  filter(Year > 2006)
plot = ggplot(new_data, aes(fill=Source, y=NO2, x=Year)) + 
  geom_bar(position="dodge", stat="identity")+
  theme_bw()
ggplotly(plot)

write.csv(new_data, '/Users/Alex/Documents/GitHub/comm2501Ass3/byIndustry.csv')
save(plot, file="dataByIndustry.RData")








