# Cloud Compute Reference — Modal (v1)

This file is read by Claude to know what commands to run for cloud GPU experiments.
Claude runs these commands directly, same pattern as GStack running `git push`.

## Auth Check

Before any cloud operation, verify Modal is authenticated:
```bash
modal token info
```
If this fails, tell user: "Modal not authenticated. Run `! modal token new` to log in."

## Running an Experiment

Modal's `modal run` command blocks until the experiment completes and streams stdout/stderr.
No async polling needed.

```bash
modal run train.py 2>&1 | tee .rstack/results/run-NNN/stdout.log
```

For GPU selection, the experiment code should include a Modal decorator:
```python
import modal
app = modal.App("rstack-experiment")

@app.function(gpu="A100", timeout=600)
def train():
    # training code here
    pass
```

Common GPU types: `"T4"`, `"A10G"`, `"A100"`, `"H100"`

## Artifact Output Contract

ALL experiment code MUST write outputs to `/output/` on the Modal container:
- `/output/metrics.json` — final metrics (loss, accuracy, etc.)
- `/output/figures/*.png` — any generated plots
- `/output/*.csv` — any tabular results
- `/output/*.log` — detailed logs

After `modal run` completes, download artifacts:
```bash
# Modal volumes (if using persistent storage)
modal volume get rstack-output /output/ .rstack/results/run-NNN/

# Or if outputs are printed to stdout, parse them from the log
```

## Error Classification

When an experiment fails, classify the error from stderr:

| Pattern in stderr | Error type | Retryable? | Suggestion |
|-------------------|-----------|------------|------------|
| `ModuleNotFoundError` | import_error | Yes | Add package to requirements.txt |
| `OutOfMemoryError` or `CUDA out of memory` | memory_error | Yes | Reduce batch_size or model size |
| `FileNotFoundError` | file_not_found | Yes | Check data paths, verify dataset downloaded |
| `TimeoutError` or killed by timeout | timeout | Yes | Reduce training duration or dataset size |
| `RuntimeError: CUDA` | cuda_error | Maybe | Check CUDA version compatibility |
| Exit code non-zero with no clear pattern | unknown | No | Show last 50 lines of output to user |

Max 3 retry attempts per experiment. After 3 failures, ask user for guidance.

## Cost Awareness

- T4: ~$0.20/hour
- A10G: ~$0.60/hour
- A100: ~$2.50/hour
- H100: ~$4.00/hour

Always show estimated cost before submission: "GPU: A100, estimated duration: ~10 min, estimated cost: ~$0.42"
These are approximate. Modal bills per second of actual usage.
