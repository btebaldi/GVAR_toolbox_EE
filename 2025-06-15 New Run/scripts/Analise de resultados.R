# Setup -------------------------------------------------------------------
rm(list = ls())


library(readxl)
library(tidyverse)


# User Defined Function ---------------------------------------------------

# ht <- function(x){
#   list("Head" = head(x), "Tail" = tail(x))
# }
# 

# Internal Variabels ------------------------------------------------------

# Dir and files of results
mDirMask <- "GVAR_Toolbox2.0/Output/Meso17_%dperc"
mFileMask <- "m17_%dperc_output.xlsx"

# Actual Values
mActualDir <- "Base de dados"
mAdmFile <- "Adm_OutputFile.xlsx"
mDesFile <- "Des_OutputFile.xlsx"




# Data Load ---------------------------------------------------------------

# load Actual values
tblAdmActual <- readxl::read_excel(path = file.path(mActualDir, mAdmFile))
tblDeslActual <- readxl::read_excel(path = file.path(mActualDir, mDesFile))

percent <- c(0,2,4,6,8)
list_of_models <- list()

for(i in seq_along(percent)){
  percent_current <- percent[i]
  cat("Lendo resultados",  percent_current, "%\n")
  
  # Abretura dos resultados da previsao condicional
  tbl <- readxl::read_excel(path = file.path(sprintf(mDirMask, percent_current), sprintf(mFileMask, percent_current)),
                            sheet = "conditional forecasts",
                            range = cell_limits(ul = c(5, 1), lr = c(NA, NA)))
  
  # Regularizacao de colunas faltantes
  colnames(tbl)[1] <- "Region"
  colnames(tbl)[2] <- "Series"
  colnames(tbl)[3] <- "F_A"
  
  # Regularizacao de colunas faltantes
  tbl <- tbl %>% 
    dplyr::select(- F_A) %>% 
    dplyr::filter(!is.na(Region)) %>% 
    tidyr::pivot_longer(cols = starts_with("20"), names_to = "Periodo") %>% 
    dplyr::mutate(Date = lubridate::ymd(Periodo, truncated = 1))
  
  list_of_models[[i]] <- tbl 
}

list_of_models[[length(list_of_models)+1]] <- tblAdmActual %>% 
  pivot_longer(cols = -date) %>% 
  dplyr::mutate(Series = "adm", 
                date = lubridate::ymd(date, truncated = 1)) %>%
  dplyr::rename(Actual = value)


list_of_models[[length(list_of_models)+1]] <- tblDeslActual %>% 
  pivot_longer(cols = -date) %>% 
  dplyr::mutate(Series = "desl", 
                date = lubridate::ymd(date, truncated = 1)) %>%
  dplyr::rename(Actual = value)


names(list_of_models) <- c(sprintf("Perc%d", percent), c("ActualAdm", "ActualDesl"))



# Data interpretation -----------------------------------------------------

# 
# 
# 
# 
# tibble(Data = NA,
#        Region = NA,
#        Cenario = NA)
# 



i=1
for(i in seq_along(percent)){
  percent_current <- percent[i]
  cat("Lendo resultados",  percent_current, "%\n")
  
  tbl <- list_of_models[[i]]
  newNameCol <- sprintf("Perc_%d", percent_current)
  tbl <- tbl %>% dplyr::rename(!!newNameCol := value) %>% dplyr::select(-Periodo)
  if(i == 1){
    tblfull <- tbl 
  } else {
    tblfull <- inner_join(tblfull, tbl, by = c("Region"="Region",
                                               "Series"="Series",
                                               "Date" = "Date") )
  }
}


tblfull <- dplyr::left_join(tblfull, 
                            dplyr::bind_rows(list_of_models[["ActualAdm"]],list_of_models[["ActualDesl"]]),
                            by = c("Region" = "name", 
                                   "Date"="date",
                                   "Series"="Series"))


# # list of reagions
mListRegions <- c( "RJ" = "Rj3306",
                   "BH" = "Mg3107",
                   "Salvador" = "Ba2905",
                   "SP" = "Sp3515",
                   "PortoAlegre" = "Rs4305",
                   "Jequitinhonha" = "Mg3103",
                   "Borborema" = "Pb2502",
                   "CentralGoias" = "Go5203")

for(i in seq_along(mListRegions)){
  
  region <- mListRegions[i]
  
  tbl2 <- tblfull %>% 
    dplyr::filter(Region %in% region) %>%
    tidyr::pivot_longer(cols = c(sprintf("Perc_%d", percent), "Actual"), names_to = "Tipo") %>% 
    tidyr::pivot_wider(id_cols = c("Region", "Date", "Tipo"),
                       names_from = "Series",
                       values_from = "value") %>% 
    dplyr::arrange(Date) %>% 
    dplyr::group_by(Region, Tipo) %>% 
    dplyr::mutate(Net = adm - desl,
                  NetCumSum = cumsum(Net))
  
  graph <- tbl2 %>% 
    ggplot() + 
    geom_line(aes(x = Date, y = NetCumSum, colour = Tipo)) + 
    # facet_wrap(~Region) +
    labs(title = "Cumulative employment rate",
    subtitle = sprintf("%s regional level",  names(mListRegions)[i])) +
    theme_bw()
  
  print(graph)
  
}

# tbl2 %>% 
#   # dplyr::filter(Region == "Sp3515") %>% 
#   # dplyr::filter(Region == "Mg3107") %>% 
#   dplyr::filter(Region == "Mg3103") %>% 
#   ht()

# Metropolitana de Salvador
# Metropolitana de Belo Horizonte
# Metropolitana do Rio de Janeiro




# Aggregation by State ----------------------------------------------------



tbl %>% 
  dplyr::mutate(Estado = str_match(string = Region, pattern = "[:alpha:]+")[ , 1]) %>%
  dplyr::group_by(Estado, Series, Date) %>% 
  dplyr::summarise(value = sum(value)) %>% 
  tidyr::pivot_wider(id_cols = c("Estado", "Date"), names_from = Series, values_from = value) %>% 
  dplyr::arrange(Date) %>% 
  dplyr::mutate(Net = adm - desl,
                NetCumSum = cumsum(Net)) %>% 
  ggplot() + 
  geom_line(aes(x = Date, y = NetCumSum, colour = Estado)) + 
  facet_wrap(~Estado, , scales="free_y") +
  # facet_grid(.~Group, scales="free_y") +
  labs()




# Agregacao nivel Brasil

# Agregacao NO=North; NE=Northeast; MW=Midwest; SE=Southeast; SO=South

# Agregacao MG=Minas Gerais; ES=Espirito Santo; RJ=Rio de Janeiro; SP=Sao Paulo

# Agregacao
# Bor=Borborema area;
# CGo=Goias central area;
# Jeq=Jequitinhonha area;
# POU=Porto Alegre metropolitan area;
# SPa=Sao Paulo metropolitan area

# Sal: Salvador metropolitan area;
# RJ: Rio de Janeiro metropolitan area;
# PA: Porto Alegre metropolitan area;
# BH: Belo Horizonte metropolitan area;
# SP: S˜ao Paulo metropolitan area




