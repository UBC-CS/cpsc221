# "By week" view: one row per week, matching the term schedule students see
# on the first day of class. Compact and structural -- see render-unit-schedule.R
# for the chronological, titled view of the same data.

source(here::here("R", "schedule-helpers.R"))

render_schedule <- function() {
  table_data <- read_schedule() |>
    dplyr::mutate(
      mon_slides = resource_cell(
        mon_id,
        slides_url(mon_id),
        "window-maximize",
        "Slides"
      ),
      mon_recording = resource_cell(
        mon_id,
        lookup_url(mon_id, "recording"),
        "circle-play",
        "Recording"
      ),
      wed_slides = resource_cell(
        wed_id,
        slides_url(wed_id),
        "window-maximize",
        "Slides"
      ),
      wed_recording = resource_cell(
        wed_id,
        lookup_url(wed_id, "recording"),
        "circle-play",
        "Recording"
      ),
      fri_slides = resource_cell(
        fri_id,
        slides_url(fri_id),
        "window-maximize",
        "Slides"
      ),
      fri_recording = resource_cell(
        fri_id,
        lookup_url(fri_id, "recording"),
        "circle-play",
        "Recording"
      ),
      hwpa_cell = purrr::map2_chr(
        hwpa,
        lookup_url(hwpa, "prairielearn"),
        \(label, url) {
          if (is.na(label)) {
            return("")
          }
          if (is.na(url)) {
            return(as.character(glue::glue(
              '<span class="pending" title="{label} on PrairieLearn ',
              '(not yet posted)">{label}</span>'
            )))
          }
          as.character(glue::glue('<a href="{url}">{label}</a>'))
        }
      ),
      lab_cell = resource_cell(
        lab,
        lookup_url(lab, "prairielearn"),
        "calendar-week",
        "Lab on PrairieLearn"
      ),
      exam_book = resource_cell(
        exam,
        lookup_url(exam, "pre-activity"),
        "book",
        "Examlet review material"
      ),
      exam_practice = resource_cell(
        exam,
        lookup_url(exam, "practice"),
        "pen-to-square",
        "Examlet practice problems"
      ),
      week = as.character(week)
    ) |>
    dplyr::select(
      part,
      week,
      date,
      mon_slides,
      mon_recording,
      wed_slides,
      wed_recording,
      fri_slides,
      fri_recording,
      hwpa_cell,
      lab_cell,
      exam_book,
      exam_practice
    )

  this_monday <- current_monday()

  table_data |>
    gt::gt(groupname_col = "part") |>
    gt::fmt_date(date, date_style = "MMMd") |>
    gt::fmt_markdown(
      columns = c(
        mon_slides,
        mon_recording,
        wed_slides,
        wed_recording,
        fri_slides,
        fri_recording,
        hwpa_cell,
        lab_cell,
        exam_book,
        exam_practice
      )
    ) |>
    gt::sub_missing(missing_text = "") |>
    gt::cols_label(
      week = "Week",
      date = "Mon",
      mon_slides = "",
      mon_recording = "",
      wed_slides = "",
      wed_recording = "",
      fri_slides = "",
      fri_recording = "",
      hwpa_cell = "HW/PA",
      lab_cell = "Lab",
      exam_book = "",
      exam_practice = ""
    ) |>
    gt::tab_spanner(label = "M", columns = c(mon_slides, mon_recording)) |>
    gt::tab_spanner(label = "W", columns = c(wed_slides, wed_recording)) |>
    gt::tab_spanner(label = "F", columns = c(fri_slides, fri_recording)) |>
    gt::tab_spanner(label = "EX", columns = c(exam_book, exam_practice)) |>
    gt::cols_align(align = "center", columns = !c(week, date)) |>
    gt::cols_align(align = "right", columns = c(week, date)) |>
    gt::tab_style(
      style = gt::cell_text(weight = "bold", size = "large"),
      locations = gt::cells_body(columns = week)
    ) |>
    gt::tab_style(
      style = list(gt::cell_text(weight = "bold")),
      locations = list(
        gt::cells_row_groups(),
        gt::cells_column_labels(),
        gt::cells_column_spanners()
      )
    ) |>
    gt::tab_style(
      style = gt::cell_fill(color = "#e8f4f8"),
      locations = gt::cells_body(rows = date == this_monday)
    ) |>
    gt::tab_options(
      quarto.disable_processing = TRUE,
      table.width = "100%",
      data_row.padding = gt::px(4)
    )
}
