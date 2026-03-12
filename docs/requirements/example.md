# Add CSV Export to Reports

## What

Add a "Export as CSV" button to the Reports page that lets users download the currently filtered report data as a CSV file. The export should respect any active filters (date range, category, status) so users get exactly the data they are looking at on screen.

### API

- `GET /api/reports/export` — streams a CSV file for the authenticated user's filtered report data
- Query parameters mirror the existing `/api/reports` endpoint: `from`, `to`, `category`, `status`
- Response content type: `text/csv`
- Response header: `Content-Disposition: attachment; filename="report-YYYY-MM-DD.csv"`

### UI

- Add an "Export CSV" button to the Reports page toolbar, next to the existing "Print" button
- While the download is in progress, show a spinner inside the button and set `aria-label="Downloading…"`
- Re-enable the button once the download completes or fails
- Show a dismissible inline error banner below the toolbar if the export fails (no browser `alert()` calls)

## Why

Users regularly copy report data into spreadsheets for further analysis in Excel or Google Sheets.
Currently they do this manually — selecting rows, copying, pasting, and reformatting values. This is
error-prone and time-consuming, especially for large result sets.

A one-click CSV export eliminates that friction. It is the most-requested feature in the last two
user surveys (mentioned by 34 of 80 respondents) and comes up repeatedly in customer support tickets.
Delivering it will reduce support load and improve satisfaction scores for power users.

## Acceptance Criteria

- Clicking "Export CSV" triggers a file download named `report-YYYY-MM-DD.csv` where the date is today's date
- The CSV includes a header row with human-readable column names (e.g. "Order ID", "Amount", "Status")
- Exported rows match exactly what is shown in the filtered table (same `from`, `to`, `category`, and `status` filters)
- If the filtered result set is empty, the export returns a CSV with only the header row — no error, no empty file
- Exporting more than 10,000 rows streams the response; the server must not buffer all rows in memory before sending
- The "Export CSV" button is disabled and shows a spinner while a download is in progress
- Triggering a second download while one is in progress is a no-op (button is disabled)
- If the server returns a non-2xx response, a dismissible error banner appears below the toolbar with the server's error message
- Unauthenticated requests to `/api/reports/export` return HTTP 401
- Requests with invalid filter parameters (e.g. `from` after `to`) return HTTP 400 with a descriptive error message

## Constraints

- Use the existing `db.query()` helper — do not add a new ORM, query builder, or database library
- Stream rows using Node.js `Readable` streams or an async generator; never buffer the full result set
- CSV format must follow RFC 4180: comma-separated fields, double-quoted strings, CRLF (`\r\n`) line endings
- Do not add new npm dependencies for CSV serialisation — the format is simple enough to handle inline
- All monetary values must appear as plain numbers with two decimal places (e.g. `1234.56`), no currency symbols
- Column order in the exported CSV must match the column order shown in the UI table
- The Export button must be keyboard-accessible and must update its `aria-label` during the download
- Do not change the existing `/api/reports` endpoint behaviour or its response schema
