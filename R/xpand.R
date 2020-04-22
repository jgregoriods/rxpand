library(dplyr)
library(gstat)
library(pals)
library(raster)
library(rgdal)
library(viridisLite)

#' Filter archaeological site coordinates and dates, retaining only the
#' earliest radiocarbon date per site or per region if a radius is specified.
#'
#' @param sites A SpatialPointsDataFrame object with archaeological sites and
#' associated radiocarbon ages.
#' @param c14bp A string. Name of the field with the radiocarbon ages in C14 BP
#' format.
#' @param dist A number. Radius in km to filter for the earliest dates in a
#' region. Default is 0, i.e. the earliest dates of all sites are retained.
#' @return A SpatialPointsDataFrame object with the earliest C14 date for every
#' site.
#' @export
filterDates <- function(sites, c14bp, dist = 0) {
    x <- c(colnames(coordinates(sites)))[1]
    y <- c(colnames(coordinates(sites)))[2]

    clusters <- zerodist(sites, zero = dist, unique.ID = TRUE)

    sites$clusterID <- clusters
    sites.df <- as.data.frame(sites)
    sites.max <- as.data.frame(sites.df %>% group_by(clusterID) %>%
                               top_n(1, get(c14bp)))

    xy <- cbind(sites.max[[x]], sites.max[[y]])

    sites.max.spdf <- SpatialPointsDataFrame(xy, sites.max)
    proj4string(sites.max.spdf) <- proj4string(sites)

    return(sites.max.spdf)
}

#' Interpolate radiocarbon dates using inverse distance weighting.
#' @param sites A SpatialPointsDataFrame object with archaeological sites and
#' associated radiocarbon ages.
#' @param c14bp A string. Name of the field with the radiocarbon ages in C14 BP
#' format.
#' @return A RasterLayer with interpolated C14 ages.
interpolateIDW <- function(sites, c14bp) {
    grd <- as.data.frame(spsample(sites, "regular", n = 50000))
    names(grd) <- c("x", "y")
    coordinates(grd) <- ~x+y
    proj4string(grd) <- proj4string(sites)
    gridded(grd) <- TRUE
    fullgrid(grd) <- TRUE

    sites.idw <- idw(get(c14bp) ~ 1, sites, newdata = grd, idp = 2.0)
    return(raster(sites.idw))
}

#' Plots an interpolated surface with the radiocarbon ages of archaeological
#' sites.
#' @param sites A SpatialPointsDataFrame object.
#' @param c14bp A string. Name of the field with the radiocarbon ages in C14 BP
#' format.
#' @return An spplot.
#' @export
isoPlot <- function(sites, c14bp, title="All sites") {
    sites <- filterDates(sites, c14bp, 100)
    sites.idw <- mask(interpolateIDW(sites, c14bp), sam)
    borders <- list("sp.polygons", sam, first = FALSE)
    plt <- spplot(sites.idw, xlim=c(-82, -34), ylim=c(-56, 13),
                  col.regions = magma(24), sp.layout = borders,
                  colorkey = list(width = 1, space = "bottom"),
                  xlab = list("C14 BP", cex = 0.75),
                  par.settings = list(axis.line = list(col = "transparent"),
                                      layout.heights = list(xlab.key.padding = 1)),
                  main = list(label = title, cex = 1))
    return(plt)
}

#' South American country borders from NaturalEarth.
#' 
#' @format A SpatialPolygonsDataFrame.
"sam"

#' Radiocarbon dates and coordinates of 1023 archaeological sites in lowland
#' South America associated with the spread of ceramics and tropical forest
#' farming.
#' 
#' @format A SpatialPointsDataFrame with 2762 features and 11 variables.
#' \itemize{
#'   \item Site. Site name.
#'   \item C14Age. Date in C14 years BP.
#'   \item C14SD. Standard error of the radiocarbon date.
#'   \item LabCode. Laboratory code of the C14 date.
#'   \item Material. Material dated (Charcoal, shell etc.).
#'   \item Culture. Cultural affiliation (Saladoid, Incised-Punctate,
#'                  Tupiguarani etc).
#'   \item Description. Summary description of the archaeological site.
#'   \item Comments. Comments mainly about problems with the C14 date.
#'   \item Reference. Author-date reference for the C14 date.
#'   \item FullReference. Full bibliographic reference.
#'   \item Exclude. TRUE or FALSE based on general consensus or problems with
#'                  the C14 date.
#'   \item Class. A simpler classification of the various archaeological
#'                cultures into few classes. Experimental.
#' }
"xpand"