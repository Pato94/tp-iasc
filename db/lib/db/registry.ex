defmodule Db.Registry do
  use GenServer
  require Logger

  @name {:global, __MODULE__}
  @chunk_size 10
  @replication_level 2
  @initial_state %{
    storages: [],
    chunk_to_cluster: %{}, # %{{queue_id, chunk_start} => [instance]}
    queues_info: %{} # %{queue_id => %{first_message: id, last_message: id }}
  }

  def start_link(state) do
    result = case GenServer.start_link(__MODULE__, @initial_state, name: @name) do
      {:ok, pid} ->
        Logger.debug "Started #{__MODULE__} master"
        Db.Endpoint.start_link([])
        {:ok, pid}
      {:error, {:already_started, pid}} ->
        Logger.debug "Started #{__MODULE__} slave"
        {:ok, pid}
    end
    GenServer.call({:global, Db.Registry}, {:register, {Db.Storage, Node.self()}})
    result
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

  def handle_call({:pop, id}, _from, state) do
    Logger.debug "Registry :pop called, id: #{id}"
    queue_info = queue_info(id, state)

    {:ok, cluster} = find_cluster_for_message(id, queue_info.first_message, state) |> Enum.at(0)

    message = cluster
    |> Enum.map(fn instance -> GenServer.call(instance, {:pop, "#{id}-#{queue_info.first_message}"}) end)
    |> Enum.at(0)

    new_queue_info = %{queue_info | first_message: queue_info.first_message + 1}
    {
      :reply,
      message,
      %{
        state |
        queues_info: Map.put(state.queues_info, id, new_queue_info)
      }
    }
  end

  def handle_call({:push, id, message}, _from, state) do
    Logger.debug "Registry :push called, id: #{id}, message: #{message}"
    queue_info = queue_info(id, state)
    message_id = queue_info.last_message + 1

    chunk_start = div(message_id, @chunk_size) * @chunk_size
    Logger.debug "Registry :push chunk_start = #{chunk_start}"

    cluster = find_storing_cluster(id, message_id, state)

    for instance <- cluster do
      GenServer.call(instance, {:store, "#{id}-#{message_id}", message})
    end

    new_queue_info = %{queue_info | last_message: message_id}
    {
      :reply,
      :ok,
      %{
        state |
        chunk_to_cluster: Map.put(state.chunk_to_cluster, {id, chunk_start}, cluster),
        queues_info: Map.put(state.queues_info, id, new_queue_info)
      }
    }
  end

  def handle_call({:register, pid}, _from, state) do
    Logger.debug "Register received from store"
    GenServer.call(pid, :ack)
    {:reply, :ok, %{state | storages: state.storages ++ [pid]}}
  end

  def handle_call(_msg, _from, state) do
    Logger.debug "Registry unknown call received"
    {:reply, :ok, state}
  end

  def queue_info(id, %{queues_info: map}) do
    case Map.fetch(map, id) do
      {:ok, info} ->
        info
      :error ->
        %{first_message: 1, last_message: 0}
    end
  end

  def find_cluster_for_message(queue_id, message_id, %{chunk_to_cluster: map}) do
    Map.keys(map)
    |> Enum.filter(fn {q_id, _} -> q_id == queue_id end)
    |> Enum.map(fn {_, start} -> {start, start..(start+@chunk_size-1)} end)
    |> Enum.filter(fn {_start, range} -> Enum.member?(range, message_id) end)
    |> Enum.map(fn {start, _range} -> Map.fetch(map, {queue_id, start}) end)
  end

  def find_storing_cluster(queue_id, message_id, state) do
    actual_cluster = find_cluster_for_message(queue_id, message_id, state)
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
