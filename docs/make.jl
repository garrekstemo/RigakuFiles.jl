using Documenter, RigakuFiles

DocMeta.setdocmeta!(RigakuFiles, :DocTestSetup, :(using RigakuFiles); recursive = true)

makedocs(
    sitename = "RigakuFiles.jl",
    modules = [RigakuFiles],
    authors = "Garrek Stemo <8449000+garrekstemo@users.noreply.github.com> and contributors",
    repo = Remotes.GitHub("garrekstemo", "RigakuFiles.jl"),
    checkdocs = :exports,
    format = Documenter.HTML(;
        canonical = "https://garrekstemo.github.io/RigakuFiles.jl",
        edit_link = "main",
        assets = String[],
    ),
    pages = [
        "Introduction" => "index.md",
        "Guide" => Any[
            "Quick start" => "guide/quickstart.md",
            "File formats" => "guide/formats.md",
        ],
        "Library" => "lib/public.md",
    ],
)

deploydocs(
    repo = "github.com/garrekstemo/RigakuFiles.jl.git",
    devbranch = "main",
    push_preview = true,
)
