# maintainer: Hyoungchul Kim
# date: 2025-09-10
# purpose: create histogram of the fixed effects

if (!require(pacman)) install.packages("pacman")
pacman::p_load(here, data.table, R.utils, fixest, broom, texreg, tidyfast, argparse, yaml, glue, tigris, dplyr, ggplot2, sf)


parser <- ArgumentParser()
parser$add_argument("--input", type = "character")
args <- parser$parse_args()

# read yaml
input_yaml <- read_yaml(args$input)

# load the data
linear_q3 <- fread(here("input", input_yaml$fes$linear_model),
    colClasses = list(character = c("tract", "var"))
)

linear_q5 <- fread(here("input", "temp", input_yaml$fes$linear_model_solution2),
    colClasses = list(character = c("tract", "var"))
)

ppml_q4 <- fread(here("input", input_yaml$fes$ppml),
    colClasses = list(character = c("tract", "var"))
)

ppml_q5 <- fread(here("input", "temp", input_yaml$fes$ppml_solution2),
    colClasses = list(character = c("tract", "var"))
)

# create boxplot of the fixed effects. we will combine the data and plot them in one plot and use color to differentiate the models.

ggplot(rbind(linear_q3[, var := "linear_q3"], linear_q5[, var := "linear_q5"], ppml_q4[, var := "ppml_q4"], ppml_q5[, var := "ppml_q5"]), aes(x = var, y = value, fill = var)) +
    geom_boxplot(alpha = 0.7) +
    labs(
        title = "Boxplot of the fixed effects",
        x = "Model",
        y = "Fixed Effect Value"
    ) +
    scale_fill_manual(values = c("pink", "skyblue", "purple", "green"), labels = c("linear_q3" = "Linear Model (Q3)", "linear_q5" = "Linear Model (Q5)", "ppml_q4" = "PPML Model (Q4)", "ppml_q5" = "PPML Model (Q5)")) +
    theme(legend.position = "none")
ggsave(here("output", "figures", "histogram_fixef.png"), width = 10, height = 10)
