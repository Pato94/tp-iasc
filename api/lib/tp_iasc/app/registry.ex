defmodule TpIasc.Registry do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def init(_opts) do
    {:ok, %{next_id: 1, queues: %{}}}
  end

  def handle_call({:store_new, queue}, _from, %{next_id: next_id, queues: queues}) do
    new_state = %{
      next_id: next_id + 1,
      queues: Map.merge(queues, %{next_id => queue})
    }
    {:reply, {:ok, next_id}, new_state}
  end

  def handle_call({:get_queue, id}, _from, %{queues: queues} = state) do
    {:reply, Map.fetch(queues, id), state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  def store_new(server, queue) do
    GenServer.call(server, {:store_new, queue})
  end

  def get_queue(server, id) do
    GenServer.call(server, {:get_queue, id})
  end
end