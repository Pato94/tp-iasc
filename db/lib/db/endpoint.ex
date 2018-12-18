defmodule Db.Endpoint do
  use Plug.Router

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(_opts),
      do: Plug.Cowboy.http(__MODULE__, [])

  plug(
    Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:match)
  plug(:dispatch)

  get "/pop/:id" do
    message = Db.Registry.pop(id)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(%{message: message}))
  end

  post "/push/:id" do
    %{"message" => message} = conn.body_params
    Db.Registry.push(id, message)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(%{}))
  end

  match _ do
    send_resp(conn, 404, "Requested page not found!")
  end
end