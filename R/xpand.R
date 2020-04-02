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


#' S3 method for plotting classified archaeological sites and dates of ExPaND
#' project. It is possible to plot only the sites according to their cultural
#' affiliation or an interpolated surface with the radiocarbon ages.
#' @param sites An xpanDates object.
#' @param culture A string. The archaeological culture to be plotted. One of
#' "all", "BB" (Bacabal and related), "CC" (Cumancaya and related), "GM"
#' (Goya-Malabrigo), "HZ" (Zone-Hachured), "IP" (Incised-Punctate and related),
#' "NI" (Unclassified), "PC" (Pedra do Caboclo/Aratu), "PL" (Amazon Polychrome),
#' "SB" (Saladoid-Barrancoid and related), "TP" (Tupiguarani), "TT"
#' (Tutishcainyo and related) or "UN" (Una/Taquara/Itararé). Default is "all".
#' @param isochrones A boolean indicating whether to plot an interpolated
#' surface of radiocarbon ages. Default is FALSE.
#' @return An spplot.
#' @export
plot.xpanDates <- function(sites, culture = "all", isochrones = FALSE) {
    sites <- sites[[1]][sites[[1]]$Exclude == FALSE,]

    keys <- list(all = "All sites", BB = "Bacabal and related",
                 CC = "Cumancaya and related", GM = "Goya-Malabrigo",
                 HZ = "Zone-Hachured", IP = "Incised-Punctate and related",
                 NI = "Other (Unclassified)", PC = "Pedra do Caboclo/Aratu",
                 PL = "Amazon Polychrome",
                 SB = "Saladoid-Barrancoid and related", TP = "Tupiguarani",
                 TT = "Tutishcainyo and related", UN = "Una/Taquara/Itararé")

    if (culture == "all") {
        attr <- "Class"
    } else {
        sites <- sites[sites$Class == culture,]
        # Get rid of parentheses with cultural subdivisions, keep only the
        # broader classification.
        sites$Culture <- gsub(" \\(.+", "", sites$Culture)
        sites$Culture <- factor(sites$Culture)
        attr <- "Culture"
    }

    if (isochrones == TRUE) {
        sites <- filterDates(sites, "C14Age", 100)
        sites.idw <- mask(interpolateIDW(sites, "C14Age"), sam)
        borders <- list("sp.polygons", sam, first = FALSE)
        plt <- spplot(sites.idw, xlim=c(-82, -34), ylim=c(-56, 13),
                      col.regions = magma(24), sp.layout = borders,
                      colorkey = list(width = 1, space = "bottom"),
                      xlab = list("C14 BP", cex = 0.75),
                      par.settings = list(axis.line = list(col = "transparent"),
                                          layout.heights = list(xlab.key.padding = 1)),
                      main = list(label = keys[culture], cex = 1))
    } else {
        borders <- list("sp.polygons", sam)
        plt <- spplot(sites, attr, xlim = c(-82, -34), ylim = c(-56, 13),
                      col.regions = kelly()[4:22], cex = 0.5, sp.layout = borders,
                      par.settings = list(axis.line = list(col = "transparent")),
                      main = list(label = keys[culture], cex = 1))
        names(plt$legend) <- "right"
    }

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
#' }
"xpand"