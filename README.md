# CPSC 221

The main feature of this course template is a landing page with a schedule table allowing students to navigate to all the course materials.
Website is automatically deployed using GH Actions to GitHub Pages.

This site is based on the [course-template](https://github.com/stephan-koenig/course-template) used by [UBC-CS/ai-100](https://github.com/UBC-CS/ai-100).

## Edit the template

There are a few things you need to do to adapt this template for your course.

1. In `_variables.yml`, fill in the `<TODO-...>` placeholders — course code/title/term/dates, instructor contact, building/room, and links (Canvas, PrairieLearn, etc.). Variables are used across the entire Quarto project using the shortcode `{{< var <key> >}}` (reference sub-keys with `.`, e.g. `course.code`; [more details](https://quarto.org/docs/authoring/variables.html#var)). `course.monday-of-the-first-term-week` must be set (format `YYYY-MM-DD`) since it's used to calculate dates in the schedule table.

2. The `_quarto.yml` file controls [Quarto project settings](https://quarto.org/docs/projects/quarto-projects.html) including [website options (such as navigation)](https://quarto.org/docs/reference/projects/websites.html). Fill in the `<TODO-...>` sidebar resource links.

3. To enable the schedule table, provide week numbers and day of the week for each unit in `/data/schedule.csv`.

4. Any extra resources that aren't Quarto documents (e.g. lecture recordings, PrairieLearn links) go in `/data/additional-resources.csv`.

5. `index.qmd` (syllabus) and `schedule.qmd` still contain `<!-- TODO -->` markers where CPSC 221-specific content needs to be written in.

## Website notes

The course schedule is dynamically generated from the files in the directories `pre-activities`, `activities`, `slides` and `summaries` using R (specifically, `render_schedule()` in `/R/render-schedule.csv`).
Having documents organized this way allows them to be formatted with `_metadata.yml` files in their directories.

- There are six different types of `<unit>`s: `part`, `week`, `lecture`, `discussion`, `potw` and `exam`.
- There are the following `<types>` of resources: `summaries`, `pre-activities`, `activities`, `slides`, `recording`, `practice` and `link`.
- All resources belonging together have a unique `<id>` consisting of their `<unit>` followed by a two-digit number, e.g., `lecture-01`.
- Files belonging to one unit should be named following the pattern: `<id>_<type>`.
- `id` is a unique identifier to join resources for all related resources to generate the schedule table.
- The titles of `part` documents are used as headings in the course schedule.

## Setup

Quarto and R need to be installed locally to render the site (`quarto render` or `quarto preview`). Python dependencies are managed with [uv](https://docs.astral.sh/uv/); R dependencies with [renv](https://rstudio.github.io/renv/).

Different versions of the website are rendered to different subdirectories by defining Quarto project profiles. To render a profile, it has to be added to the GitHub Actions step (`.github/workflows/main.yml`).

| Target audience                        | Quarto project profile(s) | Website subdirectory   | Content                  | Lesson plans |
| --------------------------------------- | -------------------------- | ----------------------- | ------------------------- | ------------- |
| Student                                | `student`                 | `/`                    | Do not show future weeks | No           |
| Student with accessibility needs       | `student,access`          | `/access`              | Do not show future weeks | No           |
| Instructor                             | `instructor`              | `/instructor`          | All                      | Yes          |
| Teaching assistant (TA)                | `ta`                      | `/ta`                  | All                      | Yes          |
| Coordinator                            | `coordinator`             | `/coordinator`         | All                      | Yes          |

## Attribution

The course template can be found at <https://github.com/stephan-koenig/course-template> and is based on:

- [STA 199 by Mine Çetinkaya-Rundel](https://sta199-s24.github.io/)
- [ESPM 157 by Carl Boettinger](https://espm-157.carlboettiger.info/)
- [STA 112 by Lucy D'Agostino McGowan](https://sta-112-s24.github.io/website/)
- [PMAP 8521 by Andrew Heiss](https://evalsp25.classes.andrewheiss.com/)

Some slides design was adapted from:

- [rstudio::conf-2022 Workshop on Quarto by Tom Mock et al.](https://github.com/rstudio-conf-2022/get-started-quarto)
