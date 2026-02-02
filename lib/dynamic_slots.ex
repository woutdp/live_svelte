defmodule LiveSvelte.DynamicSlots do
  @moduledoc false

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      # Mark Phoenix's generated __components__/0 as overridable, then override it.
      # Phoenix generates __components__/0 but doesn't mark it as overridable.
      defoverridable __components__: 0

      # Override Phoenix's __components__/0 to skip slot validation for the svelte component.
      #
      # Phoenix LiveView 1.x uses __components__/0 to get component definitions for validation.
      # The verification code does:
      #   component = submod.__components__()[fun]
      #
      # If this returns nil, the verification is skipped entirely for that component.
      # This allows LiveSvelte to accept arbitrary slot names without warnings.
      def __components__ do
        # Return empty map so __components__()[:svelte] returns nil
        # This skips slot/attr validation entirely for the svelte component
        %{}
      end
    end
  end
end
