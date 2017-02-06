defmodule SteeryMqtt do
  use Application

  @root_supervisor SteeryMqtt.Supervisor

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    mqtt = Application.get_env(:steery_mqtt, :mqtt)
    client_name = Application.get_env(:steery_mqtt, :name)
    parameters = %{client_name: client_name,
                   host: mqtt[:host],
                   port: mqtt[:port],
                   username: mqtt[:username],
                   password: mqtt[:password],
                   cacert: mqtt[:cacert]}
    
    children = [
      # Define workers and child supervisors to be supervised
      worker(SteeryMqtt.MqttWorker, [parameters])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: @root_supervisor]
    Supervisor.start_link(children, opts)
  end
end
