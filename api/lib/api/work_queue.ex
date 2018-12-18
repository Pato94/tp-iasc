defmodule Api.WorkQueue do
  use GenServer
  require HTTPoison
  require Logger

  def start_link(opts) do
    [id: id] = opts
    GenServer.start_link(__MODULE__, %{id: id, pending: 0, consumers: []}, opts)
  end

  def init(args) do
    Logger.debug "WorkQueue started"
    {:ok, args}
  end

  def handle_cast({:subscribe, pid}, state = %{id: id, consumers: consumers, pending: pending}) do
    Logger.debug "WorkQueue, subscribe received!"
    if pending > 0 do
      message = Api.DbClient.pop(id)
      GenServer.cast(pid, {:consume, self(), message})
      {:noreply, %{state | pending: pending - 1}}
    else
      {:noreply, %{state | consumers: consumers ++ [pid]}}
    end
  end

  def handle_cast({:process, message}, state = %{id: id, consumers: consumers, pending: pending}) do
    if Enum.empty?(consumers) do
      Api.DbClient.push(id, message)
      {:noreply, %{state | pending: pending + 1}}
    else
      [head | tail] = consumers
      GenServer.cast(head, {:consume, self(), message})
      {:noreply, %{state | consumers: tail}}
    end
  end

  def handle_call(_msg, _from, state) do
    Logger.debug "WorkQueue: unknown call received"
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    Logger.debug "WorkQueue: unknown cast received"
    {:noreply, state}
  end
end