# R Directory Structure Review

## Current State

### What Exists Now:
```
R/
├── functions/              # Helper functions (currently here)
│   ├── apiHelpers.R
│   ├── dataHelpers.R
│   ├── geocodingHelpers.R
│   └── mapHelpers.R
├── scripts/                # Workflow scripts
│   ├── 0-setUp.R          # Package setup (should this be here or in R/ root?)
│   ├── 1-dataAcquisition.R
│   └── 2-dataProcessing.R
└── README.md
```

### Issues to Resolve:

1. **Helper Functions Location**: 
   - Currently in `R/functions/`
   - Scripts reference them as `R/apiHelpers.R` (expecting them in R/ root)
   - README says they should be directly in `R/`

2. **0-setUp.R Location**:
   - Currently in `R/scripts/`
   - Should it be in `R/` root (since it's not a workflow script)?

3. **Path References**:
   - Scripts use `here::here("R", "apiHelpers.R")` 
   - But files are actually in `R/functions/apiHelpers.R`

## Proposed Structure Options

### Option A: Flat Structure (Simpler)
```
R/
├── 0-setUp.R              # Package setup
├── apiHelpers.R           # Helper functions directly in R/
├── dataHelpers.R
├── geocodingHelpers.R
├── mapHelpers.R
├── scripts/                # Only workflow scripts
│   ├── 1-dataAcquisition.R
│   ├── 2-dataProcessing.R
│   ├── 3-coverSheet.R
│   └── ... (3-11, 99)
└── README.md
```

### Option B: Organized Structure (Current)
```
R/
├── 0-setUp.R              # Package setup (move from scripts/)
├── functions/              # Helper functions
│   ├── apiHelpers.R
│   ├── dataHelpers.R
│   ├── geocodingHelpers.R
│   └── mapHelpers.R
├── scripts/                # Workflow scripts
│   ├── 1-dataAcquisition.R
│   └── ... (2-11, 99)
└── README.md
```

## Questions to Decide:

1. **Where should helper functions live?**
   - Directly in `R/` (Option A) - simpler paths
   - In `R/functions/` (Option B) - more organized

2. **Where should 0-setUp.R live?**
   - In `R/` root (it's setup, not a workflow script)
   - Keep in `R/scripts/` (numbered for execution order)

3. **How should scripts source helpers?**
   - If Option A: `source(here::here("R", "apiHelpers.R"))`
   - If Option B: `source(here::here("R", "functions", "apiHelpers.R"))`

## Recommendation

**Option A (Flat Structure)** - Simpler and cleaner:
- All helper functions directly in `R/`
- `0-setUp.R` in `R/` root
- Only numbered workflow scripts in `R/scripts/`
- Easier paths, less nesting

## Next Steps

1. Decide on structure (A or B)
2. Move files to match chosen structure
3. Update all path references in scripts
4. Update README to reflect final structure

