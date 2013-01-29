import java.util.*;
import proxml.*;

//Our Twitter client Object
TwC twitter;

//Twitter Auth keys
String OAuthConsumer;
String OAuthConsumerSecret;
String AccessToken;
String AccessTokenSecret;

//XML vars
XMLElement configuration;
XMLInOut xmlFile;
boolean connected = false; 

//global vars to store results
ArrayList searchResult;
ArrayList mentions;
ArrayList timeline;

void setup() {
  
  size(100,100);
  background(0);

  //load XML file
  xmlFile = new XMLInOut(this);
  xmlFile.loadElement("config.xml");

  println("---- Initializing Twitter Client -------");

}

//Extract configuration data from XML
void xmlEvent(XMLElement element){
  println("loading configuration");

  configuration = element;
  XMLElement login = configuration.getChild(0);

  OAuthConsumer = login.getAttribute("OAuthConsumer");
  OAuthConsumerSecret = login.getAttribute("OAuthConsumerSecret");
  AccessToken = login.getAttribute("AccessToken");
  AccessTokenSecret = login.getAttribute("AccessTokenSecret");

  connect();
}

//connect to Twitter
void connect(){
  println("Connecting with Twitter server");
  //Create new object with our Twitter credentials
  twitter = new TwC(OAuthConsumer,
                  OAuthConsumerSecret,
                  AccessToken,
                  AccessTokenSecret 
                  );
  //Make a connection
  twitter.connect();
  connected = true;
}

//post new tweet
void sendTweet(String msg){
  twitter.send(msg);
}

//get user timeline
void getTimeLine(){
  timeline = twitter.getTimeline();
  for (int i = 0; i<timeline.size(); i++){
    Status status = (Status)timeline.get(i);
    String username = status.getUser().getName();
    String msg = status.getText();
    println("username: " + username + " text: " + msg);
  }
}

//get "@" replies
void getMentions(){
  mentions = twitter.getMentionsTimeline();
  for (int i = 0; i<mentions.size(); i++){
    Status status = (Status)mentions.get(i);
    String username = status.getUser().getName();
    String msg = status.getText();
    println("username: " + username + " text: " + msg);
  }
}

void search(String query){
  searchResult = twitter.search(query);
  for (int i=0; i<searchResult.size(); i++) { 
    Status status = (Status)searchResult.get(i);  
    String user = status.getUser().getName();
    println("username: "+user);
    String msg = status.getText();
    println("tweet:" + msg);
    Date d = status.getCreatedAt();
    long id = status.getId(); 
    println("id: "+id);
  }
}

void draw() {
  if (connected){
    //post new tweet
    sendTweet("hello World " + str(random(0, 100)));

    //get TimeLine
    getTimeLine();

    //get Mentions
    getMentions();

    //Query Twitter search API
    search("#testing");
  }

  delay(3000);
}





