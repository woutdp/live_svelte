defmodule LiveSvelte.CspNonceTest do
  use ExUnit.Case, async: true

  defp render_html(opts) do
    %{
      __changed__: nil,
      socket: nil,
      name: "TestComponent",
      id: "test-csp",
      key: nil,
      props: %{},
      ssr: false,
      class: nil,
      loading: [],
      inner_block: [],
      csp_nonce: opts[:csp_nonce],
      csp_script_nonce: opts[:csp_script_nonce],
      csp_style_nonce: opts[:csp_style_nonce]
    }
    |> LiveSvelte.svelte()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  setup do
    %{nonce: System.unique_integer([:positive])}
  end

  test "no nonce attributes when none specified" do
    refute render_html(%{}) =~ "nonce="
  end

  test "csp_nonce applies to both script and style", %{nonce: nonce} do
    html = render_html(%{csp_nonce: nonce})

    assert html =~ ~r/<script nonce="#{nonce}">/
    assert html =~ ~r/<style nonce="#{nonce}">/
  end

  test "csp_script_nonce applies only to script", %{nonce: nonce} do
    html = render_html(%{csp_script_nonce: nonce})

    assert html =~ ~r/<script nonce="#{nonce}">/
    refute html =~ ~r/<style nonce=/
  end

  test "csp_style_nonce applies only to style", %{nonce: nonce} do
    html = render_html(%{csp_style_nonce: nonce})

    assert html =~ ~r/<style nonce="#{nonce}">/
    refute html =~ ~r/<script nonce=/
  end

  test "separate script and style nonces", %{nonce: nonce} do
    html = render_html(%{csp_script_nonce: nonce, csp_style_nonce: nonce * 2})

    assert html =~ ~r/<script nonce="#{nonce}">/
    assert html =~ ~r/<style nonce="#{nonce * 2}">/
  end
end
