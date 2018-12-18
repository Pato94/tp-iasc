defmodule Api.Registry do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_opts) do
    {:ok, %{next_id: 1, queues: %{}}}
  end

  def handle_call({:new_worker_queue}, _from, state = %{next_id: next_id, queues: queues}) do
    queue = Api.Supervisor.create_worker_queue(next_id)

    store_new_queue(queue, state)
  end

  def handle_call({:new_broadcast_queue}, _from, state = %{next_id: next_id, queues: queues}) do
    queue = Api.Supervisor.create_broadcast_queue(next_id)

    store_new_queue(queue, state)
  end

  def handle_call({:get_queue, id}, _from, %{queues: queues} = state) do
    {:reply, Map.fetch(queues, id), state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  def store_new_queue(queue, %{next_id: next_id, queues: queues}) do
    new_state = %{
      next_id: next_id + 1,
      queues: Map.merge(queues, %{next_id => queue})
    }
    {:reply, {next_id, queue}, new_state}
  end

  def new_worker_queue(server) do
    {id, _} = GenServer.call(server, {:new_worker_queue})
    id
  end

  def new_broadcast_queue(server) do
    {id, _} = GenServer.call(server, {:new_broadcast_queue})
    id
  end

  def get_queue(server, id) do
    GenServer.call(server, {:get_queue, id})
  end
end