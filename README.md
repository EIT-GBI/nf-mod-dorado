# nf-mod-__NAME__

<!-- TEMPLATE:START -->
> **Template repo.** Create a new module via GitHub's "Use this template", naming it `nf-mod-<tool>`. The `init-from-template` workflow auto-runs on the first push: it derives `<tool>` from the repo name, replaces `__NAME__` / `__NAME_UPPER__` tokens, strips this block, and removes itself.
>
> Manual fallback (e.g. running locally before pushing, or if the repo name doesn't start with `nf-mod-`): `./scripts/init.sh <name>`.
>
> Afterwards, edit the remaining `TODO`s in `Dockerfile` and `main.nf` for the tool's actual version, command, and IO.
<!-- TEMPLATE:END -->

Nextflow module for __NAME__. Used as a git submodule by pipelines.

Image: `ghcr.io/eit-gbi/nf-mod-__NAME__:latest`

## Processes

- `__NAME_UPPER__` — TODO: describe inputs/outputs

## Use as submodule
```bash
git submodule add https://github.com/eit-gbi/nf-mod-__NAME__.git modules/__NAME__
```

Then in your pipeline:
```
include { __NAME_UPPER__ } from './modules/__NAME__/main.nf'
```
