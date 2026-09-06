source(here::here("R", "fct-to-lower.R"))
source(here::here("R", "fct-to-snake.R"))
source(here::here("R", "format-exam-with-due-date.R"))
source(here::here("R", "format-resource-as-label.R"))
source(here::here("R", "format-week-with-start-day.R"))
source(here::here("R", "get-schedule.R"))
source(here::here("R", "highlight-current-week.R"))

render_weekly_schedule <- function() {
  schedule <- get_schedule() |>
    dplyr::filter_out(is.na(type)) |>
    dplyr::mutate(
      date = gt::vec_fmt_date(date, date_style = "MMMd"),
      label = purrr::pmap_chr(
        list(show_week, id, type, resource),
        format_resource_as_label
      ),
      label = dplyr::replace_when(
        label,
        unit == "week" ~ format_week_with_start_day(date, id, resource),
        unit == "exam" ~ format_exam_with_due_date(
          slot,
          date,
          show_week,
          show_exam,
          id,
          resource
        )
      )
    )

  # This course's "discussion" unit is the weekly Lab -- a single meeting per
  # week (not two, as in the template this was adapted from), so it uses one
  # "Lab" slot rather than a First/Second split.
  lectures_and_labs <- schedule |>
    dplyr::filter(unit %in% c("lecture", "discussion")) |>
    dplyr::arrange(slot) |>
    dplyr::select(
      week_number = week,
      current_week,
      show_week,
      show_exam,
      slot,
      unit,
      type,
      label
    ) |>
    dplyr::mutate(
      slot = fct_to_lower(slot),
      type = fct_to_snake(type)
    ) |>
    tidyr::pivot_wider(
      names_from = c(slot, unit, type),
      names_sep = "_",
      values_from = label
    ) |>
    dplyr::arrange(week_number)

  # Units with only a single resource
  other_units <- schedule |>
    dplyr::filter(unit %in% c("part", "week", "exam")) |>
    dplyr::select(week_number = week, unit, label) |>
    dplyr::summarize(
      label = stringr::str_flatten(label, "<div>&nbsp;</div>"),
      .by = c(week_number, unit)
    ) |>
    tidyr::pivot_wider(
      names_from = unit,
      values_from = label
    ) |>
    tidyr::fill(tidyselect::any_of("part"))

  weekly_schedule <- lectures_and_labs |>
    dplyr::left_join(
      other_units,
      by = dplyr::join_by(week_number),
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      week = highlight_current_week(current_week, as.character(week_number))
    ) |>
    dplyr::select(!c(week_number, current_week, show_week, show_exam)) |>
    dplyr::relocate(week)

  spacer <- '<span class="spacer"></span>'

  weekly_schedule |>
    gt::gt(
      groupname_col = "part",
      process_md = TRUE
    ) |>
    gt::sub_missing(missing_text = "") |>
    gt::cols_add(
      after_week_spacer = spacer,
      .after = "week"
    ) |>
    gt::cols_label(tidyselect::everything() ~ "") |>
    gt::tab_spanner(
      label = "Mon",
      columns = tidyselect::starts_with("mon_lecture"),
      id = "mon_lecture"
    ) |>
    gt::tab_spanner(
      label = "Wed",
      columns = tidyselect::starts_with("wed_lecture"),
      id = "wed_lecture"
    ) |>
    gt::tab_spanner(
      label = "Fri",
      columns = tidyselect::starts_with("fri_lecture"),
      id = "fri_lecture"
    ) |>
    gt::tab_spanner(
      label = "Lectures",
      columns = tidyselect::contains("lecture"),
      spanners = tidyselect::any_of(c("mon_lecture", "wed_lecture", "fri_lecture"))
    ) |>
    gt::tab_spanner(
      label = "Lab",
      columns = tidyselect::starts_with("lab_discussion"),
      id = "lab"
    ) |>
    gt::tab_style(
      style = gt::cell_text(size = "small"),
      locations = gt::cells_column_spanners()
    ) |>
    gt::cols_align(
      align = "left",
      columns = tidyselect::any_of("exam")
    ) |>
    gt::cols_align(
      align = "right",
      columns = c(week)
    ) |>
    gt::tab_style(
      style = list(
        gt::cell_text(weight = "bold")
      ),
      locations = list(
        gt::cells_column_labels(),
        gt::cells_column_spanners()
      )
    ) |>
    gt::fmt_markdown() |>
    gt::tab_options(
      quarto.disable_processing = TRUE,
      table.width = "100%"
    )
}
