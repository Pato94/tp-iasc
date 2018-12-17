defmodule Db.Registry do
  use GenServer
  require Logger

  @chunk_size 10
  @replication_level 1
  @initial_state %{
    storages: [],
    chunk_start_to_cluster: %{},
    next_message_id_for_queue_id: %{}, # Next id to be consumed for queue
    next_message_id: 1 # Handles global id number
  }

  def start_link(state) do
    case GenServer.start_link(__MODULE__, @initial_state, name: {:global, __MODULE__}) do
      {:ok, pid} ->
        Logger.info "Started #{__MODULE__} master"
        {:ok, pid}
      {:error, {:already_started, pid}} ->
        Logger.info "Started #{__MODULE__} slave"
        GenServer.call({:global, Db.Registry}, {:register, {Db.Storage, Node.self()}})
        {:ok, pid}
    end
  end

  def init(args) do
    {:ok, args}
  end

  def handle_call({:pop, id}, _from, state = %{next_message_id_for_queue_id: next_message_id_for_queue_id}) do
    message_id = next_message_id_for_queue(id, state)
    {:ok, cluster} = find_cluster_for_message(message_id, state) |> Enum.at(0)

    message = nil
    for instance <- cluster do
      {:ok, message} = GenServer.call(instance, {:pop, message_id})
    end

    {
      :reply,
      message,
      %{
        state |
        next_message_id_for_queue_id: %{
          next_message_id_for_queue_id |
          id => message_id + 1 # TODO: This logic is wrong
        }
      }
    }
  end

  def handle_call({:push, id, message}, _from, state = %{next_message_id: next_message_id}) do
    chunk_start = div(next_message_id, @chunk_size)
    cluster = find_storing_cluster(chunk_start, state)

    for instance <- cluster do
      GenServer.call(instance, {:store, next_message_id, message})
    end

    next_message_id_for_queue_id = if Map.has_key?(state.next_message_id_for_queue_id, id) do
      state.next_message_id_for_queue_id
    else
      Map.put(state.next_message_id_for_queue_id, id, next_message_id)
    end

    new_chunk_to_cluster = Map.put(state.chunk_start_to_cluster, chunk_start, cluster)
    {
      :reply,
      :ok,
      %{
        state |
        next_message_id: next_message_id + 1,
        chunk_start_to_cluster: new_chunk_to_cluster,
        next_message_id_for_queue_id: next_message_id_for_queue_id
      }
    }
  end

  def handle_call({:register, pid}, _from, state) do
    IO.puts "Register called with pid"
    GenServer.call(pid, :ack)
    {:reply, :ok, %{state | storages: state.storages ++ [pid]}}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def next_message_id_for_queue(id, %{next_message_id_for_queue_id: map}) do
    {:ok, id} = Map.fetch(map, id)
    id
  end

  def find_cluster_for_message(message_id, %{chunk_start_to_cluster: map}) do
    Map.keys(map)
    |> Enum.map(fn start -> {start, start..(start+@chunk_size)} end)
    |> Enum.filter(fn {_start, range} -> Enum.member?(range, message_id) end)
    |> Enum.map(fn {start, _range} -> Map.fetch(map, start) end)
  end

  def find_storing_cluster(message_id, state) do
    actual_cluster = find_cluster_for_message(message_id, state)
    if !Enum.empty?(actual_cluster) do
      {:ok, list} = actual_cluster |> Enum.at(0)
      list
    else
      Enum.take_random(state.storages, @replication_level)
    end
  end
end
