defmodule ApiWeb.QueueChannel do
  use Phoenix.Channel

  def join("queue:" <> queue_id, _message, socket) do
    {id, _} = Integer.parse(queue_id)
    send(self(), {:after_join, id})
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
end
