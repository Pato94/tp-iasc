defmodule Db.Registry do
  use GenServer
  require Logger

  @chunk_size 10

  def start_link(state) do
    case GenServer.start_link(__MODULE__, %{storages: [], id_to_storage: [], next_message_id: %{}}, name: {:global, __MODULE__}) do
      {:ok, pid} ->
        Logger.info "Started #{__MODULE__} master"
        {:ok, pid}
      {:error, {:already_started, pid}} ->
        Logger.info "Started #{__MODULE__} slave"
        {:ok, pid}
    end
  end

  def init(args) do
    {:ok, args}
  end

  def handle_call({:pop, id}, _from, state = %{next_message_id: next_message_id}) do
    message_id = next_message_id_for_queue(id, state)
    clusters = find_clusters_for_message(message_id, state)

    for cluster <- clusters do
      {:ok, message} = GenServer.call(cluster, {:pop, :message_id})
    end

    # TODO devolver el mensaje

    {:reply, :ok, %{state | next_message_id: %{next_message_id | id => message_id + 1}}}
  end

  def next_message_id_for_queue(id, %{next_message_id: map}) do
    Map.fetch(map, id)
  end

  def find_clusters_for_message(message_id, %{chunk_start_to_clusters: map}) do
    Map.keys(map)
    |> Enum.map(fn start -> {start, start..(start+@chunk_size)} end)
    |> Enum.filter(fn {_start, range} -> Enum.member?(range, message_id) end)
    |> Enum.map(fn {start, _range} -> Map.fetch(map, start) end)
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end
end