defmodule TwitterAa.RegisterController do
    use TwitterAa.Web, :controller
  
    def register(conn, _params) do
        IO.puts "registering now..."
        IO.inspect _params
        render conn, "index.html"
    end
end