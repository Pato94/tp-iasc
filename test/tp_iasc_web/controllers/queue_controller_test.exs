defmodule TpIascWeb.QueueControllerTest do
  use TpIascWeb.ConnCase

  describe "create" do
    test "Can create a regular queue", %{conn: conn} do
      response = post(conn, "api/queue")

      assert response.status == 201
    end

    test "Can create a broadcast queue" do
      response = post(conn, "api/queue?broadcast=true")

      assert response.status == 201
    end
  end
end
