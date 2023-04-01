defmodule ExampleWeb.LiveExample1 do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~H"""
    <style>
      button {
          background-color: black;
          color: white;
          padding: 0.5rem 1rem;
          border-radius: 0.25rem;
          font-weight: bold;
      }

      button.minus {
          background-color: red;
      }

      button.plus {
          background-color: rgb(0, 190, 0);
      }
    </style>

    <h1 class="flex justify-center mb-10 font-bold">LiveView</h1>

    <div class="flex flex-col justify-center items-center gap-4">
      <div class="flex flex-row items-center justify-center gap-10">
        <button class="minus" phx-click="subtract">-<%= @amount %></button>
        <span class="text-xl"><%= @number %></span>
        <button class="plus" phx-click="add">+<%= @amount %></button>
      </div>

      <label>
        Amount:
        <input
          type="number"
          class="rounded"
          value={@amount}
          min="1"
          phx-keydown="update_amount"
          phx-keyup="update_amount"
        />
      </label>
    </div>
    """
  end

  def mount(_session, _params, socket) do
    {:ok, assign(socket, %{number: 10, amount: 1})}
  end

  def handle_event("subtract", _values, socket) do
    {:noreply, assign(socket, :number, socket.assigns.number - socket.assigns.amount)}
  end

  def handle_event("add", _values, socket) do
    {:noreply, assign(socket, :number, socket.assigns.number + socket.assigns.amount)}
  end

  def handle_event("update_amount", %{"value" => amount_str}, socket) do
    {:noreply, assign(socket, :amount, String.to_integer(amount_str))}
  end
end
