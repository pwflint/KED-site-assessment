# Renders the fictional sample payload so the report layout can be reviewed without
# running the acquisition pipeline. Run from the repo root:
#   Rscript R/report/build_sample.R
source("R/report/render_report.R")
out <- render_site_assessment("R/report/sample_payload.json")
cat("Wrote", out, "\n")
