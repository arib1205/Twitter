// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/2" function
// in "web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, pass the token to the Socket constructor as above.
// Or, remove it from the constructor if you don't care about
// authentication.

socket.connect()

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("rooms:lobby", {})
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket

//UI code
let messagesDiv = $('#tweet-container');
messagesDiv.empty();

let loginContainer = $('#login-container');


let loginUsername = $("#login-username");
let loginPassword = $("#login-password");
let loginSubmit = $("#login-btn");

let registerUsername = $("#register-username");
let registerPassword = $("#register-password");
let registerSubmit = $("#register-btn");

var loggedInUser;

let tweetInput = $("#tweet-box");
let tweetBtn = $("#tweet-btn");


loginSubmit.on('click', function(){
  if(loginUsername.val()==='' || loginPassword.val()==='')
    alert("Enter correct credentials");
  else{
      channel.push("login", {username: loginUsername.val(), password: loginPassword.val()})
      loginUsername.val("");
      loginPassword.val("");
  }
});

registerSubmit.on('click', function(){
  console.log("Register btn clicked");
  if(registerUsername.val()==='' || registerPassword.val()==='')
    alert("Enter correct credentials");
  else{
      channel.push("register", {username :registerUsername.val(), password: registerPassword.val()})
      registerUsername.val("");
      registerPassword.val("");
  }
});

let content = $('#content-container');

channel.on("registered", payload => {
  alert(payload.response)
  console.log(payload)
});



channel.on("logged_in", payload => {
  loggedInUser = payload.username;
  if(payload.code === '0'){
    alert(loggedInUser+" "+payload.response)
    loginContainer.css('display','none');
    tweetInput.css('display','block');
    tweetBtn.css('display','block');
    content.css('display','block');
  }
  else
    alert(payload.response);
  console.log(payload)
});


channel.on("new_message", payload => {
  messagesContainer.append(`<br/>[${Date()}] ${payload.body}`);
});


let showMyTweets = $('#show-my-tweets');
let showRetweets = $('#show-retweets');
let follow = $('#follow');


showMyTweets.on('click',function(){
  channel.push("show_my_tweets", {username: loggedInUser});
  $('#h3-tweets').css('display',"block");

});


showRetweets.on('click',function(){
  channel.push("show_my_retweets", {username: loggedInUser});
  $('#h3-retweets').css('display',"block");
});

follow.on('click',function(){
    hideAll();
    $('#h3-follow').css('display','block');
    $('#follow-box').css('display','block');
    $('#follow-btn').css('display','block');
});

let followBtn = $('#follow-btn');
followBtn.on('click', function(){
  //alert("Following");
  var follow = $('#follow-box').val();
  if(follow=='')
    alert('Enter at least one follower');
  else{
    channel.push('subscribe_to', {follow: follow, username: loggedInUser});
    $('#follow-box').val('');
  }
});

channel.on("subscribed_to", payload=>{
  alert(payload.response);
});

tweetBtn.on('click', function(){
  console.log("Tweet btn clicked")
  if(tweetInput.val()==='')
  alert("Enter atleast one tweet!");
else{
  //alert(loggedInUser);
    channel.push("new_tweet", {tweet :tweetInput.val(), username: loggedInUser})
    tweetInput.val("");
}
});

//my tweets
let myTweets = $('#my-tweets');
let nav = $('#nav');
channel.on("tweeted", payload=>{
  alert(payload.response);
});

channel.on("showing_my_tweets", payload=>{
  hideAll();
  $('#h3-tweets').css('display','block');
  myTweets.css('display',"block");
  myTweets.empty();
  var tweets = payload.response.split("\r\n")
  for(var i=0;i<tweets.length;i++){
    myTweets.append(`<p class='col-sm-12'>${tweets[i]}</p><br/>`);
  }
  alert(tweets[0]);
});


//show retweets
let myRetweets = $('#my-retweets');

channel.on("showing_my_retweets", payload=>{
  hideAll();
  $('#h3-retweets').css('display','block');
  myRetweets.css('display',"block");
  myRetweets.empty();
  var tweets = payload.response.split("\r\n")
  for(var i=0;i<tweets.length;i++){
    myRetweets.append(`<p class='col-sm-12'>${tweets[i]}</p><br/>`);
  }
  //alert(tweets[0]);
});

//news feed
let newsFeed = $('#news-feed');
newsFeed.on('click', function(){
  hideAll();
  channel.push("news_feed", {username: loggedInUser});
  $('#h3-newsfeed').css('display',"block");
});

