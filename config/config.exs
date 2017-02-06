use Mix.Config

config :steery_mqtt,
  name: "SteeryMqtt",
  mqtt: [
    host: "",
    port: 8883,
    username: "",
    password: "",
    cacert: "cacert.pem" ] # the certificate should be present in /priv
