package divelog

import (
	"encoding/xml"
	"errors"
	"time"
)

var ErrInvalidUDDF = errors.New("could not parse UDDF file")

// uddfDocument mirrors just the subset of the UDDF schema (uddf.org) this app cares about —
// every other element (equipment, gasdefinitions, buddies, etc.) is simply ignored by
// encoding/xml, not an exhaustive model of the format.
type uddfDocument struct {
	DiveSite struct {
		Site []struct {
			ID        string `xml:"id,attr"`
			Name      string `xml:"name"`
			Geography struct {
				Latitude  *float64 `xml:"latitude"`
				Longitude *float64 `xml:"longitude"`
			} `xml:"geography"`
		} `xml:"site"`
	} `xml:"divesite"`
	ProfileData struct {
		RepetitionGroup []struct {
			Dive []uddfDive `xml:"dive"`
		} `xml:"repetitiongroup"`
	} `xml:"profiledata"`
}

type uddfDive struct {
	InformationBefore struct {
		DateTime string `xml:"datetime"`
		Link     struct {
			Ref string `xml:"ref,attr"`
		} `xml:"link"`
	} `xml:"informationbeforedive"`
	Samples struct {
		Waypoint []struct {
			Depth       *float64 `xml:"depth"`
			DiveTime    *float64 `xml:"divetime"`
			Temperature *float64 `xml:"temperature"` // Kelvin, per the UDDF spec
		} `xml:"waypoint"`
	} `xml:"samples"`
	InformationAfter struct {
		GreatestDepth     *float64 `xml:"greatestdepth"`
		DiveDuration      *float64 `xml:"diveduration"`
		LowestTemperature *float64 `xml:"lowesttemperature"`
	} `xml:"informationafterdive"`
}

// ParsedDive is one dive extracted from a UDDF file, still in the file's own units —
// ToEntry converts it into the app's Entry shape (Celsius, minutes, one user).
type ParsedDive struct {
	DivedAt        time.Time
	MaxDepthM      *float64
	DurationSecs   *float64
	MinTempKelvin  *float64
	SiteName       *string
	Latitude       *float64
	Longitude      *float64
	ProfileSamples []ProfileSample
}

// ParseUDDF extracts every <dive> in the file across all repetition groups. A file with no
// recognizable dives (wrong format, or a UDDF export of something else, like equipment
// definitions only) is reported as ErrInvalidUDDF rather than silently returning nothing.
func ParseUDDF(data []byte) ([]ParsedDive, error) {
	var doc uddfDocument
	if err := xml.Unmarshal(data, &doc); err != nil {
		return nil, ErrInvalidUDDF
	}

	siteNames := map[string]string{}
	siteLat := map[string]float64{}
	siteLon := map[string]float64{}
	for _, site := range doc.DiveSite.Site {
		siteNames[site.ID] = site.Name
		if site.Geography.Latitude != nil {
			siteLat[site.ID] = *site.Geography.Latitude
		}
		if site.Geography.Longitude != nil {
			siteLon[site.ID] = *site.Geography.Longitude
		}
	}

	var dives []ParsedDive
	for _, group := range doc.ProfileData.RepetitionGroup {
		for _, d := range group.Dive {
			parsed, ok := parseDive(d, siteNames, siteLat, siteLon)
			if ok {
				dives = append(dives, parsed)
			}
		}
	}
	if len(dives) == 0 {
		return nil, ErrInvalidUDDF
	}
	return dives, nil
}

// parseDive returns ok=false for a <dive> with no usable start time — everything else
// (depth, duration, site) is optional and just left nil/empty when absent from the file.
func parseDive(d uddfDive, siteNames map[string]string, siteLat, siteLon map[string]float64) (ParsedDive, bool) {
	divedAt, err := parseUDDFTime(d.InformationBefore.DateTime)
	if err != nil {
		return ParsedDive{}, false
	}

	var samples []ProfileSample
	var maxDepthFromSamples *float64
	var minTempFromSamples *float64
	for _, wp := range d.Samples.Waypoint {
		if wp.Depth == nil || wp.DiveTime == nil {
			continue
		}
		var tempC *float64
		if wp.Temperature != nil {
			c := kelvinToCelsius(*wp.Temperature)
			tempC = &c
			if minTempFromSamples == nil || c < *minTempFromSamples {
				minTempFromSamples = &c
			}
		}
		if maxDepthFromSamples == nil || *wp.Depth > *maxDepthFromSamples {
			maxDepthFromSamples = wp.Depth
		}
		samples = append(samples, ProfileSample{
			OffsetSeconds: int(*wp.DiveTime),
			DepthM:        *wp.Depth,
			TemperatureC:  tempC,
		})
	}

	maxDepth := d.InformationAfter.GreatestDepth
	if maxDepth == nil {
		maxDepth = maxDepthFromSamples
	}

	duration := d.InformationAfter.DiveDuration
	if duration == nil && len(samples) > 0 {
		last := float64(samples[len(samples)-1].OffsetSeconds)
		duration = &last
	}

	var minTempKelvin *float64
	if d.InformationAfter.LowestTemperature != nil {
		minTempKelvin = d.InformationAfter.LowestTemperature
	} else if minTempFromSamples != nil {
		k := celsiusToKelvin(*minTempFromSamples)
		minTempKelvin = &k
	}

	var siteName *string
	var lat, lon *float64
	if ref := d.InformationBefore.Link.Ref; ref != "" {
		if name, ok := siteNames[ref]; ok && name != "" {
			siteName = &name
		}
		if v, ok := siteLat[ref]; ok {
			lat = &v
		}
		if v, ok := siteLon[ref]; ok {
			lon = &v
		}
	}

	return ParsedDive{
		DivedAt:        divedAt,
		MaxDepthM:      maxDepth,
		DurationSecs:   duration,
		MinTempKelvin:  minTempKelvin,
		SiteName:       siteName,
		Latitude:       lat,
		Longitude:      lon,
		ProfileSamples: samples,
	}, true
}

// ToEntry converts a parsed dive (file units) into the app's storage shape (Celsius, minutes).
func (p ParsedDive) ToEntry() Entry {
	e := Entry{
		Source:         SourceImported,
		DivedAt:        p.DivedAt,
		MaxDepthM:      p.MaxDepthM,
		SiteName:       p.SiteName,
		Latitude:       p.Latitude,
		Longitude:      p.Longitude,
		ProfileSamples: p.ProfileSamples,
	}
	if p.DurationSecs != nil {
		minutes := int(*p.DurationSecs / 60)
		e.DurationMinutes = &minutes
	}
	if p.MinTempKelvin != nil {
		c := kelvinToCelsius(*p.MinTempKelvin)
		e.MinTemperatureC = &c
	}
	return e
}

func kelvinToCelsius(k float64) float64 { return k - 273.15 }
func celsiusToKelvin(c float64) float64 { return c + 273.15 }

// parseUDDFTime accepts the two datetime shapes real-world exports actually produce: full
// RFC3339 (with or without a timezone offset) and the bare "2006-01-02T15:04:05" some tools
// emit without one — treated as UTC in that case, same fallback Subsurface itself uses.
func parseUDDFTime(s string) (time.Time, error) {
	if s == "" {
		return time.Time{}, errors.New("empty datetime")
	}
	if t, err := time.Parse(time.RFC3339, s); err == nil {
		return t, nil
	}
	if t, err := time.Parse("2006-01-02T15:04:05", s); err == nil {
		return t.UTC(), nil
	}
	return time.Time{}, errors.New("unrecognized datetime format: " + s)
}
