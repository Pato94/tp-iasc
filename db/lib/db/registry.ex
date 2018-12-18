defmodule Db.Registry do
  use GenServer
  require Logger

  @name {:global, __MODULE__}
  @chunk_size 10
  @replication_level 2
  @initial_state %{
    storages: [],
    chunk_start_to_cluster: %{},
    next_message_id_for_queue_id: %{}, # Next id to be consumed for queue
    next_message_id: 1 # Handles global id number
  }

  def start_link(state) do
    case GenServer.start_link(__MODULE__, @initial_state, name: @name) do
      {:ok, pid} ->
        Logger.debug "Started #{__MODULE__} master"
        {:ok, pid}
      {:error, {:already_started, pid}} ->
        Logger.debug "Started #{__MODULE__} slave"
        GenServer.call({:global, Db.Registry}, {:register, {Db.Storage, Node.self()}})
        {:ok, pid}
    end
  end

  def init(args) do
    {:ok, args}
  end

  def pop(id) do
    GenServer.call(@name, {:pop, id})
  end

  def push(id, message) do
    GenServer.call(@name, {:push, id, message})
  end

  def handle_call({:pop, id}, _from, state = %{next_message_id_for_queue_id: next_message_id_for_queue_id}) do
    Logger.debug "Registry :pop called, id: #{id}"
    message_id = next_message_id_for_queue(id, state)
    {:ok, cluster} = find_cluster_for_message(message_id, state) |> Enum.at(0)

    message = cluster
    |> Enum.map(fn instance -> GenServer.call(instance, {:pop, message_id}) end)
    |> Enum.at(0)

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
    Logger.debug "Registry :push called, id: #{id}, message: #{message}"
    chunk_start = div(next_message_id, @chunk_size) * @chunk_size
    Logger.debug "Registry :push chunk_start = #{chunk_start}"
    cluster = find_storing_cluster(next_message_id, state)

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
    Logger.debug "Register received from slave"
    GenServer.call(pid, :ack)
    {:reply, :ok, %{state | storages: state.storages ++ [pid]}}
  end

  def handle_call(_msg, _from, state) do
    Logger.debug "Registry unknown call received"
    {:reply, :ok, state}
  end

  def next_message_id_for_queue(id, %{next_message_id_for_queue_id: map}) do
    {:ok, id} = Map.fetch(map, id)
    id
  end

  def find_cluster_for_message(message_id, %{chunk_start_to_cluster: map}) do
    Map.keys(map)
    |> Enum.map(fn start -> {start, start..(start+@chunk_size-1)} end)
    |> Enum.filter(fn {_start, range} -> Enum.member?(range, message_id) end)
    |> Enum.map(fn {start, _range} -> Map.fetch(map, start) end)
  end

  def find_storing_cluster(message_id, state) do
    actual_cluster = find_cluster_for_message(message_id, state)
    if !Enum.empty?(actual_cluster) do
      Logger.debug "Registry :find_storing_cluster. cluster found"
      {:ok, list} = actual_cluster |> Enum.at(0)
      list
    else
      Logger.debug "Registry :find_storing_cluster. cluster not found"
      Enum.take_random(state.storages, @replication_level)
    end
  end
end
