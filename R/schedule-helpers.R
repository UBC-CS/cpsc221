# Shared helpers for the two schedule views (by week and by unit).
#
# Data model:
#   data/schedule.csv              one row per week; semantic ids per cell
#   data/additional-resources.csv  id,type,resource -- URLs as they go live
#
# Every cell that will *eventually* hold a link renders a faded icon until a
# URL exists for it, so students can see what's coming. Cells that will never
# hold anything (holidays, term end) render empty.

read_schedule <- function() {
  readr::read_csv(
    here::here("data", "schedule.csv"),
    col_types = readr::cols(
      part = readr::col_character(),
      week = readr::col_integer(),
      date = readr::col_date(),
      mon_id = readr::col_character(),
      wed_id = readr::col_character(),
      fri_id = readr::col_character(),
      hwpa = readr::col_character(),
      lab = readr::col_character(),
      exam = readr::col_character()
    )
  )
}

read_additional_resources <- function() {
  readr::read_csv(
    here::here("data", "additional-resources.csv"),
    col_types = "ccc"
  )
}

# Look up a URL for a given (id, type); NA when it isn't published yet.
lookup_url <- function(id, type) {
  additional <- read_additional_resources()
  purrr::map_chr(id, \(this_id) {
    if (is.na(this_id)) {
      return(NA_character_)
    }
    match <- additional |>
      dplyr::filter(id == this_id, type == .env$type)
    if (nrow(match) == 0) NA_character_ else match$resource[[1]]
  })
}

# Slides are authored in this repo, so derive the link from the file itself.
slides_url <- function(id) {
  purrr::map_chr(id, \(this_id) {
    if (is.na(this_id)) {
      return(NA_character_)
    }
    source_file <- here::here("slides", paste0(this_id, "_slides.qmd"))
    if (fs::file_exists(source_file)) {
      paste0("slides/", this_id, "_slides.html")
    } else {
      NA_character_
    }
  })
}

# A cell is empty when nothing is scheduled, a live link when the resource
# exists, and a faded icon when it is expected but not yet published.
resource_cell <- function(anchor, url, icon, label) {
  purrr::map2_chr(
    anchor,
    url,
    \(this_anchor, this_url) {
      if (is.na(this_anchor)) {
        return("")
      }
      if (is.na(this_url)) {
        return(as.character(glue::glue(
          '<span class="pending" title="{label} (not yet posted)">',
          "{fontawesome::fa(icon, fill_opacity = 0.25)}",
          "</span>"
        )))
      }
      as.character(glue::glue(
        '<a href="{this_url}" title="{label}">{fontawesome::fa(icon)}</a>'
      ))
    }
  )
}

# Prefer the human-written summary title; fall back to the slides subtitle,
# then to the id itself, so a lecture always shows something meaningful.
lecture_title <- function(id) {
  purrr::map_chr(id, \(this_id) {
    if (is.na(this_id)) {
      return(NA_character_)
    }

    summary_file <- here::here("summaries", paste0(this_id, "_summary.qmd"))
    if (fs::file_exists(summary_file)) {
      title <- rmarkdown::yaml_front_matter(summary_file)$title
      if (!is.null(title)) {
        return(title)
      }
    }

    slides_file <- here::here("slides", paste0(this_id, "_slides.qmd"))
    if (fs::file_exists(slides_file)) {
      subtitle <- rmarkdown::yaml_front_matter(slides_file)$subtitle
      if (!is.null(subtitle)) {
        return(subtitle)
      }
    }

    # e.g. "lecture-07" -> "Lecture 7"
    stringr::str_replace(this_id, "^([a-z]+)-0*(\\d+)$", "\\1 \\2") |>
      stringr::str_to_sentence()
  })
}

summary_url <- function(id) {
  purrr::map_chr(id, \(this_id) {
    if (is.na(this_id)) {
      return(NA_character_)
    }
    source_file <- here::here("summaries", paste0(this_id, "_summary.qmd"))
    if (fs::file_exists(source_file)) {
      paste0("summaries/", this_id, "_summary.html")
    } else {
      NA_character_
    }
  })
}

current_monday <- function() {
  lubridate::floor_date(lubridate::today(), unit = "week", week_start = 1)
}
