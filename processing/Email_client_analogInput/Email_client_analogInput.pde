/*
Mail Client and analog input, callibration and edge detection. 
Developed for Networked Objects workshop at FoamCity ( http://foamcity.org )
January - 2013

http://martinez-zea.info
*/

import java.util.Properties;
//import java mail lib
import javax.mail.*;
import javax.mail.internet.*;
//import serial lib
import processing.serial.*;
//import XML lib
import proxml.*;


/*
As of 22/01/2013 the official Arduino library doesn't work with 
Processing 2.0 or higher, the following version has been tested with 
2.0b7 and seems to work fine:

https://github.com/pardo-bsso/processing-arduino
*/


import cc.arduino.*;

Arduino arduino;
Message lastMessage;
int lastMessageCount;
boolean firstCheck = true;

XMLElement configuration;
XMLInOut xmlFile;

//Username
String email;
//SMTP server address
String smtp_host;
//IMAP server address
String imap_host;
//Password
String pass;

int photoPin = 0;
int pastState = 0;
int pressCount = 0;

//caibration variables
int sensMin = 1023;
int sensMax = 0;
int sensVal = 0;
int threshold = 0;

void setup() {
  size(200,200);

  //load XML file
  xmlFile = new XMLInOut(this);
  xmlFile.loadElement("config.xml");
  
  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  
  arduino.pinMode(photoPin, Arduino.INPUT);
  
  //calibration
  while(millis() < 5000){
    println("Calibrating ...");
    sensVal = arduino.analogRead(photoPin);
    if(sensVal > sensMax){
      sensMax = sensVal;
    }
    if(sensVal < sensMin){
      sensMin = sensVal;
    }
  }
  //the middle value between min and max is our threshold
  threshold = sensMin + ((sensMax - sensMin)/2);
  
}

void xmlEvent(XMLElement element){
  configuration = element;

  XMLElement login = configuration.getChild(0);

  email = login.getAttribute("username");
  pass = login.getAttribute("password");
  smtp_host = login.getAttribute("smtp");
  imap_host = login.getAttribute("imap");
  
}

void draw(){
  background(0);
  
  int photoRead = arduino.analogRead(photoPin);
  //println(val);
  
  int currentState;
  if(photoRead > threshold){
    currentState = 1;
  }else{
    currentState = 0;
  }
  //println(currentState);
  if(currentState == 1 && pastState == 0){
    pressCount++; // add 1 to the press count
    println("button was just pressed");
    println("button has been pressed " + str(pressCount) + " times.");
  }
  //update past reading
  pastState = currentState;
  
  //After some presses, send an email
  if(pressCount > 20){
    sendMail("networked.objects@gmail.com", "networked.objects@gmail.com", "button pressed", "Threshold has been passed " + str(pressCount) + " times.");
    pressCount = 0;
  }
}


/*
Check incoming email
*/

void checkMail() {
  try {
    
    Properties props = new Properties();

    
    props.put("mail.imap.port", "993");
    
    //security
    /*
    props.put("mail.imap.starttls.enable", "true");
    props.setProperty("mail.imap.socketFactory.fallback", "false");
    props.setProperty("mail.imap.socketFactory.class","javax.net.ssl.SSLSocketFactory");
    */
    props.setProperty("mail.store.protocol", "imaps");
    
    //Create a new session
    Session receive_session = Session.getDefaultInstance(props, null);
    Store store = receive_session.getStore("imaps");
    store.connect(imap_host, email, pass);
    
    //Get Inbox information
    Folder folder = store.getFolder("INBOX");
    folder.open(Folder.READ_ONLY);
    System.out.println(folder.getMessageCount() + " total messages.");

    if(lastMessageCount < folder.getMessageCount()){
      if(firstCheck){
        println("first check");
        lastMessageCount = folder.getMessageCount();
        lastMessage = folder.getMessages()[folder.getMessageCount() - 1];
        firstCheck = false;
        
      }else{
        println("regular check");
        int newMessageCount = abs(folder.getMessageCount() - lastMessageCount);
        lastMessage = folder.getMessages()[folder.getMessageCount() - 1];
        lastMessageCount = folder.getMessageCount();
      }

        println("--------- BEGIN MESSAGE------------");
        println("From: " + lastMessage.getFrom()[0]);
        println("Subject: " + lastMessage.getSubject());
        String subject = lastMessage.getSubject().toString();
        println("Message:");
        String content = lastMessage.getContent().toString(); 
        println(content);
        println("--------- END MESSAGE------------");

    }else{
      println("You don't have new messages");
    }
    
    // Close session
    folder.close(false);
    store.close();
  } 
  // Basic error handler
  catch (Exception e) {
    e.printStackTrace();
  }
}
// Send email through the SMTP server
void sendMail(String to, String from, String subject, String body) {

  Properties props=new Properties();

  // SMTP Session for Gmail
  
  props.put("mail.transport.protocol", "smtp");
  props.put("mail.smtp.host", smtp_host);
  props.put("mail.smtp.port", "587");
  props.put("mail.smtp.auth", "true");
  
  // TLS setting for Gmail
  props.put("mail.smtp.starttls.enable","true");
 
  /*
  //SSL configuration
  props.put("mail.transport.protocol", "smtps");
  props.put("mail.smtp.host", server);
  props.put("mail.smtp.socketFactory.port", "587");
  props.put("mail.smtp.socketFactory.class", "javax.net.ssl.SSLSocketFactory");
  props.put("mail.smtp.socketFactory.fallback", "false");
  */
 
  // Creates new session
  Session send_session = Session.getInstance(props, null);

  try
  {
    // Create new message
    MimeMessage message = new MimeMessage(send_session);

    // Define sender
    message.setFrom(new InternetAddress(email, from));

    // Define recipient
    message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to, false));

    // Set the subject
    message.setSubject(subject);
    // Set body 
    message.setText(body);
    
    
    //Authenticate to the SMTP server
    Transport transport = send_session.getTransport("smtp");
    transport.connect(smtp_host, 587, email, pass );
    //Send E-mail
    transport.sendMessage(message, message.getAllRecipients());
    //Close connection
    transport.close(); 
   
    println("Mail sent to: " + to);
 
}
  //Basic error handler
  catch(Exception e)
  {
    e.printStackTrace();
  }
}

void keyReleased(){
  if(key == 's'){
    sendMail("networked.objects@gmail.com", "networked-objects", "test", "hello world");
  }
}




