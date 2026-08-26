package divelog

import (
	"encoding/csv"
	"errors"
	"strconv"
	"strings"
	"time"
)

var ErrInvalidCSV = errors.New("could not parse CSV file — check the column headers")

// ParseCSV expects a header row naming (a subset of) DiveBubble's own documented column
// template — date, time, country, site, max_depth_m, avg_depth_m, duration_min, min_temp_c,
// notes — not an attempt to guess anyone else's export shape. "date" is the only required
// column (matched by looksLikeCSV before this even runs); every other column is optional and
// simply left nil on the resulting Entry if absent or blank for a given row. Column names
// are matched case-insensitively and in any order.
func ParseCSV(data []byte) ([]Entry, error) {
	reader := csv.NewReader(strings.NewReader(string(data)))
	reader.FieldsPerRecord = -1 // rows may have trailing columns omitted

	header, err := reader.Read()
	if err != nil {
		return nil, ErrInvalidCSV
	}
	col := make(map[string]int, len(header))
	for i, name := range header {
		col[strings.ToLower(strings.TrimSpace(name))] = i
	}
	dateIdx, ok := col["date"]
	if !ok {
		return nil, ErrInvalidCSV
	}

	get := func(row []string, name string) string {
		i, ok := col[name]
		if !ok || i >= len(row) {
			return ""
		}
		return strings.TrimSpace(row[i])
	}

	var entries []Entry
	for {
		row, err := reader.Read()
		if err != nil {
			break // io.EOF (normal end) or a malformed row — either way, stop reading further rows
		}
		if dateIdx >= len(row) || strings.TrimSpace(row[dateIdx]) == "" {
			continue // blank/trailing row
		}

		divedAt, err := parseCSVDateTime(get(row, "date"), get(row, "time"))
		if err != nil {
			continue // unparseable date on this row — skip it rather than failing the whole import
		}

		e := Entry{
			DivedAt:         divedAt,
			MaxDepthM:       parseCSVFloat(get(row, "max_depth_m")),
			AvgDepthM:       parseCSVFloat(get(row, "avg_depth_m")),
			DurationMinutes: parseCSVInt(get(row, "duration_min")),
			MinTemperatureC: parseCSVFloat(get(row, "min_temp_c")),
		}
		if v := get(row, "country"); v != "" {
			e.Country = &v
		}
		if v := get(row, "site"); v != "" {
			e.SiteName = &v
		}
		if v := get(row, "notes"); v != "" {
			e.Notes = &v
		}
		entries = append(entries, e)
	}

	if len(entries) == 0 {
		return nil, ErrInvalidCSV
	}
	return entries, nil
}

// parseCSVDateTime accepts "YYYY-MM-DD" alone or with an "HH:MM" time column — treated as
// UTC in the absence of any timezone info in a plain CSV, same fallback the UDDF parser uses.
func parseCSVDateTime(date, timeStr string) (time.Time, error) {
	if timeStr == "" {
		timeStr = "00:00"
	}
	return time.Parse("2006-01-02 15:04", date+" "+timeStr)
}

func parseCSVFloat(s string) *float64 {
	if s == "" {
		return nil
	}
	v, err := strconv.ParseFloat(s, 64)
	if err != nil {
		return nil
	}
	return &v
}

func parseCSVInt(s string) *int {
	if s == "" {
		return nil
	}
	v, err := strconv.Atoi(s)
	if err != nil {
		return nil
	}
	return &v
}
