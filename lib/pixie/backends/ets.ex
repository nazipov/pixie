defmodule Pixie.Backend.ETS do
  use Pixie.Backend
  use Supervisor
  import Supervisor.Spec
  alias Pixie.Monitor

  @moduledoc """
  This is the default persistence backend for Pixie, which stores data in
  ETS tables, which means it will only persist as long as this process is
  running.

  More information about ETS can be found
  [in the Elixir ETS docs](http://elixir-lang.org/getting-started/mix-otp/ets.html).
  """

  def start_link options do
    Supervisor.start_link __MODULE__, options, name: __MODULE__
  end

  def init _options do
    children = [
      supervisor(Pixie.ClientSupervisor, []),
      supervisor(Pixie.TransportSupervisor, []),
      worker(__MODULE__.Namespaces, []),
      worker(__MODULE__.ClientSubscriptions, []),
      worker(__MODULE__.ChannelSubscriptions, []),
      worker(__MODULE__.Channels, []),
      worker(__MODULE__.MessageQueue, [])
    ]
    supervise children, strategy: :one_for_one
  end

  def generate_namespace length do
    __MODULE__.Namespaces.generate_namespace length
  end

  def release_namespace namespace do
    __MODULE__.Namespaces.release_namespace namespace
  end

  def create_client do
    {client_id, pid} = __MODULE__.Clients.create
    Monitor.created_client client_id
    {client_id, pid}
  end

  def get_client client_id do
    __MODULE__.Clients.get client_id
  end

  def ping_client(_client_id), do: :ok

  def destroy_client client_id, reason do
    do_destroy_client client_id, reason
  end

  def subscribe client_id, channel_name do
    unless __MODULE__.Channels.exists? channel_name do
      __MODULE__.Channels.create channel_name
      Monitor.created_channel channel_name
    end
    __MODULE__.ClientSubscriptions.subscribe client_id, channel_name
    __MODULE__.ChannelSubscriptions.subscribe channel_name, client_id
    Monitor.client_subscribed client_id, channel_name
  end

  def unsubscribe client_id, channel_name do
    do_unsubscribe client_id, channel_name
  end

  def subscribed_to client_id do
    __MODULE__.ClientSubscriptions.get client_id
  end

  def subscribers_of channel_pattern do
    __MODULE__.Channels.list
      |> Enum.reduce(HashSet.new, fn
        ({channel_name, matcher}, set) ->
          if channel_matches? matcher, channel_pattern do
            subscribers = __MODULE__.ChannelSubscriptions.get channel_name
            subscribers = Enum.into subscribers, HashSet.new
            Set.union set, subscribers
          else
            set
          end
      end)
  end

  def client_subscribed? client_id, channel_name do
    __MODULE__.ClientSubscriptions.subscribed? client_id, channel_name
  end

  def queue_for client_id, messages do
    __MODULE__.MessageQueue.queue client_id, messages
  end

  def dequeue_for client_id do
    __MODULE__.MessageQueue.dequeue client_id
  end

  def deliver client_id, messages do
    Pixie.Client.deliver client_id, messages
  end

  def terminate _reason, _table do
    Enum.each __MODULE__.Clients.list, fn(client_id) ->
      do_destroy_client client_id, "Backend exiting"
    end
    :ok
  end

  defp do_destroy_client client_id, reason do
    subs = __MODULE__.ClientSubscriptions.get(client_id)
    Enum.each subs, fn(channel)->
      do_unsubscribe client_id, channel
    end
    Monitor.destroyed_client client_id
    __MODULE__.Clients.destroy client_id
  end

  defp do_unsubscribe client_id, channel_name do
    __MODULE__.ClientSubscriptions.unsubscribe client_id, channel_name
    __MODULE__.ChannelSubscriptions.unsubscribe channel_name, client_id
    Pixie.Monitor.client_unsubscribed client_id, channel_name
    if __MODULE__.ChannelSubscriptions.subscriber_count channel_name == 0 do
      __MODULE__.Channels.destroy channel_name
      Pixie.Monitor.destroyed_channel channel_name
    end
  end
end
