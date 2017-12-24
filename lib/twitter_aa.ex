defmodule TwitterAa do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    ConCache.start_link([], name: :register)
    ConCache.start_link([], name: :alive)
    ConCache.start_link([ets_options: [:duplicate_bag]], name: :tweet)
    ConCache.start_link([ets_options: [:bag]], name: :retweet)
    ConCache.start_link([ets_options: [:bag]], name: :subscribe)
    ConCache.start_link([ets_options: [:bag]], name: :followers)
    ConCache.start_link([ets_options: [:bag]], name: :hashtags)
    ConCache.start_link([ets_options: [:bag]], name: :mentions)
    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(TwitterAa.Endpoint, []),
      # Start your own worker by calling: TwitterAa.Worker.start_link(arg1, arg2, arg3)
      # worker(TwitterAa.Worker, [arg1, arg2, arg3]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TwitterAa.Supervisor]
    Supervisor.start_link(children, opts)

  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TwitterAa.Endpoint.config_change(changed, removed)
    :ok
  end
end
