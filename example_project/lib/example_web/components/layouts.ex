defmodule ExampleWeb.Layouts do
  use ExampleWeb, :html

  embed_templates "layouts/*"

  # Single source of truth for main nav (sidebar + desktop). Layout has route helpers (~p).
  def nav_groups do
    [
      %{
        label: "Basics",
        links: [
          %{label: "Hello World", to: ~p"/hello-world"},
          %{label: "Lodash", to: ~p"/lodash"},
          %{label: "Struct Props", to: ~p"/live-struct"}
        ]
      },
      %{
        label: "Interactive",
        links: [
          %{label: "Counter", to: ~p"/live-simple-counter"},
          %{label: "Lights", to: ~p"/live-lights"},
          %{label: "Sigil", to: ~p"/live-sigil"},
          %{label: "Plus/Minus (Static)", to: ~p"/plus-minus-svelte"},
          %{label: "Plus/Minus (Live)", to: ~p"/live-plus-minus"},
          %{label: "Hybrid Counter", to: ~p"/live-plus-minus-hybrid"}
        ]
      },
      %{
        label: "Data",
        links: [
          %{label: "Log List", to: ~p"/live-log-list"},
          %{label: "Breaking News", to: ~p"/live-breaking-news"},
          %{label: "Chat", to: ~p"/live-chat"},
          %{label: "LiveJSON", to: ~p"/live-json"}
        ]
      },
      %{
        label: "Slots",
        links: [
          %{label: "Simple Slots", to: ~p"/live-slots-simple"},
          %{label: "Dynamic Slots", to: ~p"/live-slots-dynamic"}
        ]
      },
      %{
        label: "Advanced",
        links: [
          %{label: "Client Loading", to: ~p"/live-client-side-loading"}
        ]
      },
      %{
        label: "Ecto",
        links: [
          %{label: "Notes (OTP)", to: ~p"/live-notes-otp"}
        ]
      }
    ]
  end

  def nav_sidebar_items(assigns) do
    assigns = assign(assigns, :nav_groups, nav_groups())

    ~H"""
    <nav class="flex flex-1 flex-col">
      <ul role="list" class="flex flex-1 flex-col gap-y-7">
        <li :for={group <- @nav_groups}>
          <div class="text-xs font-semibold leading-6 text-base-content/40 uppercase tracking-wider">
            <%= group.label %>
          </div>
          <ul role="list" class="-mx-2 mt-2 space-y-1">
            <li :for={link <- group.links}>
              <a href={link.to} class="block px-3 py-2 rounded-md text-sm font-medium text-base-content hover:bg-base-200">
                <%= link.label %>
              </a>
            </li>
          </ul>
        </li>
      </ul>
    </nav>
    """
  end

  def nav_desktop_dropdowns(assigns) do
    assigns = assign(assigns, :nav_groups, nav_groups())

    ~H"""
    <nav class="hidden lg:flex lg:items-center lg:gap-1">
      <div :for={group <- @nav_groups} class="relative group">
        <button type="button" class="px-3 py-2 text-sm font-medium text-base-content rounded-md hover:bg-base-200">
          <%= group.label %>
        </button>
        <div class="absolute left-0 mt-1 w-48 bg-base-100 rounded-box shadow-lg border border-base-300 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-150 z-50">
          <div class="py-1">
            <a :for={link <- group.links} href={link.to} class="block px-4 py-2 text-sm text-base-content hover:bg-base-200">
              <%= link.label %>
            </a>
          </div>
        </div>
      </div>
    </nav>
    """
  end
end
