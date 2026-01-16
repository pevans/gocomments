package main

import (
	"regexp"
	"strings"
)

var listItemPattern = regexp.MustCompile(`^\s*[-+*o] |^\s*\d+[.)] `)

// wrapText takes some given text and a length, and with that produces a set
// of lines which are accordingly wrapped.
func wrapText(text string, maxLength int) []string {
	if maxLength <= 0 {
		maxLength = 40
	}

	var result []string
	words := strings.Fields(text)

	if len(words) == 0 {
		return []string{""}
	}

	currentLine := words[0]

	// If this is a list item, we need to figure out how far indented it might
	// be so that we can preserve that indentation on each line after the
	// first
	indentLevel := 0
	if listItemPattern.MatchString(text) {
		// Add one for a space between the item and the rest of the paragraph
		indentLevel = len(currentLine) + 1

		for i := range text {
			if text[i] != ' ' {
				break
			}

			indentLevel++
			currentLine = " " + currentLine
		}
	}

	for _, word := range words[1:] {
		if len(currentLine)+1+len(word) <= maxLength {
			currentLine += " " + word
		} else {
			result = append(result, currentLine)
			currentLine = strings.Repeat(" ", indentLevel) + word
		}
	}

	if currentLine != "" {
		result = append(result, currentLine)
	}

	return result
}

// paragraphDelimiter returns true if we think we've found some break in the
// paragraph. A break would either be a blank line or the start of some list
// item.
func paragraphDelimiter(text string) bool {
	trimmed := strings.TrimSpace(text)

	return len(trimmed) == 0 || listItemPattern.MatchString(text)
}
