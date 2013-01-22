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

Serial ser;
Message lastMessage;
int lastMessageCount;
boolean firstCheck = true;
String[] command;


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


void setup() {
  size(200,200);
  lastMessageCount = 0;

  //load XML file
  xmlFile = new XMLInOut(this);
  xmlFile.loadElement("config.xml");
  
  //Serial Communication
  //String portName = Serial.list()[0];
  //ser = new Serial(this, portName, 9600);
  past = millis();
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
        println("Subject: " + lastMessage.getSubject());
        println("Message:");
        String content = lastMessage.getContent().toString(); 
        println(content);
        println("--------- END MESSAGE------------");

        //parse and execute 
        command = parseCommand(lastMessage.getSubject());
        executeCommand(command);

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
    sendMail("zea@randomlab.net", "networked-objects", "test", "hello world");
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

void executeCommand(String[] command){
  String name = command[0];
  String parameter = command[1];
  println("name " + name);
  println("param " + parameter);
  
  if(name.equals("led1")){
    if(parameter.equals("on")){
      //ser.write('A');
      println("request LED1 ON");
    }else if(parameter.equals("off")){
      //ser.write('B');
      println("request LED1 OFF");
    }else{
      println("parameter unknown");
    }
  }else{
    println("command unknown");
  }
}
