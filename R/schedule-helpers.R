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

course_variables <- function() {
  yaml::read_yaml(here::here("_variables.yml"))
}

# Recordings are the one resource with two of everything: each class day is
# taught and recorded twice, once per section. Rather than splitting every
# lecture cell in two, all of them point at the same gallery and students pick
# the section they want.
#
# The faded/live distinction is kept by asking the calendar instead of the CSV:
# a class that has happened has a recording, so its icon goes live on its own.
# A per-lecture row in additional-resources.csv still wins, for the occasional
# day worth linking directly.
recording_url <- function(id, class_date) {
  gallery <- course_variables()$course$recordings
  override <- lookup_url(id, "recording")

  purrr::pmap_chr(
    list(id, class_date, override),
    \(this_id, this_date, this_override) {
      if (is.na(this_id)) {
        return(NA_character_)
      }
      if (!is.na(this_override)) {
        return(this_override)
      }
      if (is.na(this_date) || this_date > lubridate::today()) {
        return(NA_character_)
      }
      gallery
    }
  )
}

# Labs live on PrairieLearn, all of them, from the start of term. PL addresses
# assessments by a numeric database id that exists nowhere in this repo, so the
# default link is the assessment list -- every lab is listed there, including
# the ones that haven't opened yet, so a student always lands somewhere useful.
#
# A row in additional-resources.csv still wins, for a lab worth linking
# directly once its id is known.
prairielearn_url <- function(id) {
  instance <- course_variables()$course$prairielearn
  listing <- paste0(sub("/?$", "/", instance), "assessments")
  override <- lookup_url(id, "prairielearn")

  purrr::map2_chr(id, override, \(this_id, this_override) {
    if (is.na(this_id)) {
      return(NA_character_)
    }
    if (!is.na(this_override)) {
      return(this_override)
    }
    listing
  })
}

# Slides are authored in this repo, so derive the link from the file itself:
# the schedule links `lecture-07` to slides/lecture-07_slides.qmd when that
# file exists, and shows the faded "coming later" icon when it doesn't.
#
# A deck in progress is named draft-07_slides.qmd instead. It renders and is
# reachable at its own URL, but no schedule row points at it. Renaming it to
# lecture-07_slides.qmd is what publishes it.
slides_url <- function(id) {
  purrr::map_chr(id, \(this_id) {
    if (is.na(this_id)) {
      return(NA_character_)
    }
    source_file <- here::here("slides", paste0(this_id, "_slides.qmd"))
    if (!fs::file_exists(source_file)) {
      return(NA_character_)
    }
    paste0("slides/", this_id, "_slides.html")
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

    # Check the draft deck too, so an unpublished lecture still shows its real
    # topic in the schedule -- only the *link* waits for the rename.
    candidates <- c(
      here::here("slides", paste0(this_id, "_slides.qmd")),
      here::here(
        "slides",
        paste0(stringr::str_replace(this_id, "^lecture-", "draft-"), "_slides.qmd")
      )
    )
    for (slides_file in candidates) {
      if (fs::file_exists(slides_file)) {
        subtitle <- rmarkdown::yaml_front_matter(slides_file)$subtitle
        if (!is.null(subtitle)) {
          return(subtitle)
        }
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
