import java.util.*;
import proxml.*;
import processing.serial.*;
import cc.arduino.*;

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
int[] APImentions = new int[3];
int[] APIstatus = new int[3];

//Arduino object
Arduino arduino;
int ledPin = 13;
int buttonPin = 7;
int pastState = 0;
int pressCount = 0;

void setup() {
  
  size(100,100);
  background(0);

  //load XML file
  xmlFile = new XMLInOut(this);
  xmlFile.loadElement("config.xml");

  println("---- Initializing Twitter Client -------");

  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  
  arduino.pinMode(ledPin, Arduino.OUTPUT);
  arduino.pinMode(buttonPin, Arduino.INPUT);
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

//get "@" replies
void getMentions(){
  println("loading and processing tweets");

  //get all the "@" messages
  mentions = twitter.getMentionsTimeline(1,1);
  
  //loop through all messages and look for 
  //our desired string on each message
  for (int i = 0; i<mentions.size(); i++){
    Status status = (Status)mentions.get(i);
    println("---- new tweet -----");
    //extract data from tweet
    String username = status.getUser().getName();
    String screenName = status.getUser().getScreenName();
    String msg = status.getText();
    println("username: " + screenName + " text: " + msg);

    matchCommand(msg, screenName);
  }
}

void matchCommand(String tweet, String sender){
  String[] result1 = match(tweet, "led on");
  String[] result2 = match(tweet,"led off");
  String message = sender;
  
  if(result1 != null && result2 == null){
    //turn on the led and send reply
    arduino.digitalWrite(ledPin, Arduino.HIGH);
    message += " the LED is ON"; 
    println("Tuning LED ON");
  } else if (result1 ==null && result2 !=null){
    arduino.digitalWrite(ledPin, Arduino.LOW);
    message += " the LED is OFF";
    println("Tuning LED OFF");
  } else {
    message += " sorry, I don't understand :(";
    println("Unmatched string");
  }
    sendTweet(message);
}

void checkButton(){
  int currentState = arduino.digitalRead(buttonPin);
  println(currentState);
  if(currentState == 1 && pastState == 0){
    pressCount++; // add 1 to the press count
    println("button was just pressed");
    println("button has been pressed " + str(pressCount) + " times.");
  }
  //update past reading
  pastState = currentState;
}

void draw() {
  if (connected){
    //check status
    APImentions = twitter.getRateLimitStatus("/statuses/mentions_timeline");
    
    if(APImentions[1] > 0 ){
      getMentions();
      delay(30000);
    } else {
      println("Waiting "+ APImentions[2] + " seconds until next query");
      delay(1000);
    }
  }
}





