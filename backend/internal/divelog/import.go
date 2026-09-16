package divelog

import (
	"bytes"
	"errors"
)

var ErrUnrecognizedFormat = errors.New("unrecognized dive log file format")

var sqliteMagic = []byte("SQLite format 3\x00")

// parseImportFile sniffs the file's actual bytes rather than its filename/extension, since Diving Log 6's SQLite export is literally named ".sql" despite not being SQL text.
func parseImportFile(data []byte) ([]Entry, error) {
	switch {
	case bytes.HasPrefix(data, sqliteMagic):
		return parseDivingLogSQLite(data)
	case looksLikeXML(data):
		dives, err := ParseUDDF(data)
		if err != nil {
			return nil, err
		}
		entries := make([]Entry, len(dives))
		for i, d := range dives {
			entries[i] = d.ToEntry()
		}
		return entries, nil
	case looksLikeCSV(data):
		return ParseCSV(data)
	default:
		return nil, ErrUnrecognizedFormat
	}
}

func looksLikeXML(data []byte) bool {
	// "\xef\xbb\xbf" is a UTF-8 byte-order-mark some XML exporters still prepend.
	trimmed := bytes.TrimLeft(data, " \t\r\n\xef\xbb\xbf")
	return bytes.HasPrefix(trimmed, []byte("<"))
}

// looksLikeCSV requires the first line to contain a "date" column, so garbage input gets a clear "unrecognized format" error instead of silently importing as zero dives.
func looksLikeCSV(data []byte) bool {
	firstLine, _, _ := bytes.Cut(data, []byte("\n"))
	return bytes.Contains(bytes.ToLower(firstLine), []byte("date"))
}
