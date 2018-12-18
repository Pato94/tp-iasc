defmodule Api.CliProducerConsumer do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_cast({:process, queue, message}, state) do
    IO.puts("Process called: #{message}")
    GenServer.cast(queue, {:process, message})
    {:noreply, state}
  end

  def handle_cast({:subscribe, queue}, state) do
    IO.puts("Subscribed")
    GenServer.cast(queue, {:subscribe, self()})
    {:noreply, state}
  end

  def handle_cast({:consume, from, message}, state) do
    IO.puts("Message consumed: #{message}")
    GenServer.cast(from, {:subscribe, self()})
    {:noreply, state}
  end

  def handle_call(_msg, _from, state) do
    Logger.debug "CliProducerConsumer: Unknown call"
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    Logger.debug "CliProducerConsumer: Unknown cast"
    {:noreply, state}
  end

  def produce(server, queue, message) do
    GenServer.cast(server, {:process, queue, message})
  end

  def subscribe(server, queue) do
    GenServer.cast(server, {:subscribe, queue})
  end
end