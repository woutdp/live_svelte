defmodule User do
  @derive Jason.Encoder
  defstruct name: "John", age: 27
end

defmodule ExampleWeb.LiveStruct do
  use ExampleWeb, :live_view

  @example_struct %User{name: "Bob", age: 42}

  def render(assigns) do
    ~H"""
    <h1 class="text-center text-2xl font-light my-4">
          Struct Demo
        </h1>
        <p class="text-sm text-base-content/50 mb-8 text-center">
          Passing a struct to Svelte.
        </p>

    <.svelte name="Struct" props={%{struct: @struct}} socket={@socket} />
    """
  end

  def mount(_session, _params, socket) do
    {:ok, assign(socket, :struct, @example_struct)}
  end

  def handle_event("randomize", _, socket) do
    new_struct = %User{name: "Bob", age: Enum.random(0..100)}
    {:noreply, assign(socket, :struct, new_struct)}
  end
end
