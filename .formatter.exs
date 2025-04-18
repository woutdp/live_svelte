# Used by "mix format"
[
  import_deps: [:phoenix],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  plugins: [
    Phoenix.LiveView.HTMLFormatter
  ]
]
