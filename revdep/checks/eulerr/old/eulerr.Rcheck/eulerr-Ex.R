pkgname <- "eulerr"
source(file.path(R.home("share"), "R", "examples-header.R"))
options(warn = 1)
library('eulerr')

base::assign(".oldSearch", base::search(), pos = 'CheckExEnv')
base::assign(".old_wd", base::getwd(), pos = 'CheckExEnv')
cleanEx()
nameEx("error_plot")
### * error_plot

flush(stderr()); flush(stdout())

### Name: error_plot
### Title: Error plot for 'euler' objects
### Aliases: error_plot

### ** Examples

error_plot(euler(organisms), quantities = FALSE)



cleanEx()
nameEx("euler")
### * euler

flush(stderr()); flush(stdout())

### Name: euler
### Title: Area-proportional Euler diagrams
### Aliases: euler euler.default euler.data.frame euler.matrix euler.table
###   euler.list

### ** Examples

# Fit a diagram with circles
combo <- c(A = 2, B = 2, C = 2, "A&B" = 1, "A&C" = 1, "B&C" = 1)
fit1 <- euler(combo)

# Investigate the fit
fit1

# Refit using ellipses instead
fit2 <- euler(combo, shape = "ellipse")

# Investigate the fit again (which is now exact)
fit2

# Plot it
plot(fit2)

# A set with no perfect solution
euler(c(
  "a" = 3491, "b" = 3409, "c" = 3503,
  "a&b" = 120, "a&c" = 114, "b&c" = 132,
  "a&b&c" = 50
))


# Using grouping via the 'by' argument through the data.frame method
euler(fruits, by = list(sex, age))


# Using the matrix method
euler(organisms)

# Using weights
euler(organisms, weights = c(10, 20, 5, 4, 8, 9, 2))

# The table method
euler(pain, factor_names = FALSE)

# A euler diagram from a list of sample spaces (the list method)
euler(plants[c("erigenia", "solanum", "cynodon")])



cleanEx()
nameEx("eulerr_options")
### * eulerr_options

flush(stderr()); flush(stdout())

### Name: eulerr_options
### Title: Get or set global graphical parameters for eulerr
### Aliases: eulerr_options

### ** Examples

eulerr_options(edges = list(col = "blue"), fontsize = 10)
eulerr_options(n_threads = 2)



cleanEx()
nameEx("plot.euler")
### * plot.euler

flush(stderr()); flush(stdout())

### Name: plot.euler
### Title: Plot Euler and Venn diagrams
### Aliases: plot.euler plot.venn

### ** Examples

fit <- euler(c("A" = 10, "B" = 5, "A&B" = 3))

# Customize colors, remove borders, bump alpha, color labels white
plot(fit,
     fills = list(fill = c("red", "steelblue4"), alpha = 0.5),
     labels = list(col = "white", font = 4))

# Add quantities to the plot
plot(fit, quantities = TRUE)

# Add a custom legend and retain quantities
plot(fit, quantities = TRUE, legend = list(labels = c("foo", "bar")))

# Plot without fills and distinguish sets with border types instead
plot(fit, fills = "transparent", lty = 1:2)

# Save plot parameters to plot using some other method
diagram_description <- plot(fit)

# Plots using 'by' argument
plot(euler(fruits[, 1:4], by = list(sex)), legend = TRUE)



cleanEx()
nameEx("print.euler")
### * print.euler

flush(stderr()); flush(stdout())

### Name: print.euler
### Title: Print a summary of an Euler diagram
### Aliases: print.euler

### ** Examples

euler(organisms)



cleanEx()
nameEx("print.venn")
### * print.venn

flush(stderr()); flush(stdout())

### Name: print.venn
### Title: Print a summary of a Venn diagram
### Aliases: print.venn

### ** Examples

venn(organisms)



cleanEx()
nameEx("venn")
### * venn

flush(stderr()); flush(stdout())

### Name: venn
### Title: Venn diagrams
### Aliases: venn venn.default venn.table venn.data.frame venn.matrix
###   venn.list

### ** Examples

# The trivial version
f1 <- venn(5, names = letters[1:5])
plot(f1)

# Using data (a numeric vector)
f2 <- venn(c(A = 1, "B&C" = 3, "A&D" = 0.3))

# The table method
venn(pain, factor_names = FALSE)

# Using grouping via the 'by' argument through the data.frame method
venn(fruits, by = list(sex, age))


# Using the matrix method
venn(organisms)

# Using weights
venn(organisms, weights = c(10, 20, 5, 4, 8, 9, 2))

# A venn diagram from a list of sample spaces (the list method)
venn(plants[c("erigenia", "solanum", "cynodon")])



### * <FOOTER>
###
cleanEx()
options(digits = 7L)
base::cat("Time elapsed: ", proc.time() - base::get("ptime", pos = 'CheckExEnv'),"\n")
grDevices::dev.off()
###
### Local variables: ***
### mode: outline-minor ***
### outline-regexp: "\\(> \\)?### [*]+" ***
### End: ***
quit('no')
