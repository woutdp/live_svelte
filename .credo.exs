%{
  configs: [
    %{
      name: "default",
      plugins: [{ExSlop, []}],
      checks: [
        {Credo.Check.Design.AliasUsage, false},
        {ExSlop.Check.Readability.NarratorDoc, false},
        {Credo.Check.Refactor.CyclomaticComplexity, [max_complexity: 25]},
        {Credo.Check.Refactor.Nesting, [max_nesting: 5]}
      ]
    }
  ]
}