channel.on("showing_news_feed", payload => {
  $('#my-news-feed').css('display','block');
  $('#my-news-feed').empty();
  var count=0;
  if(feed===""){
    $('#my-news-feed').append(`<h4>No tweets from people you are subscribed to</h4>`)
  }
  else
  {
    var feed= payload.feed.split("\r\n")
    console.log("Feed length: "+feed.length);
    $('#my-news-feed').append(`<h4>Tweets from people you are subscribed to, and your mentions</h4>`)
    for(var i=0;i<feed.length-1;i++){
      $('#my-news-feed').append(`<p class='col-sm-12'>${feed[i]}</p><button type="submit" class="btn col-sm-3 col-sm-offset-1" id="retweetBtn-${i}" style="margin-left: 10px;line-height: 0px !important; font-weight: 0px !important; height: 15px !important; width: 15% !important;">Retweet</button>`);
      count++;
    }
  }
  $('#my-news-feed').append(`<br />`)
  if(mentions===""){
    $('#my-news-feed').append(`<h4>No mentions about you</h4>`)
  }
  else{
    var mentions = payload.mentions.split("\r\n");
    console.log("Mentions length: "+mentions.length);
    for(var i=0;i<mentions.length-1;i++){
      $('#my-news-feed').append(`<p class='col-sm-12'>${mentions[i]}</p><button type="submit" class="btn col-sm-3 col-sm-offset-1" id="retweetBtn-${i+count}" style="margin-left: 10px;line-height: 0px !important; font-weight: 0px !important; height: 15px !important; width: 15% !important;">Retweet</button>`);
    }
  }
});

$('#my-news-feed').on('click', 'button', function(){
  var id = $(this).attr('id');
  id = parseInt(id.substring(id.lastIndexOf('-')+1, id.length))+1;
  channel.push('retweet', {tweet_no:id, username: loggedInUser});
});

channel.on('retweeted', payload => {
  alert(payload.response);
});

// function clickFeedBtn(){
//   alert("Hi")
// }

//hash
let hash = $('#query-hash');
hash.on('click', function(){
  hideAll();
  $('#h3-hash').css('display','block');
  $('#hash-box').css('display','block');
  $('#hash-btn').css('display','block');
});

let hashBtn = $('#hash-btn');
hashBtn.on('click', function(){
  var hash = $('#hash-box').val();
  if(hash=='')
    alert('Enter at least one hash string to query');
  else{
    channel.push('query_hash', {hash: hash});
    $('#hash-box').val('');
  }
});

channel.on("queried_hash", payload=>{
  hideAll();
  $('#h3-hash').css("display","block");
  $('#my-hash').css("display","block");
  var hash= payload.response.split("\r\n")
  for(var i=0;i<hash.length;i++){
    $('#my-hash').append(`<p class='col-sm-12' id='${i+1}'>${hash[i]}</p><br/>`);
  }
});


//mention
let mention = $('#query-mention');
mention.on('click', function(){
  hideAll();
  $('#h3-mention').css('display','block');
  $('#mention-box').css('display','block');
  $('#mention-btn').css('display','block');
});

let mentionBtn = $('#mention-btn');
mentionBtn.on('click', function(){
  var mention = $('#mention-box').val();
  if(mention=='')
    alert('Enter at least one mentioned user to query');
  else{
    channel.push('query_mention', {mention: mention});
    $('#mention-box').val('');
  }
});

channel.on("queried_mention", payload=>{
  hideAll();
  $('#h3-mention').css("display","block");
  $('#my-mention').css("display","block");
  var mention= payload.response.split("\r\n")
  for(var i=0;i<mention.length;i++){
    $('#my-mention').append(`<p class='col-sm-12'>${mention[i]}</p><br/>`);
  }
});


//retweet

function hideAll(){

  //my tweets
  $('#h3-tweets').css('display','none');
  $('#my-tweets').css('display','none');

  //follow
  $('#h3-follow').css('display','none');
  $('#follow-box').css('display','none');
  $('#follow-btn').css('display','none');

  //news feed
  $('#h3-newsfeed').css("display","none");
  $("#my-news-feed").css("display","none");

  //hash
  $('#h3-hash').css("display","none");
  $('#hash-box').css("display","none");
  $('#hash-btn').css("display","none");
  $('#my-hash').css("display","none");

  //mentions
  $('#h3-mention').css("display","none");
  $('#mention-box').css("display","none");
  $('#mention-btn').css("display","none");
  $('#my-mention').css("display","none");

  //retweets
  $('#h3-retweets').css('display','none');
  $('#my-retweets').css('display','none');


}
