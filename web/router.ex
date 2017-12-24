defmodule TwitterAa.Router do
  use TwitterAa.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TwitterAa do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    #post "/", PageController, :index
    get "/home", TweetsController, :show
    #get "/register", RegisterController, :register
  end

  # Other scopes may use custom stacks.
  # scope "/api", TwitterAa do
  #   pipe_through :api
  # end
end
