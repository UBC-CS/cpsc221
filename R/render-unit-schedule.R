# "By unit" view: one row per scheduled item, in chronological order, with
# titles -- easier for finding a specific topic within the flow of the course.
# Built from the same data as render-schedule.R.

source(here::here("R", "schedule-helpers.R"))

render_unit_schedule <- function() {
  schedule <- read_schedule()

  # Lectures: one row per meeting day, dated off that week's Monday.
  lectures <- schedule |>
    dplyr::select(part, week, date, mon_id, wed_id, fri_id) |>
    tidyr::pivot_longer(
      cols = c(mon_id, wed_id, fri_id),
      names_to = "day",
      values_to = "id"
    ) |>
    dplyr::filter(!is.na(id)) |>
    dplyr::mutate(
      offset = dplyr::case_when(
        day == "mon_id" ~ 0,
        day == "wed_id" ~ 2,
        day == "fri_id" ~ 4
      ),
      date = date + offset,
      kind = "lecture",
      sort_order = offset,
      title = lecture_title(id),
      title_url = summary_url(id),
      resource_1 = resource_cell(
        id,
        slides_url(id),
        "window-maximize",
        "Slides"
      ),
      resource_2 = resource_cell(
        id,
        lookup_url(id, "recording"),
        "circle-play",
        "Recording"
      )
    )

  # Labs, assignments and examlets aren't tied to a specific meeting day, so
  # they sort after that week's lectures.
  weekly_items <- function(id_column, kind, sort_order, r1, r2) {
    schedule |>
      dplyr::select(part, week, date, id = {{ id_column }}) |>
      dplyr::filter(!is.na(id)) |>
      dplyr::mutate(
        kind = kind,
        sort_order = sort_order,
        title = id,
        title_url = NA_character_,
        resource_1 = r1(id),
        resource_2 = r2(id)
      )
  }

  labs <- weekly_items(
    lab,
    "lab",
    5,
    \(id) {
      resource_cell(
        id,
        lookup_url(id, "prairielearn"),
        "calendar-week",
        "Lab on PrairieLearn"
      )
    },
    \(id) rep("", length(id))
  ) |>
    dplyr::mutate(
      title = stringr::str_replace(title, "^lab-0*(\\d+)$", "Lab \\1")
    )

  assignments <- weekly_items(
    hwpa,
    "assignment",
    6,
    \(id) {
      resource_cell(
        id,
        lookup_url(id, "prairielearn"),
        "calendar-week",
        "Assignment on PrairieLearn"
      )
    },
    \(id) rep("", length(id))
  )

  examlets <- weekly_items(
    exam,
    "exam",
    7,
    \(id) {
      resource_cell(
        id,
        lookup_url(id, "pre-activity"),
        "book",
        "Examlet review material"
      )
    },
    \(id) {
      resource_cell(
        id,
        lookup_url(id, "practice"),
        "pen-to-square",
        "Examlet practice problems"
      )
    }
  )

  table_data <- dplyr::bind_rows(lectures, labs, assignments, examlets) |>
    dplyr::arrange(week, sort_order) |>
    dplyr::mutate(
      day_and_date = dplyr::if_else(
        kind == "lecture",
        as.character(glue::glue(
          '<span class="day-of-week">{format(date, "%a")}</span> ',
          '{format(date, "%b %e")}'
        )),
        as.character(glue::glue(
          '<span class="day-of-week">week {week}</span>'
        ))
      ),
      title_cell = purrr::map2_chr(title, title_url, \(this_title, this_url) {
        if (is.na(this_url)) {
          return(this_title)
        }
        as.character(glue::glue('<a href="{this_url}">{this_title}</a>'))
      })
    ) |>
    dplyr::select(part, day_and_date, title_cell, resource_1, resource_2)

  table_data |>
    gt::gt(groupname_col = "part") |>
    gt::fmt_markdown(
      columns = c(day_and_date, title_cell, resource_1, resource_2)
    ) |>
    gt::sub_missing(missing_text = "") |>
    gt::cols_label(
      day_and_date = "",
      title_cell = "",
      resource_1 = "",
      resource_2 = ""
    ) |>
    gt::cols_align(align = "right", columns = day_and_date) |>
    gt::cols_align(align = "left", columns = title_cell) |>
    gt::cols_align(align = "center", columns = c(resource_1, resource_2)) |>
    gt::tab_style(
      style = list(gt::cell_text(weight = "bold")),
      locations = list(gt::cells_row_groups())
    ) |>
    gt::tab_options(
      quarto.disable_processing = TRUE,
      table.width = "100%",
      data_row.padding = gt::px(4)
    )
}
