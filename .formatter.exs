[
  inputs: [
    "{mix,.formatter}.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  locals_without_parens: [
    preset: 1,
    accept: 1,
    reject: 1,
    handle: 2
  ],
  export: [
    locals_without_parens: [
      preset: 1,
      accept: 1,
      reject: 1,
      handle: 2
    ]
  ]
]
