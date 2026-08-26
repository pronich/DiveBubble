package divelog

import (
	"database/sql"
	"errors"
	"os"
	"strconv"
	"time"

	_ "modernc.org/sqlite"
)

var ErrInvalidSQLite = errors.New("could not read this SQLite dive log — expected a Diving Log 6 export")

// parseDivingLogSQLite reads a Diving Log 6 (tenderson software) export — despite the ".sql"
// extension some versions give it, the file is an actual SQLite database, not SQL text (see
// parseImportFile's magic-byte sniff).
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
		SELECT Divedate, Entrytime, Country, Place, Divetime, Depth, DepthAvg, Watertemp, Profile, Profile2, ProfileInt
		FROM Logbook
	`)
	if err != nil {
		return nil, ErrInvalidSQLite
	}
	defer rows.Close()

	var entries []Entry
	for rows.Next() {
		var divedate string
		var entrytime, country, place, profile, profile2 sql.NullString
		var divetime, depth, depthAvg, watertemp sql.NullFloat64
		var profileInt sql.NullInt64
		if err := rows.Scan(
			&divedate, &entrytime, &country, &place, &divetime, &depth, &depthAvg, &watertemp,
			&profile, &profile2, &profileInt,
		); err != nil {
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

		if samples := decodeDivingLogProfile(profile.String, profile2.String, int(profileInt.Int64)); samples != nil {
			e.ProfileSamples = samples
			// The decoded curve is more precise than the single stored summary stats for
			// exactly the cases those stats are missing (older DepthAvg is often NULL for
			// newer watch-sourced dives) or coarser (Watertemp is one averaged reading, the
			// samples let us report the dive's actual minimum) — prefer it over the column
			// whenever we have it, rather than only using it as a fallback.
			var depthSum, minTemp float64
			var minTempSet bool
			for _, s := range samples {
				depthSum += s.DepthM
				if s.TemperatureC != nil && (!minTempSet || *s.TemperatureC < minTemp) {
					minTemp = *s.TemperatureC
					minTempSet = true
				}
			}
			avg := depthSum / float64(len(samples))
			e.AvgDepthM = &avg
			if minTempSet {
				e.MinTemperatureC = &minTemp
			}
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

// decodeDivingLogProfile decodes Diving Log 6's own undocumented (but empirically verified —
// cross-checked against this same file's Depth/DepthAvg/Watertemp summary columns until the
// averages matched) sample encoding: Profile is a flat string of fixed-width 12-character
// chunks, one per sample, whose first 4 characters are the depth in decimeters (e.g. "0122"
// = 12.2m); Profile2 is the same idea at 11 characters per chunk, whose first 2 characters
// are the water temperature in whole degrees Celsius (0 across the board on older entries
// from a device with no temperature sensor — treated as "no temperature data" below, same as
// UDDF's own per-waypoint optional temperature). Returns nil if either column doesn't divide
// evenly by its chunk width, doesn't match the other's sample count, or there's no usable
// sample interval — a dive just keeps its summary stats and no graph in that case, same as
// before this function existed.
func decodeDivingLogProfile(profile, profile2 string, intervalSeconds int) []ProfileSample {
	const depthChunkWidth = 12
	const tempChunkWidth = 11
	if intervalSeconds <= 0 || len(profile) == 0 || len(profile)%depthChunkWidth != 0 {
		return nil
	}
	n := len(profile) / depthChunkWidth

	hasTemp := len(profile2) > 0 && len(profile2)%tempChunkWidth == 0 && len(profile2)/tempChunkWidth == n

	samples := make([]ProfileSample, n)
	for i := 0; i < n; i++ {
		chunk := profile[i*depthChunkWidth : i*depthChunkWidth+depthChunkWidth]
		depthDm, err := strconv.Atoi(chunk[:4])
		if err != nil {
			return nil // one malformed sample means the whole decode is untrustworthy
		}
		samples[i] = ProfileSample{OffsetSeconds: i * intervalSeconds, DepthM: float64(depthDm) / 10}

		if hasTemp {
			tempChunk := profile2[i*tempChunkWidth : i*tempChunkWidth+tempChunkWidth]
			tempC, err := strconv.Atoi(tempChunk[:2])
			if err == nil && tempC > 0 {
				v := float64(tempC)
				samples[i].TemperatureC = &v
			}
		}
	}
	return samples
}
