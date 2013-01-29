/*

Just a simple Processing and Twitter thingy majiggy

RobotGrrl.com

Code licensed under:
CC-BY

*/

// First step is to register your Twitter application at dev.twitter.com
// Once registered, you will have the info for the OAuth tokens
// You can get the Access token info by clicking on the button on the
// right on your twitter app's page
// Good luck, and have fun!

import twitter4j.*;
import java.util.List;

class TwC{
  Twitter twitter = new TwitterFactory().getInstance();
  RequestToken requestToken;
  // This is where you enter your Oauth info
   String OAuthConsumerKey;
   String OAuthConsumerSecret; 
   String AccessToken;
   String AccessTokenSecret;
  
  // Just some random variables kicking around
  String myTimeline;
  java.util.List statuses = null;
  User[] friends;
  String[] theSearchTweets = new String[11];
  
  TwC(String oac, String oacs, String at, String ats){
    OAuthConsumerKey = oac;
    OAuthConsumerSecret = oacs;
    AccessToken = at;
    AccessTokenSecret = ats;    
  }
  
    // Initial connection
  void connect() {
    twitter.setOAuthConsumer(OAuthConsumerKey, OAuthConsumerSecret);
    AccessToken accessToken = loadAccessToken();
    twitter.setOAuthAccessToken(accessToken);
  }
  
  // Sending a tweet
  void send(String t) {
    try {
      if(t.length() < 140){
        Status status = twitter.updateStatus(t);
        println("Successfully updated the status to [" + status.getText() + "].");
      } else {
        println("Error!!! message too long");
      }
    } catch(TwitterException e) { 
      println("Send tweet: " + e + " Status code: " + e.getStatusCode());
    }
  }
  
  
  // Loading up the access token
  private AccessToken loadAccessToken(){
    return new AccessToken(AccessToken, AccessTokenSecret);
  }
  
  
  // Get your tweets
  ArrayList getTimeline() {
    ArrayList tweets = new ArrayList();
    try {
      tweets = (ArrayList) twitter.getUserTimeline(); 
    } catch(TwitterException e) { 
      println("Get timeline: " + e + " Status code: " + e.getStatusCode());
    }
    return tweets;
  }

  // get your @ messages
  ArrayList getMentionsTimeline(){
    ArrayList tweets = new ArrayList();
    try{
      tweets = (ArrayList) twitter.getMentionsTimeline();
    } catch(TwitterException e){
      println("Get Mentions Timeline: " + e);
    }
    return tweets;
  }
    
  // Search for tweets
  ArrayList search(String ask) {
    String queryStr = ask;
    ArrayList tweets = new ArrayList();
  
    try {
      Query query = new Query(queryStr);    
     // query.setRpp(10); // Get 10 of the 100 search results  
      QueryResult result = twitter.search(query);    
      tweets = (ArrayList) result.getTweets();    
    } catch (TwitterException e) {    
      println("Search tweets: " + e); 
    }
    return tweets;
  }
  
  // Search for tweets
  ArrayList search(String ask, int results) {
    String queryStr = ask;
    ArrayList tweets = new ArrayList();
  
    try {
      Query query = new Query(queryStr);    
     // query.setRpp(results); // Get 10 of the 100 search results  
      QueryResult result = twitter.search(query);    
      tweets = (ArrayList) result.getTweets();    
    } catch (TwitterException e) {    
      println("Search tweets: " + e); 
    }
    return tweets;
  }
  
  ArrayList search(String ask, long since) {
    String queryStr = ask;
    ArrayList tweets = new ArrayList();
  
    try {
      Query query = new Query(queryStr);    
     // query.setRpp(10); // Get 10 of the 100 search results
      query.sinceId(since);  
      QueryResult result = twitter.search(query);    
      tweets = (ArrayList) result.getTweets();    
    } catch (TwitterException e) {    
      println("Search tweets: " + e); 
    }
    return tweets;
  } 
}