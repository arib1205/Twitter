defmodule TwitterAa.TweetsController do
    use TwitterAa.Web, :controller
  
    def show(conn, _params) do
        IO.puts "showdewvwevsfvsfvdsvsdvdsvsdvsdvdsvdsvdsvdsvdsvsd"
      render conn, "home.html"
    #   conn
    #   |> put_view(TwitterAa.TweetsView)
    #   |> render("home.html", blah: "dfdf")
    end
  end
  