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
          %{label: "Hybrid Counter", to: ~p"/live-plus-minus-hybrid"},
          %{label: "Drag & Drop", to: ~p"/live-drag-drop"},
          %{label: "Static + List", to: ~p"/live-static-color"}
        ]
      },
      %{
        label: "Data",
        links: [
          %{label: "Log List", to: ~p"/live-log-list"},
          %{label: "Breaking News", to: ~p"/live-breaking-news"},
          %{label: "Chat", to: ~p"/live-chat"},
          %{label: "Props Diff", to: ~p"/live-props-diff"},
          %{label: "ID List Diff", to: ~p"/live-id-list-diff"},
          %{label: "Streams", to: ~p"/streams"}
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
          %{label: "Client Loading", to: ~p"/live-client-side-loading"},
          %{label: "Rich Editor (@attach)", to: ~p"/live-editor"},
          %{label: "Runed Utilities", to: ~p"/live-runed"},
          %{label: "Svelte Stores", to: ~p"/live-stores"},
          %{label: "SSR Demo", to: ~p"/live-ssr"}
        ]
      },
      %{
        label: "Ecto",
        links: [
          %{label: "Notes (OTP)", to: ~p"/live-notes-otp"}
        ]
      },
      %{
        label: "Composables",
        links: [
          %{label: "Form (useLiveForm)", to: ~p"/live-form"},
          %{label: "Navigation (useLiveNavigation)", to: ~p"/live-navigation"},
          %{label: "Composition (useLiveSvelte)", to: ~p"/live-composition"},
          %{label: "File Upload (useLiveUpload)", to: ~p"/live-upload"},
          %{label: "Event Reply (useEventReply)", to: ~p"/live-event-reply"}
        ]
      }
    ]
  end

  def nav_sidebar_items(assigns) do
    assigns = assign(assigns, :nav_groups, nav_groups())

    ~H"""
    <nav class="flex flex-1 flex-col" data-nav-list>
      <ul role="list" class="flex flex-1 flex-col gap-y-5">
        <li :for={group <- @nav_groups} data-nav-group>
          <div class="app-label">{group.label}</div>
          <ul role="list" class="-mx-1 mt-1.5 space-y-0.5">
            <li :for={link <- group.links} data-nav-item>
              <a href={link.to} data-nav-link class="app-nav-link">
                {link.label}
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
    <nav class="hidden lg:flex lg:items-center lg:gap-0.5">
      <div :for={group <- @nav_groups} class="app-nav-group relative">
        <button type="button" class="app-nav-btn px-3 py-2">
          {group.label}
          <.icon name="hero-chevron-down" class="ml-0.5 inline h-3.5 w-3.5 opacity-50" />
        </button>
        <div class="app-nav-menu">
          <a :for={link <- group.links} href={link.to} data-nav-link class="app-nav-link">
            {link.label}
          </a>
        </div>
      </div>
    </nav>
    """
  end
end
