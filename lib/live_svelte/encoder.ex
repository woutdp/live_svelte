defprotocol LiveSvelte.Encoder do
  @moduledoc """
  Protocol for encoding values for LiveSvelte JSON serialization.

  Transforms structs and other terms into JSON-compatible data (maps, lists,
  primitives) before the configured JSON library encodes to a string. Supports
  `@derive` with `:only` and `:except` to control which struct fields are
  encoded. By default all keys except `:__struct__` are encoded.

  ## Deriving

  * `@derive LiveSvelte.Encoder` — encode all struct fields except `:__struct__`
  * `@derive {LiveSvelte.Encoder, only: [:a, :b]}` — encode only listed keys
  * `@derive {LiveSvelte.Encoder, except: [:secret]}` — encode all except listed keys

  ## Example

      defmodule User do
        @derive {LiveSvelte.Encoder, except: [:password]}
        defstruct [:name, :email, :password]
      end

  For structs you don't own, use `Protocol.derive/3` outside the module.
  """

  @type t :: term()
  @type opts :: Keyword.t()
  @fallback_to_any true

  @doc "Encodes a value to a JSON-compatible term (map, list, or primitive)."
  @spec encode(t(), opts()) :: any()
  def encode(value, opts \\ [])
end

defimpl LiveSvelte.Encoder, for: Integer do
  def encode(value, _opts), do: value
end

defimpl LiveSvelte.Encoder, for: Float do
  def encode(value, _opts), do: value
end

defimpl LiveSvelte.Encoder, for: BitString do
  def encode(value, _opts), do: value
end

defimpl LiveSvelte.Encoder, for: Atom do
  def encode(atom, _opts), do: atom
end

defimpl LiveSvelte.Encoder, for: List do
  def encode(list, opts) do
    Enum.map(list, &LiveSvelte.Encoder.encode(&1, opts))
  end
end

defimpl LiveSvelte.Encoder, for: Map do
  def encode(map, opts) do
    Map.new(map, fn {key, value} ->
      {key, LiveSvelte.Encoder.encode(value, opts)}
    end)
  end
end

defimpl LiveSvelte.Encoder, for: [Date, Time, NaiveDateTime, DateTime] do
  def encode(value, _opts) do
    @for.to_iso8601(value)
  end
end

