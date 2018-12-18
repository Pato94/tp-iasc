defmodule Api.BroadcastQueue do
  use GenServer
  require Logger

  def start_link(opts) do
    [id: id] = opts
    GenServer.start_link(__MODULE__, %{id: id, consumers: %{}}, opts)
  end

  def init(args) do
    Logger.debug "BroadcastQueue started"
    {:ok, args}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast({:subscribe, pid}, state = %{id: id, consumers: consumers}) do
    subscriberQueue = consumers[pid]
    if subscriberQueue do
      GenServer.cast(subscriberQueue, {:subscribe, pid})
      {:noreply, state}
    else
      id = Api.Registry.new_worker_queue(Api.Registry)
      newConsumers = Map.put(consumers, pid, id)
      GenServer.cast(id, {:subscribe, pid})
      {:noreply, %{state | consumers: newConsumers}}
    end
  end

  def handle_cast({:process, message}, state = %{id: id, consumers: consumers}) do
    for {_, v} <- consumers do
      GenServer.cast(v, {:process, message})
    end
    {:noreply, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end
end