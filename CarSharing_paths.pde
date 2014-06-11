
import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.utils.*;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.data.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.core.Coordinate;
import java.util.List;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.*;
import java.util.concurrent.TimeUnit;
import java.text.SimpleDateFormat;
import java.text.ParseException;
import de.fhpotsdam.unfolding.providers.*;


SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.ENGLISH);
SimpleDateFormat format2 = new SimpleDateFormat("yyyy/MM/dd HH:mm", Locale.ENGLISH);

UnfoldingMap map;
List<Marker> transitMarkers = new ArrayList<Marker>();
List<Marker> addedMarkers = new ArrayList<Marker>();
List<Marker> newMarkers = new ArrayList<Marker>();
MarkerManager<Marker> markerManager;
color c = color(232, 193, 2, 15);
Date start = new Date(1393192800000L);
Date end=new Date(1393736400000L);
List<Feature> transitLines;
Giorgio giorgio= new Giorgio();

void setup() {
  size(1920, 1080, OPENGL);
  smooth();
  println(giorgio);
  map = new UnfoldingMap(this, giorgio);
  markerManager = map.getDefaultMarkerManager();
  map.zoomAndPanTo(new Location(45.467117286247066, 9.187265743530346), 13);
  MapUtils.createDefaultEventDispatcher(this, map);

  transitLines = GeoJSONReader.loadData(this, "all_rents_geojson.json");

  // Create markers from features, and use LINE property to color the markers.
}

void draw() {
  if (start.before(end)) {
    newMarkers.clear();
    println("start date "+start);
    
    Iterator<Marker> i = addedMarkers.iterator();
    Iterator<Feature> j = transitLines.iterator();
    
    //************************
    while (j.hasNext ()) {
      Feature f = j.next(); // must be called before you can call i.remove()
      if(f.getStringProperty("start")=="") {
        j.remove();
        
      }
    }
    //************************
    


    //****************************
    while (i.hasNext ()) {
      Marker s = i.next(); // must be called before you can call i.remove()
      Date currend=new Date();
      try {
        currend=format.parse(s.getStringProperty("end"));
      }
      catch (ParseException e) {
        println("end");
        println(e);
      }
      if (currend.before(start)) {
        markerManager.removeMarker(s);
        i.remove();
        
      }
    }
    //*****************************



    for (Feature feature : transitLines) {

      Date curr=new Date();
      if (feature.getProperty("start")!="") {
        try {
          curr=format.parse(feature.getStringProperty("start"));
        }
        catch (ParseException e) {
          println("start");
          println(e);
        }

        if (curr.before(start)) {
         
          feature.putProperty("start", "");

          ShapeFeature lineFeature = (ShapeFeature) feature;
          SimpleLinesMarker m = new SimpleLinesMarker(lineFeature.getLocations());
          m.setColor(c);
          m.setProperties(feature.getProperties());
          m.setStrokeWeight(2);
          addedMarkers.add(m);
          newMarkers.add(m);
          //transitMarkers.add(m);
        } else {
          break;
        }

        
        
      }
    }
    map.addMarkers(newMarkers);
    start = new Date(start.getTime() + TimeUnit.SECONDS.toMillis(60));
    textSize(32);
    fill(232, 193, 2, 255);
    map.draw();
    //text(format2.format(start), 35, 35);
    
  } else {
    background(255);
    text("THE END", 30, 30);
  }
}

public void keyPressed() {
   
    if (key == 'c') {
      markerManager.clearMarkers();
    }
  }

class Giorgio extends MapBox.MapBoxProvider {
  
Giorgio() {
  super();
};
  
  public String[] getTileUrls(Coordinate coordinate) {
    println(getZoomString(coordinate));
    String url = "http://api.tiles.mapbox.com/v1/giorgiouboldi.ifkdj2f1/"+ getZoomString(coordinate) + ".jpg";
    return new String[] { 
      url
    };
  }
}