defimpl LiveSvelte.Encoder, for: Phoenix.HTML.Form do
  def encode(%Phoenix.HTML.Form{} = form, opts) do
    LiveSvelte.Encoder.encode(
      %{
        name: form.name,
        values: encode_form_values(form, opts),
        errors: encode_form_errors(form) || %{},
        valid: get_form_validity(form)
      },
      opts
    )
  rescue
    error in [Protocol.UndefinedError] ->
      reraise maybe_enhance_error(error), __STACKTRACE__
  end

  defp get_form_validity(%{source: %{valid?: valid}}), do: valid
  defp get_form_validity(_), do: true

  if Code.ensure_loaded?(Ecto.Association.NotLoaded) do
    defp maybe_enhance_error(%{value: %Ecto.Association.NotLoaded{}} = error) do
      Map.update!(error, :description, fn description ->
        [first | rest] = String.split(description, "\n\n")
        addition = "\n\nEncode form with LiveSvelte.Encoder.encode(form, nilify_not_loaded: true) to avoid."
        Enum.join([first | [addition | rest]], "\n\n")
      end)
    end

    defp maybe_enhance_error(error), do: error
  else
    defp maybe_enhance_error(error), do: error
  end

  if Code.ensure_loaded?(Ecto.Changeset) do
    @relations [:embed, :assoc]

    defp collect_changeset_values(%Ecto.Changeset{} = source, opts) do
      data = Map.new(source.types, fn {field, type} -> {field, get_field_value(source, field, type, opts)} end)
      result = if is_struct(source.data), do: Map.merge(source.data, data), else: data
      Map.delete(result, :__meta__)
    end

    defp get_field_value(source, field, {tag, %{cardinality: :one}}, opts) when tag in @relations do
      case Map.fetch(source.changes, field) do
        {:ok, nil} -> nil
        {:ok, %Ecto.Changeset{} = changeset} -> collect_changeset_values(changeset, opts)
        :error ->
          case Map.fetch!(source.data, field) do
            %Ecto.Association.NotLoaded{} = not_loaded ->
              if opts[:nilify_not_loaded], do: nil, else: not_loaded
            %{__meta__: _} = value -> Map.delete(value, :__meta__)
            value -> value
          end
      end
    end

    defp get_field_value(source, field, {tag, %{cardinality: :many}}, opts) when tag in @relations do
      case Map.fetch(source.changes, field) do
        {:ok, changesets} ->
          changesets
          |> Enum.filter(&(&1.params != nil))
          |> Enum.map(&collect_changeset_values(&1, opts))
        :error ->
          case Map.fetch!(source.data, field) do
            %Ecto.Association.NotLoaded{} = not_loaded ->
              if opts[:nilify_not_loaded], do: nil, else: not_loaded
            [%{__meta__: _} | _] = value -> Enum.map(value, &Map.delete(&1, :__meta__))
            value -> value
          end
      end
    end

    defp get_field_value(source, field, _type, _opts) do
      Phoenix.HTML.FormData.Ecto.Changeset.input_value(source, %{params: source.params}, field)
    end

    if Code.ensure_loaded?(Phoenix.HTML.FormData.Ecto.Changeset) do
      def encode_form_values(%{impl: Phoenix.HTML.FormData.Ecto.Changeset, source: source}, opts) do
        source |> collect_changeset_values(opts) |> LiveSvelte.Encoder.encode(opts)
      end
    end
  end

  def encode_form_values(form, opts) do
    base_values =
      form.hidden
      |> Map.new()
      |> Map.merge(form.data)
      |> Map.merge(Map.new(form.params))

    LiveSvelte.Encoder.encode(base_values, opts)
  end

  if Code.ensure_loaded?(Ecto.Changeset) do
    defp collect_changeset_errors(%Ecto.Changeset{} = changeset) do
      errors = translate_errors(changeset.errors)
      Enum.reduce(changeset.changes, errors, fn {field, value}, acc ->
        case Map.get(changeset.types, field) do
          {tag, %{cardinality: :one}} when tag in @relations ->
            embed_errors = collect_changeset_errors(value)
            if embed_errors == %{}, do: acc, else: Map.put(acc, field, embed_errors)

          {tag, %{cardinality: :many}} when tag in @relations ->
            list_errors =
              value
              |> Enum.filter(&(&1.params != nil))
              |> Enum.map(fn embed_changeset ->
                embed_errors = collect_changeset_errors(embed_changeset)
                if embed_errors == %{}, do: nil, else: embed_errors
              end)
            if Enum.all?(list_errors, &is_nil/1), do: acc, else: Map.put(acc, field, list_errors)

          _ -> acc
        end
      end)
    end

    if Code.ensure_loaded?(Phoenix.HTML.FormData.Ecto.Changeset) do
      def encode_form_errors(%{impl: Phoenix.HTML.FormData.Ecto.Changeset} = form) do
        collect_changeset_errors(form.source)
      end
    end
  end

  def encode_form_errors(form) do
    translate_errors(form.errors)
  end

  defp translate_errors(errors) do
    Map.new(errors, fn {field, error} ->
      {field, error |> List.wrap() |> Enum.map(&translate_error/1)}
    end)
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", value |> List.wrap() |> Enum.map_join(", ", &to_string/1))
    end)
  end
end

if Code.ensure_loaded?(Ecto.Changeset) do
  defimpl LiveSvelte.Encoder, for: Ecto.Changeset do
    def encode(%Ecto.Changeset{} = cs, opts) do
      LiveSvelte.Encoder.encode(
        %{
          params: cs.params,
          changes: cs.changes,
          errors: changeset_errors_to_map(cs),
          valid?: cs.valid?
        },
        opts
      )
    end

    defp changeset_errors_to_map(%Ecto.Changeset{} = changeset) do
      errors = changeset_errors_to_list(changeset.errors)

      Enum.reduce(changeset.changes, errors, fn {field, value}, acc ->
        case Map.get(changeset.types, field) do
          {:embed, %{cardinality: :one}} when is_struct(value, Ecto.Changeset) ->
            embed_errors = changeset_errors_to_map(value)
            if embed_errors == %{}, do: acc, else: Map.put(acc, field, embed_errors)

          {:embed, %{cardinality: :many}} when is_list(value) ->
            list_errors =
              value
              |> Enum.filter(&match?(%Ecto.Changeset{}, &1))
              |> Enum.map(fn embed_cs ->
                embed_errors = changeset_errors_to_map(embed_cs)
                if embed_errors == %{}, do: nil, else: embed_errors
              end)
            if Enum.all?(list_errors, &is_nil/1), do: acc, else: Map.put(acc, field, list_errors)

          {:assoc, %{cardinality: :one}} when is_struct(value, Ecto.Changeset) ->
            embed_errors = changeset_errors_to_map(value)
            if embed_errors == %{}, do: acc, else: Map.put(acc, field, embed_errors)

          {:assoc, %{cardinality: :many}} when is_list(value) ->
            list_errors =
              value
              |> Enum.filter(&match?(%Ecto.Changeset{}, &1))
              |> Enum.map(fn assoc_cs ->
                assoc_errors = changeset_errors_to_map(assoc_cs)
                if assoc_errors == %{}, do: nil, else: assoc_errors
              end)
            if Enum.all?(list_errors, &is_nil/1), do: acc, else: Map.put(acc, field, list_errors)

          _ ->
            acc
        end
      end)
    end

    defp changeset_errors_to_list(errors) do
      Map.new(errors, fn {field, error} ->
        {field, error |> List.wrap() |> Enum.map(&error_tuple_to_message/1)}
      end)
    end

    defp error_tuple_to_message({msg, opts}) do
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", value |> List.wrap() |> Enum.map_join(", ", &to_string/1))
      end)
    end
  end
