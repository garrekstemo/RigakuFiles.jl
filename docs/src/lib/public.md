```@meta
CurrentModule = RigakuFiles
```

# Public API

Only exported types and functions are considered part of the public API. Raw header fields not covered by the accessors below are still available through `scan.metadata`.

## Index

```@index
Pages = ["public.md"]
```

## Reading files

```@autodocs
Modules = [RigakuFiles]
Pages = ["parser.jl"]
Private = false
```

## Types

```@autodocs
Modules = [RigakuFiles]
Pages = ["types.jl"]
Private = false
```

## Metadata accessors

```@autodocs
Modules = [RigakuFiles]
Pages = ["utils.jl"]
Private = false
```
