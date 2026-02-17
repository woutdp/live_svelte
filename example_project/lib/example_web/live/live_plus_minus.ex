defmodule ExampleWeb.LivePlusMinus do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center gap-4 p-4">
      <h2 class="text-center text-2xl font-light my-4">
        Plus / Minus (LiveView)
      </h2>
      <p class="text-sm text-base-content/50 text-center max-w-sm">
        Native LiveView: value and step amount are both server state.
      </p>
      <div class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden w-full max-w-xs">
        <div class="card-body gap-4 p-5">
          <span class="badge badge-ghost badge-sm font-medium text-base-content/70 w-fit">
            Value
          </span>
          <div class="flex flex-row items-center justify-center gap-6 py-2">
            <button
              class="btn btn-square btn-sm btn-outline border-base-300 hover:border-error hover:text-error"
              phx-click="subtract"
              aria-label={"Decrease by #{@amount}"}
              data-testid="live-plus-minus-minus"
            >
              -<%= @amount %>
            </button>
            <span class="text-3xl font-bold tabular-nums text-brand min-w-[3rem] text-center" data-testid="live-plus-minus-value"><%= @number %></span>
            <button
              class="btn btn-square btn-sm btn-success border-0"
              phx-click="add"
              aria-label={"Increase by #{@amount}"}
              data-testid="live-plus-minus-plus"
            >
              +<%= @amount %>
            </button>
          </div>
          <label class="flex flex-col gap-1.5 mx-auto">
            <span class="text-xs font-medium text-base-content/50">Step amount</span>
            <input
              type="number"
              class="input input-bordered input-sm w-24 bg-base-200/50 border-base-300"
              value={@amount}
              min="1"
              name="amount"
              phx-blur="update_amount"
              phx-keydown="update_amount"
              phx-keyup="update_amount"
              aria-label="Step amount"
            />
          </label>
        </div>
      </div>
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

  def handle_event("update_amount", %{"value" => value}, socket) do
    amount_str = extract_amount_value(value)
    amount = if is_binary(amount_str) and amount_str != "" do
      case Integer.parse(amount_str) do
        {n, _} when n >= 1 -> n
        _ -> socket.assigns.amount
      end
    else
      socket.assigns.amount
    end
    {:noreply, assign(socket, :amount, amount)}
  end

  defp extract_amount_value(str) when is_binary(str), do: str
  defp extract_amount_value(%{"value" => v}), do: extract_amount_value(v)
  defp extract_amount_value(_), do: ""
end
