# clear all
rm(list = ls())

# library
library(readxl)
library(dplyr)
library(ggplot2)

Rec.8perc <- read_excel("C:/Users/Teo/Dropbox/bruno-tebaldi/Recuperacao_8perc.xlsx", 
                          sheet = "Recuperacao", range = "a3:c157")

Rec.4perc <- read_excel("C:/Users/Teo/Dropbox/bruno-tebaldi/Recuperacao_4perc.xlsx", 
                        sheet = "Recuperacao", range = "a3:c157")

Rec.0perc <- read_excel("C:/Users/Teo/Dropbox/bruno-tebaldi/Recuperacao_0perc.xlsx", 
                        sheet = "Recuperacao", range = "a3:c157")

# preview of data
head(Rec.0perc)
tail(Rec.0perc)

head(Rec.4perc)
tail(Rec.4perc)

head(Rec.8perc)
tail(Rec.8perc)

# filter data
Data.0perc <- Rec.0perc %>% 
  filter(!is.na(Deficit)) %>% 
  mutate(check = Mesoregiao %% 100) %>% 
  filter(check != 0) %>% 
  filter(Mesoregiao < 9999)
Brasil.0perc = na.omit(Rec.0perc$time_to_rec[Rec.0perc$Mesoregiao == 99999])
Data.0perc$time_to_rec_centrada = Data.0perc$time_to_rec - Brasil.0perc
Range.0perc = range(Data.0perc$time_to_rec)


Data.4perc <- Rec.4perc %>% 
  filter(!is.na(Deficit)) %>% 
  mutate(check = Mesoregiao %% 100) %>% 
  filter(check != 0) %>% 
  filter(Mesoregiao < 9999)
Brasil.4perc = na.omit(Rec.4perc$time_to_rec[Rec.4perc$Mesoregiao == 99999])
Data.4perc$time_to_rec_centrada = Data.4perc$time_to_rec - Brasil.4perc
Range.4perc = range(Data.4perc$time_to_rec)


Data.8perc <- Rec.8perc %>% 
  filter(!is.na(Deficit)) %>% 
  mutate(check = Mesoregiao %% 100) %>% 
  filter(check != 0) %>% 
  filter(Mesoregiao < 9999)
Brasil.8perc = na.omit(Rec.8perc$time_to_rec[Rec.8perc$Mesoregiao == 99999])
Data.8perc$time_to_rec_centrada = Data.8perc$time_to_rec - Brasil.8perc
Range.8perc = range(Data.8perc$time_to_rec)


total.range = range(Range.8perc, Range.4perc, Range.0perc)

# ---- Graficos -----

graf.title1 = "Boxplot of recovery"
graf.x1 = "Months to recovery"
graf.y1 = "Quantity of meso regions"
graf.title2 = "Bar plot"
graf.x2 = "Months to recovery"
graf.y2 = "Quantity of meso regions"

g.box0 <- Data.0perc %>% 
  ggplot() +
  geom_boxplot(aes(time_to_rec)) + 
  geom_vline(xintercept = Brasil.0perc, colour = "black", linetype="dashed") +
  labs(
    title = graf.title1,
    subtitle = "0% growth",
    x = graf.x1,
    y = graf.y1
  ) + theme_bw()


g.bar0 <- 
  Data.0perc %>% 
  ggplot() +
  geom_bar(aes(time_to_rec), alpha = 0.5) + 
  geom_vline(xintercept = Brasil.0perc, colour = "black", linetype="dashed") +
  labs(
    title = graf.title2,
    subtitle = "0% growth",
    x = graf.x2,
    y = graf.y2
  ) + theme_bw() + xlim(-1, 100)



# ------------------------
g.box4 <- Data.4perc %>% 
  ggplot() +
  geom_boxplot(aes(time_to_rec)) + 
  geom_vline(xintercept = Brasil.4perc, colour = "black", linetype="dashed") +
  labs(
    title = graf.title1,
    subtitle = "4% growth",
    x = graf.x1,
    y = graf.y1
  ) + theme_bw()


g.bar4 <- Data.4perc %>% 
  ggplot() +
  geom_bar(aes(time_to_rec), alpha = 0.5) + 
  geom_vline(xintercept = Brasil.4perc, colour = "black", linetype="dashed") +
  labs(
    title = graf.title2,
    subtitle = "4% growth",
    x = graf.x2,
    y = graf.y2
  ) + theme_bw() + xlim(-1, 100)

# --------------------------
g.box8 <- Data.8perc %>% 
  ggplot() +
  geom_boxplot(aes(time_to_rec)) + 
  geom_vline(xintercept = Brasil.8perc, colour = "black", linetype="dashed") +
  labs(
    title = graf.title1,
    subtitle = "8% growth",
    x = graf.x1,
    y = graf.y1
  ) + theme_bw()


g.bar8 <- Data.8perc %>% 
  ggplot() +
  geom_bar(aes(time_to_rec), alpha = 0.5) + 
  geom_vline(xintercept = Brasil.8perc, colour = "black", linetype="dashed") +
  labs(
    title = graf.title2,
    subtitle = "8% growth",
    x = graf.x2,
    y = graf.y2
  ) + theme_bw() + xlim(-1, 100)

ggsave(filename = "bar_0perc.png", plot = g.bar0)
ggsave(filename = "bar_4perc.png", plot = g.bar4)
ggsave(filename = "bar_8perc.png", plot = g.bar8)

ggsave(filename = "boxplot_0perc.png", plot = g.box0)
ggsave(filename = "boxplot_4perc.png", plot = g.box4)
ggsave(filename = "boxplot_8perc.png", plot = g.box8)

