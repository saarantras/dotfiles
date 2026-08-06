---
name: read-paper
description: Use when the user wants you to read, summarize, or extract information from a research paper, academic article, or PDF. Also use when given a DOI, PubMed ID, arXiv ID, or journal URL.
---

# read-paper

## Getting the paper

Fetch open-access sources directly - arXiv (use the `/pdf/` URL), PubMed Central, bioRxiv and medRxiv (`.full.pdf`), PLoS, eLife, and journal article pages that render without a login.

For anything paywalled, ask. The user has institutional access and a download costs them about 20 seconds. Make it cheap for them: give a direct website or PDF link, not a title to go search for, and batch every paper you need into a single request rather than asking one at a time.

```
Please grab these and drop the paths here (or drag the files in):
  1. https://...
  2. https://...
```

Then wait. Do not summarize from metadata while waiting.

## Say what you actually read

An abstract, a PubMed record, a preprint landing page, or a search-result snippet is not the paper. Track which one you have, and say so.

Never present a sample size, effect size, statistical test, or methodological detail as the paper's when it came from an abstract. If a claim rests on partial access, flag it and offer the link: "the abstract reports X, but I have not seen the methods - want me to give you the link?" beats a confident summary assembled from metadata. The user would much rather spend 20 seconds downloading than act on something wrong.

This applies to absence too. Do not conclude a paper omits a control, a dataset, or an analysis when all you have seen is its abstract.

## Preprints and published versions

A preprint is not the final paper - numbers, figures, and conclusions routinely change in peer review.

bioRxiv and medRxiv flag this on the abstract page ("Now published in <journal> doi:..."). Check for it. If a published version exists, say so and offer to have the user pull it, since they usually can.

Use discretion. A recent or genuinely unpublished preprint is fine to work from, as is a preprint when the question is about something peer review would not have touched. Just do not present preprint results as settled literature, and do not assume the preprint is current when a published version exists.

## Reading the PDF

For simple reading and summarization, use the built-in Read tool directly on the PDF path - it handles PDFs natively without any extra tooling.

For programmatic/batch extraction (e.g. pulling tables, figures, bulk text from many files), use a Python PDF environment (see below).

## Python PDF environment

Only needed for programmatic extraction, not for simple reading.

### Find an existing env

```bash
conda env list
```

Look for names like `pdf`, `paper`, `lit`, `reading`, `pdftools`, `papers`. Check if it has PDF packages:

```bash
conda run -n <candidate> python -c "import fitz; print('pymupdf ok')"
conda run -n <candidate> python -c "import pdfplumber; print('pdfplumber ok')"
```

Use the first one that works.

### Create one if none found

```bash
conda create -n pdf-tools -y python=3.11 pymupdf pdfplumber
```

`pymupdf` (import as `fitz`) is the workhorse - fast, handles most PDFs well. `pdfplumber` is better for tables.

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
