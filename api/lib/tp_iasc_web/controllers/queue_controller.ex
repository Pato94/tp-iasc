defmodule TpIascWeb.QueueController do
  use TpIascWeb, :controller

  def create(conn, params) do
    id = case Map.get(params, "broadcast", false) do
    	true ->
        TpIasc.Registry.new_broadcast_queue(TpIasc.Registry)
    	false ->
        TpIasc.Registry.new_worker_queue(TpIasc.Registry)
    end

    conn
    |> put_status(:created)
    |> text("#{id}")
  end

  def message(conn, params) do
    message = Map.get(params, "message", "")
    case Map.get(params, "id", -1) do
    	-1 -> conn
    		  	|> put_flash(:error, "Didn't input a queue")
    		  	|> text("error")
    	id -> TpIasc.Supervisor.get_queue(id).push(message)
            conn
              |> text("ok")
    end
  end
end
