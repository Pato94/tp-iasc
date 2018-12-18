defmodule TpIasc.DbClient do
  require Logger

  def push(id, message) do
    Logger.debug "pushing message, id: #{id}, message: #{message}"
    {:ok, response} = HTTPoison.post "localhost:4001/push/#{id}", Jason.encode!(%{message: message}), [{"Content-Type", "application/json"}]
    Logger.debug "response: #{inspect(response.body)}"
    Jason.decode!(response.body)
  end

  def pop(id) do
    Logger.debug "popping message, id: #{id}"
    {:ok, response} = HTTPoison.get "localhost:4001/pop/#{id}"
    Logger.debug "response: #{inspect(response.body)}"
    %{"message" => message} = Jason.decode!(response.body)
    message
  end
end
