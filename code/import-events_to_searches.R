library(tidyverse)
library(lubridate)
library(here)
library(knitr)

message("Lendo dados brutos de eventos")

events_original = read_csv("https://github.com/wikimedia-research/Discovery-Hiring-Analyst-2016/raw/master/events_log.csv.gz")

#events_original = events_original %>% slice(1:5000) # Útil para testar código em dados pequenos. Comente na hora de processá-los para valer.

message("Transformando em dados por busca")

events = events_original %>% 
    group_by(session_id) %>% 
    arrange(timestamp) %>% 
    mutate(search_index = cumsum(action == "searchResultPage")) # contador para as buscas nessa sessão.

searches = events %>% 
    group_by(session_id, search_index) %>% 
    arrange(timestamp) %>% 
    summarise(
        session_start_timestamp = first(timestamp),
        session_start_date = ymd_hms(first(timestamp)),
        session_end_date = ymd_hms(last(timestamp)),
        group = first(group), # eventos de uma mesma sessão são de um mesmo grupo
        results = max(n_results, na.rm = TRUE), # se não houver busca, retorna -Inf
        num_clicks = sum(action == "visitPage"), 
        first_click = ifelse(num_clicks == 0, 
                             NA_integer_, 
                             first(na.omit(result_position))
        )
    ) %>% 
    filter(search_index > 0) # Apenas search sessions

out_file = here("data/search_data.csv")

message("Salvando em ", out_file)

searches %>% 
    write_csv(out_file)
