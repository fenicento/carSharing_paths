
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
SimpleDateFormat format2 = new SimpleDateFormat("yyyy/MM/dd  HH:mm", Locale.ENGLISH);

UnfoldingMap map;
List<Marker> transitMarkers = new ArrayList<Marker>();
List<Marker> addedMarkers = new ArrayList<Marker>();
List<Marker> newMarkers = new ArrayList<Marker>();
List<Car> addedCars = new ArrayList<Car>();
List<Car> newCars = new ArrayList<Car>();
MarkerManager<Marker> markerManager;
color c = color(232, 193, 2, 15);
Date start = new Date(1393192800000L);
Date end = new Date(1393736400000L);
List<Feature> transitLines;
Giorgio giorgio= new Giorgio();
PFont raleway  = createFont("Raleway-Bold", 32);

void setup() {
  size(1920, 1080, OPENGL);
  smooth();
  map = new UnfoldingMap(this, giorgio);
  markerManager = map.getDefaultMarkerManager();
  map.zoomAndPanTo(new Location(45.467117286247066, 9.187265743530346), 13);
  MapUtils.createDefaultEventDispatcher(this, map);

  transitLines = GeoJSONReader.loadData(this, "all_rents_geojson.json");

  // Create markers from features, and use LINE property to color the markers.
  map.draw();
}

void draw() {
  
  if(millis()<10000) {
    map.draw();
    return;
  }
  
  if (start.before(end)) {
    newMarkers.clear();
    newCars.clear();

    Iterator<Marker> i = addedMarkers.iterator();
    Iterator<Car> z = addedCars.iterator();
    Iterator<Feature> j = transitLines.iterator();

    //************************
    while (j.hasNext ()) {
      Feature f = j.next(); // must be called before you can call i.remove()
      if (f.getStringProperty("start")=="") {
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

    while (z.hasNext ()) {
      Car c = z.next(); // must be called before you can call i.remove()
      if (c.en.before(start)) {
        z.remove();
      }
    }


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



          ShapeFeature lineFeature = (ShapeFeature) feature;
          SimpleLinesMarker m = new SimpleLinesMarker(lineFeature.getLocations());
          m.setColor(c);
          List<PVector> vecs = getPixelPos(m);
          HashMap<java.lang.String, java.lang.Object> props = feature.getProperties();
          props.put("vecs", vecs);
          m.setProperties(props);
          m.setStrokeWeight(3);
          Car c = new Car(vecs, m.getStringProperty("start"), m.getStringProperty("end"));
          
          feature.putProperty("start", "");
          addedMarkers.add(m);
          newMarkers.add(m);
          addedCars.add(c);
          newCars.add(c);


          //transitMarkers.add(m);
        } else {
          break;
        }
      }
    }
    map.addMarkers(newMarkers);
    for (Car c : addedCars) {
    
      c.draw();
    
    }
    start = new Date(start.getTime() + TimeUnit.SECONDS.toMillis(60));
    textSize(32);
    fill(232, 193, 2, 255);
    map.draw();
    textFont(raleway);
    text(format2.format(start), 35, 35);
  } else {
    map.draw();
  }
  saveFrame("car-######.png");
}

public void keyPressed() {

  if (key == 'c') {
    markerManager.clearMarkers();
  }
}

public List<PVector> getPixelPos(SimpleLinesMarker m) {
  List<PVector> vecs = new ArrayList<PVector>();
  List<Location> locs = m.getLocations();
  for (Location l : locs) {
    PVector p = map.mapDisplay.getScreenPosition(l);
    vecs.add(p);
  }
  return vecs;
}


class Giorgio extends MapBox.MapBoxProvider {

  Giorgio() {
    super();
  };

  public String[] getTileUrls(Coordinate coordinate) {

    String url = "http://api.tiles.mapbox.com/v1/giorgiouboldi.ifkdj2f1/"+ getZoomString(coordinate) + ".jpg";
    return new String[] { 
      url
    };
  }
}

class Car extends SimpleLinesMarker {

  List<PVector> vecs;
  float duration;
  float dist;
  List<Float> checks = new ArrayList<Float>();
  Date st;
  Date en;

  Car() {   
    super();
  };

  Car(List<PVector> v, String s, String e) {   
    vecs=v;
    try {
      st = format.parse(s);
      en = format.parse(e);
    }
    catch(Exception ex) {
      println(ex);
    }
    long lst = st.getTime();
    long len = en.getTime();
    duration = len-lst;

    for (int i =0; i<vecs.size ()-1; i++) {
      float d = vecs.get(i).dist(vecs.get(i+1));
      dist+=d;
      checks.add(d);
    }
  };

  public String toString() {
    return "duration: "+duration/(1000*60)+" distance: "+dist+" checkPoints:"+vecs.size()+" times:"+checks.size();
  }

  public void draw() {

    if (start.before(st) || start.after(end)) {
      return;
    }
    long lstart = start.getTime();
    float passed = (lstart-st.getTime())/duration;
    float currdist = passed * dist; 
    //println("distance: "+dist+" curr distance: "+currdist+" passedPerc:"+passed);
    int n=0;
    float totdist=0;
    float diff = 0;
    for(int i = 0; i<checks.size(); i++) {
      totdist+=checks.get(i);
      if(currdist < totdist) {
        n=i-1;
        totdist-=checks.get(i);
        diff=currdist-totdist;
        break;
      }
    }
    Float currCheck = checks.get(n);
    float checkperc = diff/checks.get(n+1);
    PVector middle = PVector.lerp(vecs.get(n), vecs.get(n+1), checkperc);
   
    fill(232, 193, 2, 255);
    noStroke();
    ellipse(middle.x,middle.y,10,10);
    fill(255, 255, 255, 255);
    ellipse(middle.x,middle.y,4,4);
  }
}

