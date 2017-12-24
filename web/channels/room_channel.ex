defmodule TwitterAa.RoomChannel do
    use Phoenix.Channel
    
    def join("rooms:lobby", _message, socket) do
        {:ok, socket}
    end

    def join(_room, _params, _socket) do
        {:error, %{reason: "You can only join the room lobby"}}
    end

    def handle_in("new_message", body, socket) do
        broadcast! socket, "new_message", body
        {:noreply, socket}
    end

    def handle_in("login", %{"username"=>username, "password"=>password},socket) do
        IO.puts "logging in"
        if(ConCache.get(:register, username) == password) do
            html = Phoenix.View.render_to_string(TwitterAa.PageView,"tweets.html",username: username)
            IO.puts "Html is #{html}"
            push socket, "logged_in", %{response: "Logged in successfully", username: username, html: html, code: "0"}
        else
            push socket, "logged_in", %{response: "Incorrect login credentials.Try again!", code: "-1"}
        end
        {:noreply, socket}
    end

    def handle_in("register", %{"username"=>username, "password"=>password},socket) do
        IO.puts "username is #{username} ... password is #{password}"
        ConCache.put(:register, username, password)
        push socket, "registered", %{response: "Registered successfully"}
        {:noreply, socket}
    end

    def handle_in("new_tweet", %{"tweet"=> tweet, "username"=>username} ,socket) do
        IO.puts "username is #{username} ... tweet is #{tweet}"
        date_time = Tuple.to_list(:calendar.local_time())
        date_time_string = "Date " <> Enum.join((Tuple.to_list(Enum.at(date_time, 0))),"-") <> " time " <> Enum.join((Tuple.to_list(Enum.at(date_time, 1))),"-")
        IO.puts date_time_string
        ConCache.put(:tweet, username, [username, tweet, date_time_string])
        hashtag =  Regex.scan(~r/#[a-zA-Z0-9_]+/, tweet)|> Enum.concat
        if(length(hashtag) != 0) do
          hash_string =  Enum.at(hashtag,0)
          # hash_string = String.slice(hash_string, 1..String.length(hash_string))
          ConCache.put(:hashtags, hash_string, [username, tweet, date_time_string])
        end

        mention =  Regex.scan(~r/@[a-zA-Z0-9_]+/, tweet)|> Enum.concat
        if length(mention) != 0 do
          men_string =  Enum.at(mention,0)
          ConCache.put(:mentions, men_string, [username, tweet, date_time_string])
        #   men_chk_alive = String.slice(men_string, 1..String.length(men_string))
        #   if(ConCache.get(:alive, men_chk_alive) != nil) do
        #     pid = ConCache.get(:alive, men_chk_alive)
        #     write_line(deliver, pid)
        #   end
        end
        # #ConCache.put(:register, username, password)
        # #ConCache.put(:tweet,username, [tweet])
        # tweeted = display_tweet(username)#ConCache.get(:tweet, username)
        # IO.inspect tweeted
        push socket, "tweeted", %{response: "Tweet added to database"}
        {:noreply, socket}
    end

    def handle_in("show_my_tweets", %{"username"=>username} ,socket) do
        IO.puts "username is #{username}"
        tweeted = display_tweet(username)#ConCache.get(:tweet, username)
        IO.inspect tweeted
        push socket, "showing_my_tweets", %{response: tweeted}
        {:noreply, socket}
    end

    def handle_in("show_my_retweets", %{"username"=>username} ,socket) do
        IO.puts "username is #{username}"
        retw_list = ConCache.get(:retweet, username)
        IO.inspect retw_list
        if is_list(Enum.at(retw_list,0)) do
          final = convert_list_for_news_feed(retw_list, "", 0)
        else
          final = convert_for_news_feed(retw_list,"")
        end
    
        push socket, "showing_my_retweets", %{response: final}
        {:noreply, socket}
    end
    

    def handle_in("subscribe_to", %{"follow"=>follow, "username"=>username} ,socket) do
        IO.puts "follow is #{follow}  username is #{username}"
        ConCache.put(:subscribe, username, [follow])
        ConCache.put(:followers, follow, [username])
        #tweeted = display_tweet(username)#ConCache.get(:tweet, username)
        push socket, "subscribed_to", %{response: "Subscribed to #{follow}"}
        {:noreply, socket}
    end

    def handle_in("news_feed", %{"username"=>username} ,socket) do
        IO.puts "username is #{username}"
        feed=""
        mentions=""
        if ConCache.get(:subscribe, username) !=nil do
            #feed = feed <> "tweets from the people subscribed to\r\n"
            all_sub = ConCache.get(:subscribe, username)
            if(length(all_sub) == 1) do
              sname = Enum.at(all_sub, 0)
              feed = feed <> display_tweet_for_news_feed(sname)
            else
            #   Enum.each(all_sub, fn(list) -> sname = Enum.at(list, 0)
            #                                  feed = feed <> display_tweet_for_news_feed(sname)
            #                                end)
                feed = feed <> news_feed(all_sub, "", 0)
            end
          else
              #feed = feed <> "No tweets from the people subscribed to\r\n"
          end
          mention_str = "@" <> username
          if(ConCache.get(:mentions, mention_str) != nil) do
            #mentions = mentions <> "Mentions\r\n"
            all_mention = ConCache.get(:mentions, mention_str)
            if is_list(Enum.at(all_mention,0)) do
              final = convert_list_for_news_feed(all_mention, "", 0)
            else
              final = convert_for_news_feed(all_mention,"")
            end
            mentions = mentions <> final
          else
            #mentions = mentions <> "Nobody mentioned you\r\n"
          end

          IO.puts "Feed is #{feed}"
          IO.puts "Mentions is #{mentions}"
          IO.inspect mentions
        push socket, "showing_news_feed", %{feed: feed, mentions: mentions}
        {:noreply, socket}
    end


    def handle_in("query_mention", %{"mention"=>mention} ,socket) do
        IO.puts "mention is #{mention}"
        mention_str = ""
        if(ConCache.get(:mentions, mention) == nil) do
            mention_str = mention_str <> "No match for hash provided\r\n"
        else
          all_mention = ConCache.get(:mentions, mention)
          if is_list(Enum.at(all_mention,0)) do
            final = convert_list_for_news_feed(all_mention, "", 0)
          else
            final = convert_for_news_feed(all_mention,"")
          end
          mention_str = mention_str <> final
        end
        push socket, "queried_mention", %{response: mention_str}
        {:noreply, socket}
    end


    def handle_in("query_hash", %{"hash"=>hash} ,socket) do
        IO.puts "hash is #{hash}"
        hash_str = ""
        if(ConCache.get(:hashtags, hash) == nil) do
          hash_str = hash_str <> "No match for hash provided\r\n"
        else
          all_hash = ConCache.get(:hashtags, hash)
          if is_list(Enum.at(all_hash,0)) do
            final = convert_list_for_news_feed(all_hash, "", 0)
          else
            final = convert_for_news_feed(all_hash,"")
          end
          hash_str = hash_str <> final
        end
        push socket, "queried_hash", %{response: hash_str}
        {:noreply, socket}
    end

    def handle_in("retweet", %{"tweet_no"=>tweet_no, "username"=>username} ,socket) do
        IO.puts "tweet_no is #{tweet_no}"
        
        tweet_list = [["0"]]
        if ConCache.get(:subscribe, username) !=nil do
        #    write_line("tweets from the people subscribed to\r\n", socket)
           all_sub = ConCache.get(:subscribe, username)
           if(length(all_sub) == 1) do
             sname = Enum.at(all_sub, 0)
            #  display_tweet(sname, socket)

             temp_list = ConCache.get(:tweet, sname)
             if is_list(Enum.at(temp_list,0)) do
               # Enum.each(temp_list, fn(list) -> tweet_list = List.insert_at(tweet_list, length(tweet_list), list)
               #                                  IO.inspect tweet_list
               #                                  end)
               tweet_list = calc_retweet(temp_list, tweet_list, 0)
             else
               tweet_list = List.insert_at(tweet_list, length(tweet_list), temp_list)
               IO.inspect tweet_list
             end

           else
             Enum.each(all_sub, fn(list) -> sname = Enum.at(list, 0)
                                            # display_tweet(sname, socket)
                                            temp_list = ConCache.get(:tweet, sname)
                                            if is_list(Enum.at(temp_list,0)) do
                                              # Enum.each(temp_list, fn(list) -> tweet_list = List.insert_at(tweet_list, length(tweet_list), list)
                                              #                                  end)
                                              tweet_list = calc_retweet(temp_list, tweet_list, 0)
                                            else
                                              tweet_list = List.insert_at(tweet_list, length(tweet_list), temp_list)
                                            end
                                          end)
           end
         else
            #  write_line("No tweets from the people subscribed to\r\n", socket)
         end
       IO.inspect tweet_list

       if(tweet_no < length(tweet_list)) do
          retweet = Enum.at(tweet_list, tweet_no)
          IO.inspect retweet
       else
        IO.puts "in mentions" 
        mention_str = "@" <> username
        if(ConCache.get(:mentions, mention_str) != nil) do
          #mentions = mentions <> "Mentions\r\n"
          all_mention = ConCache.get(:mentions, mention_str)
          
          
          if is_list(Enum.at(all_mention,0)) do
            # final = convert_list_for_news_feed(all_mention, "", 0)
            retweet = Enum.at(all_mention, tweet_no - length(tweet_list))
          else
            # final = convert_for_news_feed(all_mention,"")
            retweet = all_mention
          end
          IO.inspect retweet
        #   mentions = mentions <> final
        # else
          #mentions = mentions <> "Nobody mentioned you\r\n"
        end

       end

       date_time = Tuple.to_list(:calendar.local_time())
       date_time_string = "Date " <> Enum.join((Tuple.to_list(Enum.at(date_time, 0))),"-") <> " time " <> Enum.join((Tuple.to_list(Enum.at(date_time, 1))),"-")
       ConCache.put(:retweet, username, [Enum.at(retweet,0), Enum.at(retweet,2), username, date_time_string, Enum.at(retweet,1)] )
       IO.inspect ConCache.get(:retweet, username)
        push socket, "retweeted", %{response: "Added to retweets database!"}
        {:noreply, socket}
    end

    #util methods

    def calc_retweet(temp_list, tweet_list, i) do
        if i < length(temp_list) do
          tweet_list = List.insert_at(tweet_list, length(tweet_list), Enum.at(temp_list, i))
          tweet_list = calc_retweet(temp_list, tweet_list, i+1)
        end
        tweet_list
      end

    def convert(list, str) do
        if(length(list) != 0) do
          if(length(list) == 3) do
            str = str <> "\"" <> Enum.at(list,1) <> "\" , " <> Enum.at(list,2) <> "\r\n"
          else
            str = str <> "\"" <> Enum.at(list,0) <> "\" , "  <> Enum.at(list,1) <> " , \"" <> Enum.at(list,2) <> "\" , "  <> Enum.at(list,3) <> " , \"" <> Enum.at(list,4) <> "\"\r\n"
          end
        end
        str
      end
    
      def convert_list(t, final, i) do
        if i < length(t) do
           final = final <> convert(Enum.at(t,i),"")
           # write_line(final,socket)
           final = convert_list(t,final,i+1)
         end
         final
      end
    
      def display_tweet(username) do
        t = ConCache.get(:tweet, username)
        # IO.inspect ConCache.ets(:tweet)
        # final = "{\"" <> Enum.at(t,0) <> "\" , " <> Enum.at(t,1) <> "}\r\n"
        IO.inspect t
        if is_list(Enum.at(t,0)) do
          final = convert_list(t, "", 0)
        else
          final = convert(t,"")
        end
        #write_line(final, socket)
        final
      end


      def convert_for_news_feed(list, str) do
        if(length(list) != 0) do
          if(length(list) == 3) do
            str = str <> "\"" <> Enum.at(list,0) <> "\" , \"" <> Enum.at(list,1) <> "\" , " <> Enum.at(list,2) <> "\r\n"
          else
            str = str <> "\"" <> Enum.at(list,0) <> "\" , "  <> Enum.at(list,1) <> " , \"" <> Enum.at(list,2) <> "\" , "  <> Enum.at(list,3) <> " , \"" <> Enum.at(list,4) <> "\"\r\n"
          end
        end
        str
      end
    
      def convert_list_for_news_feed(t, final, i) do
        if i < length(t) do
           final = final <> convert_for_news_feed(Enum.at(t,i),"")
           # write_line(final,socket)
           final = convert_list_for_news_feed(t,final,i+1)
         end
         final
      end
    
      def display_tweet_for_news_feed(username) do
        t = ConCache.get(:tweet, username)
        # IO.inspect ConCache.ets(:tweet)
        # final = "{\"" <> Enum.at(t,0) <> "\" , " <> Enum.at(t,1) <> "}\r\n"
        IO.inspect t
        if is_list(Enum.at(t,0)) do
          final = convert_list_for_news_feed(t, "", 0)
        else
          final = convert_for_news_feed(t,"")
        end
        #write_line(final, socket)
        final
      end

      def news_feed(all_sub, str, i) do
          if i< length(all_sub) do
            list = Enum.at(all_sub, i)
            sname = Enum.at(list, 0)
            str = str <> display_tweet_for_news_feed(sname)
            str = news_feed(all_sub, str, i+1)
          else
            str
          end
          str
      end
    
end