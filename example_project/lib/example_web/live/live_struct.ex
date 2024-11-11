defmodule User do
  @derive Jason.Encoder
  defstruct name: "John", age: 27
end

defmodule ExampleWeb.LiveStruct do
  use ExampleWeb, :live_view

  @example_struct %User{name: "Bob", age: 42}

  def render(assigns) do
    ~H"""
    <h1 class="text-lg">An example of how to pass a struct to Svelte:</h1>
    <.svelte name="Struct" props={%{struct: @struct}} socket={@socket} />
    """
  end

  def mount(_session, _params, socket) do
    {:ok, assign(socket, :struct, @example_struct)}
  end

  def handle_event("randomize", _, socket) do
    {:noreply, assign(socket, :struct, %User{name: "Bob", age: Enum.random(0..100)})}
  end
end
