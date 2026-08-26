package divelog

import (
	"database/sql"
	"errors"
	"os"
	"time"

	_ "modernc.org/sqlite"
)

var ErrInvalidSQLite = errors.New("could not read this SQLite dive log — expected a Diving Log 6 export")

// parseDivingLogSQLite reads a Diving Log 6 (tenderson software) export — despite the ".sql"
// extension some versions give it, the file is an actual SQLite database, not SQL text (see
// parseImportFile's magic-byte sniff). Deliberately reads only the plain descriptive/summary
// columns off the Logbook table (date, time, country, site, max/avg depth, duration, water
// temp) — the app's own Profile/Profile2/... columns encoding the depth/temperature sample
// curve are an undocumented, version-specific format not safe to guess at, so imported dives
// from this source never get a profile_samples graph, same as a manual entry.
func parseDivingLogSQLite(data []byte) ([]Entry, error) {
	tmp, err := os.CreateTemp("", "divelog-import-*.sqlite")
	if err != nil {
		return nil, err
	}
	defer os.Remove(tmp.Name())
	defer tmp.Close()
	if _, err := tmp.Write(data); err != nil {
		return nil, err
	}
	if err := tmp.Close(); err != nil {
		return nil, err
	}

	db, err := sql.Open("sqlite", tmp.Name())
	if err != nil {
		return nil, err
	}
	defer db.Close()

	rows, err := db.Query(`
		SELECT Divedate, Entrytime, Country, Place, Divetime, Depth, DepthAvg, Watertemp
		FROM Logbook
	`)
	if err != nil {
		return nil, ErrInvalidSQLite
	}
	defer rows.Close()

	var entries []Entry
	for rows.Next() {
		var divedate string
		var entrytime, country, place sql.NullString
		var divetime, depth, depthAvg, watertemp sql.NullFloat64
		if err := rows.Scan(&divedate, &entrytime, &country, &place, &divetime, &depth, &depthAvg, &watertemp); err != nil {
			continue // one malformed row shouldn't sink the whole import
		}

		timeStr := "00:00"
		if entrytime.Valid && entrytime.String != "" {
			timeStr = entrytime.String
		}
		divedAt, err := time.Parse("2006-01-02 15:04", divedate+" "+timeStr)
		if err != nil {
			continue
		}

		e := Entry{DivedAt: divedAt}
		if depth.Valid {
			v := depth.Float64
			e.MaxDepthM = &v
		}
		if depthAvg.Valid {
			v := depthAvg.Float64
			e.AvgDepthM = &v
		}
		if divetime.Valid {
			minutes := int(divetime.Float64)
			e.DurationMinutes = &minutes
		}
		if watertemp.Valid {
			v := watertemp.Float64
			e.MinTemperatureC = &v
		}
		if country.Valid && country.String != "" {
			v := country.String
			e.Country = &v
		}
		if place.Valid && place.String != "" {
			v := place.String
			e.SiteName = &v
		}
		entries = append(entries, e)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if len(entries) == 0 {
		return nil, ErrInvalidSQLite
	}
	return entries, nil
}
