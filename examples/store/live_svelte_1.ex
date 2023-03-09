defmodule ExamplesWeb.LiveSvelte1 do
  use ExamplesWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mt-2 flex flex-col">
      <%!-- Both work --%>
      <.link navigate={~p"/svelte-2"}>svelte-2 with navigate</.link>
      <.link patch={~p"/svelte-2"}>svelte-2 with patch</.link>
    </div>
    <.live_component module={LiveSvelte} name="StoreExample1" id="id"/>
    """
  end
end
