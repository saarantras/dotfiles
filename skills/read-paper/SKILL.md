---
name: read-paper
description: Use when the user wants you to read, summarize, or extract information from a research paper, academic article, or PDF. Also use when given a DOI, PubMed ID, arXiv ID, or journal URL.
---

# read-paper

## Getting the PDF

**Do not try to WebFetch paywalled papers.** Agents hang or get redirected to login pages. Instead, give the user the URL and let them download it.

Paywalled by default -- give the user the URL, do not fetch:
- Elsevier / ScienceDirect (sciencedirect.com, linkinghub.elsevier.com)
- Nature / Springer (nature.com, link.springer.com) -- unless the URL contains `/articles/` and the paper looks open-access
- Cell Press (cell.com)
- Wiley (onlinelibrary.wiley.com)
- Annual Reviews (annualreviews.org)

Free to fetch directly:
- arXiv (arxiv.org/pdf/...) -- use the /pdf/ URL, not the abstract page
- PubMed Central (ncbi.nlm.nih.gov/pmc/...)
- bioRxiv / medRxiv (biorxiv.org, medrxiv.org) -- use the .full.pdf URL
- PLoS journals (journals.plos.org)
- eLife (elifesciences.org)

When in doubt, give the user the URL rather than hanging on a fetch.

### Asking the user to download

Give them the exact URL and a clear instruction:
```
Please download this and drop the path here (or just drag the file in):
  https://...
```

Wait. Do not proceed until the PDF path is provided.

## Reading the PDF

For simple reading and summarization, use the built-in Read tool directly on the PDF path -- it handles PDFs natively without any extra tooling.

For programmatic/batch extraction (e.g. pulling tables, figures, bulk text from many files), use a Python PDF environment (see below).

## Python PDF environment

Only needed for programmatic extraction, not for simple reading.

### Find an existing env

```bash
conda env list
```

Look for names like `pdf`, `paper`, `lit`, `reading`, `pdftools`, `papers`. Check if it has PDF packages:

```bash
conda run -n <candidate> python -c "import fitz; print('pymupdf ok')" 2>/dev/null
conda run -n <candidate> python -c "import pdfplumber; print('pdfplumber ok')" 2>/dev/null
```

Use the first one that works.

### Create one if none found

```bash
conda create -n pdf-tools -y python=3.11 pymupdf pdfplumber
```

`pymupdf` (import as `fitz`) is the workhorse -- fast, handles most PDFs well. `pdfplumber` is better for tables.

### Typical extraction snippet

```python
import fitz  # pymupdf

doc = fitz.open("paper.pdf")
text = "\n".join(page.get_text() for page in doc)
print(text)
```

For tables, prefer `pdfplumber`:
```python
import pdfplumber

with pdfplumber.open("paper.pdf") as pdf:
    for page in pdf.pages:
        table = page.extract_table()
        if table:
            print(table)
```
