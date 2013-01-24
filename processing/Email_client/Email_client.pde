/*
Mail Client developed to Networked Objects workshop
FoamCity
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
String[] command;
//sender of the last message
String sender;


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

long past;

//how often do we check for new mail 
long interval = 10000;
int ledPin = 7;
int photocellPin = 0;

void setup() {
  size(200,200);
  lastMessageCount = 0;

  //load XML file
  xmlFile = new XMLInOut(this);
  xmlFile.loadElement("config.xml");
  
  past = millis();
  
  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  
  arduino.pinMode(ledPin, Arduino.OUTPUT);
  arduino.pinMode(photocellPin, Arduino.INPUT);
  
  arduino.digitalWrite(ledPin, Arduino.LOW);
  
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
  if(millis() - past > interval){
    checkMail();
    past = millis();
    println("check for new messages ....");
  }
}


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
        sender = lastMessage.getFrom()[0].toString();
        println("Subject: " + lastMessage.getSubject());
        String subject = lastMessage.getSubject().toString();
        println("Message:");
        String content = lastMessage.getContent().toString(); 
        println(content);
        println("--------- END MESSAGE------------");

        //parse and execute 
        command = parseCommand(lastMessage.getSubject());
        //executeCommand(command);
        
        /*
        *send the command to the match function
        *we make sure it's lowercase because the function
        *is not case sensitive.
        */
        
        matchCommand(subject.toLowerCase()); 

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
  if(key == 'c'){
    checkMail();
  }
}


//Parsing input data
String[] parseCommand(String message){
    String[] command = split(message, ' ');
    return command ;   
}



void matchCommand(String subject){
  String[] result1 = match(subject, "party");
  String[] result2 = match(subject,"don't");
  String message;
  if(result1 != null && result2 == null){
    message = "Let's party, yeah !!! :D ";
    println(message);
    arduino.digitalWrite(ledPin, Arduino.HIGH);
  }else if(result1 != null && result2 != null){
    message = "Party pooper :'( ";
    println(message);    
    arduino.digitalWrite(ledPin, Arduino.LOW);
  }else{
    message = "I don't get it, maybe misspelling ?";
  }
  sendMail(sender, "networked.objects@gmail.com", "Party", message);
}

void executeCommand(String[] command){
  String name = command[0];
  String parameter = command[1];
  println("name " + name);
  println("param " + parameter);
  
  if(name.equals("party")){
    if(parameter.equals("on")){
      arduino.digitalWrite(ledPin, Arduino.HIGH);
      println("request LED1 ON");
    }else if(parameter.equals("off")){
      arduino.digitalWrite(ledPin, Arduino.LOW);
      println("request LED1 OFF");
    }
  }else if(name.equals("photocell")){
      if(parameter.equals("read")){
          println("Reading photocell");
          int val = arduino.analogRead(photocellPin);
          //sendMail("networked.objects@gmail.com", "networked.objects@gmail.com", "ldr reading", "Ldr value is: " + str(val) + ".");
          sendMail(sender, "networked.objects@gmail.com", "ldr reading", "Photocell value is: " + str(val) + ".");
          println("Photocell val: " + str(val));
      } 
  }else{
    println("command unknown");
  }
}
