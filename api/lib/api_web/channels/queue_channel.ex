defmodule ApiWeb.QueueChannel do
  use Phoenix.Channel
  require Logger

  def join("queue:lobby", _message, socket) do
    {:ok, socket}
  end

  def join("queue:" <> queue_id, _message, socket) do
    {id, _} = Integer.parse(queue_id)
    if (String.contains?(queue_id, "consumer")) do
      send(self(), {:after_join, id})
    end
    {:ok, socket}
  end

  def handle_info({:after_join, queue_id}, socket) do
    {:ok, queue} = Api.Registry.get_queue(Api.Registry, queue_id)
    {:ok, sc} = Api.SocketConsumer.start_link([socket: socket])
    Api.SocketConsumer.subscribe(sc, queue)
    {:noreply, socket}
  end

  def handle_in("new_msg", %{"queue_id" => queue_id, "body" => body}, socket) do
    {:ok, queue} = Api.Registry.get_queue(Api.Registry, queue_id)
    GenServer.cast(queue, {:process, body})
    {:noreply, socket}
  end

  def handle_in("new_queue", %{"queue_id" => queue_id, "broadcast" => broadcast}, socket) do
    if broadcast do
      Logger.debug "New broadcast queue created"
      Api.Registry.new_broadcast_queue(Api.Registry)
    else
      Logger.debug "New worker queue created"
      Api.Registry.new_worker_queue(Api.Registry)
    end
    {:noreply, socket}
  end
end
