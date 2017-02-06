defmodule SteeryMqtt.MqttWorker do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def send_vehicle_position(lat, long) do
    msg = %{position: %{latitude: lat, longitude: long, timestamp: get_timestamp_as_string()}}
    msg_raw = Poison.encode!(msg)
    GenServer.cast(__MODULE__, {:send_event, msg_raw})
  end

  def init(%{client_name: client_name, host: host, port: port, username: un, password: pw, cacert: cacert_name}) do
    topic_event = "/test"
    topic_connection = "/test"
    topic_command = "/test"

    ssl = [ 
      cacertfile: Path.join(:code.priv_dir(:steery_mqtt), cacert_name)
    ]
    will_payload = Poison.encode!(%{disconnected: %{vehicle: client_name}})
    {:ok, pid} = :emqttc.start_link([host: host,
                                     port: port,
                                     client_id: client_name,
                                     username: un,
                                     password: pw,
                                     ssl: ssl,
                                     proto_ver: 4,
                                     connack_timeout: 30,
                                     reconnect: {3, 60},
                                     clean_sess: true,
                                     auto_resub: [reconnect: 4],
                                     keepalive: 60,
                                     logger: :all,
                                     will: [qos: 1, retain: true, topic: topic_connection, payload: will_payload]])
    state = %{pid: pid,
              client_name: client_name,
              topic_event: topic_event,
              topic_connection: topic_connection,
              topic_command: topic_command}
    {:ok, state}
  end

  def handle_cast({:send_event, payload}, state) do
    :emqttc.publish(state.pid, state.topic_event, payload, [qos: 1, retain: true])
    {:noreply, state}
  end

  def handle_info({:mqttc, pid, :connected}, state) do
    send_connected(pid, state.topic_connection)
    Logger.debug("Subscribing to #{state.topic_command}")

    :emqttc.subscribe(pid, state.topic_command, 1)

    {:noreply, state}
  end

  def handle_info({:mqttc, _pid, :disconnected}, state) do
    Logger.warn("Disconnected")
    {:noreply,state}
  end

  def handle_info({:publish, topic_command, payload}, state = %{topic_command: topic_command}) do
    cmd = Poison.decode!(payload)
    handle_command(cmd["command"], cmd["id"], state.pid, state.topic_event)
    {:noreply, state}
  end

  def handle_info({:publish, unknown_topic, payload}, state) do
    Logger.info("Received unknown topic(#{unknown_topic}): #{inspect payload}")
    {:noreply, state}
  end

  defp handle_command("ping", id, pid, topic_event) do
    msg = %{pong: %{id: id, timestamp: get_timestamp_as_string()}}
    msg_raw = Poison.encode!(msg)
    :emqttc.publish(pid, topic_event, msg_raw)
  end

  defp handle_command(unknown_command, _id, _pid, _topic_event) do
    Logger.warn("Unknown command: #{unknown_command}")
  end

  defp send_connected(pid, topic_connection) do
    boot_time = "unknown"
    msg = %{connected: %{boot_time: boot_time, addresses: get_ip_address(), timestamp: get_timestamp_as_string()}}
    payload = Poison.encode!(msg)
    :emqttc.publish(pid, topic_connection, payload, [qos: 1, retain: true])
  end

  defp get_ip_address do
    :inet.getif() |> elem(1) |> hd() |> elem(0) |> Tuple.to_list |> Enum.join(".")
  end

  defp get_timestamp_as_string do
    DateTime.utc_now |> DateTime.to_string
  end
end