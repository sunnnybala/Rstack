# Venue Formatting Reference

## arXiv (v1 default)

- **Page limit**: No limit
- **Document class**: `\documentclass[11pt]{article}`
- **Citation style**: natbib (`\usepackage{natbib}`, `\bibliographystyle{plainnat}`)
- **Template**: `templates/arxiv/template.tex`
- **Required sections**:
  1. Abstract
  2. Introduction
  3. Related Work
  4. Method / Approach
  5. Experiments
  6. Results
  7. Conclusion
  8. References
- **Optional sections**: Acknowledgments, Appendix, Supplementary Material
- **Figures**: PDF or PNG, use `\includegraphics` with `graphicx` package
- **Tables**: Use `booktabs` package (`\toprule`, `\midrule`, `\bottomrule`)
- **Math**: `amsmath`, `amssymb` packages
- **URLs**: `\usepackage{hyperref}` with `colorlinks=true`

## NeurIPS (v1.1 — when 2026 .sty files are published)

- **Page limit**: 9 pages + unlimited appendix
- **Document class**: `neurips_2026.sty` (not yet available)
- **Layout**: Single column, 5.5 x 9 inch text area

## ICML (v1.1 — when 2026 .sty files are published)

- **Page limit**: 8 pages + unlimited appendix
- **Document class**: `icml2026.sty` (not yet available)
- **Layout**: Two column

## BibTeX Entry Format

For papers from `.rstack/lit-review.jsonl`, generate entries like:
```bibtex
@article{smith2025,
  title={Title of the Paper},
  author={Smith, Alice and Jones, Bob},
  journal={NeurIPS},
  year={2025},
  url={https://arxiv.org/abs/...}
}
```

Cite key format: `{firstauthorlastname}{year}` (lowercase, no spaces).
If duplicate keys: append a/b/c suffix.
