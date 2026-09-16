package divelog

import (
	"encoding/csv"
	"errors"
	"strconv"
	"strings"
	"time"
)

var ErrInvalidCSV = errors.New("could not parse CSV file — check the column headers")

// ParseCSV expects DiveBubble's own documented column template (date required, everything else optional and left nil if absent), matched case-insensitively in any order, not an attempt to guess other exporters' shapes.
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

// parseCSVDateTime accepts "YYYY-MM-DD" alone or with "HH:MM", treated as UTC since a plain CSV carries no timezone info, same fallback the UDDF parser uses.
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
