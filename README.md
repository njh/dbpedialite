<div class="gone">
dbpedia lite is no-more.
What it was attempting to do is now handled much better by <a href="http://www.wikidata.org/">Wikidata</a>.

Pages now redirect to the equivalent Wikidata pages.
</div>


[dbpedia lite](http://www.dbpedialite.org) used to take some of the structured data in [Wikipedia](http://wikipedia.org/) and presents it as [Linked Data](http://linkeddata.org/). It contained a small subset of the data that [dbpedia](http://dbpedia.org/) contains; it did not attempt to extract data from the Wikipedia infoboxes. Data is fetched live from the [Wikipedia API](http://en.wikipedia.org/w/api.php).

Unlike dbpedia is it uses stable Wikipedia pageIds in its URIs to attempt to mitigate the problems of article titles changing over time. If the title of a Wikipedia page changes, the dbpedia lite URI will stay the same. This makes it safer to store dbpedia lite identifiers in your own database.
