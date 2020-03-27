# xpandR
<h2>Radiocarbon dates for the spread of farming and ceramics in tropical South America</h2>
<img src="img/ds.png" width=100 align="left"></img>
<p>This package contains a dataset with 2794 radiocarbon dates from 1035 archaeological sites in lowland South America. In principle, only archaeological cultures related to the spread of polyculture agroforestry (tropical forest farming) and ceramics are represented. The dataset has been compiled and is continuously updated as part of the project <a href="https://amazonexpand.wixsite.com/expand">ExPaND: Examining Pan-Neotropical Diasporas</a> funded by the European Commission H2020.</p>
<h3>Installation</h3>
<p>To install from the github repository:</p>
<pre><code>devtools::install_github("jgregoriods/xpandR")</pre></code>
<h3>Data</h3>
<p>The data are stored in the object <i>xpand</i>, a SpatialPointsDataFrame. Variables are the following:</p>
<ul>
  <li><b>Site:</b> Site name and code (if available).</li>
  <li><b>C14Age:</b> The radiocarbon date(s) for the site.</li>
  <li><b>C14SD:</b> Standard error of the radiocarbon determination.</li>
  <li><b>LabCode:</b> Laboratory code, if available.</li>
  <li><b>Material:</b> The material dated, i.e. wood charcoal, marine shell, human bone etc.</li>
  <li><b>Culture:</b> Cultural affiliation of the site or dated level. See below for a summary of archaeological cultures.</li>
  <li><b>Description:</b> Brief description of the archaeological site, if available.</li>
  <li><b>Comments:</b> Mainly comments about problems with the context or radiocarbon measurement, if there are any.</li>
  <li><b>Reference:</b> Reference for the date in author-year format.</li>
  <li><b>FullReference</b> Full bibliographic reference.</li>
  <li><b>Exclude:</b> A boolean deciding whether the date should be excluded from analyses based on the best judgement of the original publisher or general consensus of the archaeological community in the present.</li>
</ul>
<p>The data are made available in SpatialPoints* format to facilitate spatial analyses in R.</p>
<pre><code>data(xpand)
data(sam) #South American country borders
plot(sam)
plot(xpand, add=TRUE, cex=0.5, col="red")</pre></code>
<img src="img/plotsites.png" width=200></img>
<h2>Archaeological cultures and chronology</h2>
<p>A second dataset, <i>xpandClass</i>, is classified according to a broad taxonomic scheme devised to simplify the myriad of archaeological cultures in late Holocene tropical South America. The following codes are employed:</p>

<p>The package comes with some in-built methods for simple visualization of the classified data. They allow one to do a first exploration of trends in the radiocarbon dates. To visualize the distribution of archaeological cultures, one can select all sites and the broad classification scheme, or a single taxonomic unit in order to show its cultural components.</p>
<pre><code>data(xpandClass)
plot(xpandClass)</pre></code>
<img src="img/all.png" height=300></img>
<pre><code>plot(xpandClass, "SB")  #Saladoid-Barrancoid subset</pre></code>
<img src="img/sb.png" height=300></img>
<p>To explore spatial trends in the distribution of radiocarbon dates, there is the option of plotting an isochrone map - based on inverse distance weighting and considering only the earliest dates in a radius of 100 km.</p>
<pre><code>plot(xpandClass, "SB", isochrones=TRUE)</pre></code>
