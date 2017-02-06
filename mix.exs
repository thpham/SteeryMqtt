defmodule SteeryMqtt.Mixfile do
  use Mix.Project

  def project do
    [app: :steery_mqtt,
     version: "0.1.0",
     config_path: "config/config.exs",
     elixir: "~> 1.4",
     escript: [main_module: SteeryMqtt],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [ 
      applications: [
        :logger,
        :ssl,
        :poison,
        :emqttc
       ],
      mod: {SteeryMqtt, []} 
    ]
  end

  defp deps do
    [
      {:emqttc, git: "https://github.com/emqtt/emqttc.git"},
      {:poison, "~> 3.1"}
    ]
  end
end
