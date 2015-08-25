defmodule Pixie.Handshake do
  # Is there a way to use the one from Pixie.Bayeux?
  @version "1.0"
  alias Pixie.Event
  alias Pixie.Bayeux.Error
  alias Pixie.Bayeux
  alias Pixie.Client

  def handle(%Event{message: %{version: v}, response: r}=event) when not is_nil(v) and v != @version do
    %{event | response: Error.version_mismatch(r, v) }
  end

  def handle(%Event{message: %{supported_connection_types: %{__struct__: HashSet}=client_transports, version: @version, channel: "/meta/handshake"}, response: response}=event) do
    server_transports = Bayeux.transports
    common_transports = Set.intersection client_transports, server_transports

    if Enum.empty? common_transports do
      %{event | response: Error.conntype_mismatch(response, client_transports)}
    else
      client = Pixie.Backend.create_client
      %{event | client: client, response: %{response | client_id: client.id}}
    end
  end

  def handle(%Event{message: m, response: r}=event) do
    missing = []
      |> missing_key?(m, :channel)
      |> missing_key?(m, :version)
      |> missing_key?(m, :supported_connection_types)

    %{event | response: Error.parameter_missing(r, missing)}
  end

  defp missing_key? acc, message, key do
    case Map.get message, key, nil do
      nil ->
        [key | acc]
      value when is_bitstring(value) and byte_size(value) == 0 ->
        [key | acc]
      value when is_list(value) and length(value) == 0 ->
        [key | acc]
      value when is_map(value) and map_size(value) == 0 ->
        [key | acc]
      _ ->
        acc
    end
  end

end
