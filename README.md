# nf-mod-dorado


Nextflow module for dorado. Used as a git submodule by pipelines.

Image: `ghcr.io/eit-gbi/nf-mod-dorado:latest`

## Processes

- `DORADO` — TODO: describe inputs/outputs

## Use as submodule
```bash
git submodule add https://github.com/eit-gbi/nf-mod-dorado.git modules/dorado
```

Then in your pipeline:
```
include { DORADO } from './modules/dorado/main.nf'
```