end

if Code.ensure_loaded?(Phoenix.LiveView) do
  defimpl LiveSvelte.Encoder, for: Phoenix.LiveView.UploadConfig do
    def encode(%Phoenix.LiveView.UploadConfig{} = struct, opts) do
      errors =
        Enum.map(struct.errors, fn {key, value} ->
          %{ref: key, error: LiveSvelte.Encoder.encode(value, opts)}
        end)

      entries =
        Enum.map(struct.entries, fn entry ->
          encoded = LiveSvelte.Encoder.encode(entry, opts)
          entry_errors = errors |> Enum.filter(&(&1.ref == entry.ref)) |> Enum.map(& &1.error)
          Map.put(encoded, :errors, entry_errors)
        end)

      LiveSvelte.Encoder.encode(
        %{
          ref: struct.ref,
          name: struct.name,
          accept: struct.accept,
          max_entries: struct.max_entries,
          auto_upload: struct.auto_upload?,
          entries: entries,
          errors: errors
        },
        opts
      )
    end
  end

  defimpl LiveSvelte.Encoder, for: Phoenix.LiveView.UploadEntry do
    def encode(%Phoenix.LiveView.UploadEntry{} = struct, opts) do
      LiveSvelte.Encoder.encode(
        %{
          ref: struct.ref,
          client_name: struct.client_name,
          client_size: struct.client_size,
          client_type: struct.client_type,
          progress: struct.progress,
          done: struct.done?,
          valid: struct.valid?,
          preflighted: struct.preflighted?
        },
        opts
      )
    end
  end
end

defimpl LiveSvelte.Encoder, for: Any do
  defmacro __deriving__(module, struct, opts) do
    fields = fields_to_encode(struct, opts)

    quote do
      defimpl LiveSvelte.Encoder, for: unquote(module) do
        def encode(struct, opts) do
          struct
          |> Map.take(unquote(fields))
          |> LiveSvelte.Encoder.encode(opts)
        end
      end
    end
  end

  # Default for structs without explicit impl: encode all keys except __struct__ and __meta__
  # (matches @derive LiveSvelte.Encoder default; __meta__ stripped for Ecto schemas).
  def encode(%{__struct__: _module} = struct, opts) do
    keys = Map.keys(struct) -- [:__struct__, :__meta__]
    struct
    |> Map.take(keys)
    |> LiveSvelte.Encoder.encode(opts)
  end

  def encode(value, _opts), do: value

  defp fields_to_encode(struct, opts) do
    fields = Map.keys(struct)

    cond do
      only = Keyword.get(opts, :only) ->
        case only -- fields do
          [] -> only
          error_keys ->
            raise ArgumentError,
              ":only specified keys (#{inspect(error_keys)}) not in defstruct: #{inspect(fields -- [:__struct__])}"
        end

      except = Keyword.get(opts, :except) ->
        case except -- fields do
          [] -> fields -- [:__struct__ | except]
          error_keys ->
            raise ArgumentError,
              ":except specified keys (#{inspect(error_keys)}) not in defstruct: #{inspect(fields -- [:__struct__])}"
        end

      true ->
        fields -- [:__struct__]
    end
  end
end
