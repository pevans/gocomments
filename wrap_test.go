package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestWrapText(t *testing.T) {
	tests := []struct {
		name      string
		text      string
		maxLength int
		want      []string
	}{
		{
			name:      "short text no wrap",
			text:      "hello world",
			maxLength: 20,
			want:      []string{"hello world"},
		},
		{
			name:      "basic wrapping",
			text:      "this is a longer sentence that needs wrapping",
			maxLength: 20,
			want:      []string{"this is a longer", "sentence that needs", "wrapping"},
		},
		{
			name:      "empty text",
			text:      "",
			maxLength: 20,
			want:      []string{""},
		},
		{
			name:      "single word longer than max",
			text:      "supercalifragilisticexpialidocious",
			maxLength: 20,
			want:      []string{"supercalifragilisticexpialidocious"},
		},
		{
			name:      "URL not broken",
			text:      "See https://example.com/very/long/path/to/resource for details",
			maxLength: 30,
			want:      []string{"See", "https://example.com/very/long/path/to/resource", "for details"},
		},
		{
			name:      "zero maxLength uses default",
			text:      "hello world",
			maxLength: 0,
			want:      []string{"hello world"},
		},
		{
			name:      "negative maxLength uses default",
			text:      "hello world",
			maxLength: -10,
			want:      []string{"hello world"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := wrapText(tt.text, tt.maxLength)
			assert.Equal(t, tt.want, got)
		})
	}
}

func TestWrapTextBulletLists(t *testing.T) {
	tests := []struct {
		name      string
		text      string
		maxLength int
		want      []string
	}{
		{
			name:      "dash bullet wraps with indent",
			text:      "- First bullet item that is long enough to wrap",
			maxLength: 30,
			want:      []string{"- First bullet item that is", "  long enough to wrap"},
		},
		{
			name:      "asterisk bullet wraps with indent",
			text:      "* First asterisk item that is long enough to wrap",
			maxLength: 30,
			want:      []string{"* First asterisk item that is", "  long enough to wrap"},
		},
		{
			name:      "plus bullet wraps with indent",
			text:      "+ First plus item that is long enough to wrap",
			maxLength: 30,
			want:      []string{"+ First plus item that is long", "  enough to wrap"},
		},
		{
			name:      "letter o bullet wraps with indent",
			text:      "o First o item that is long enough to wrap",
			maxLength: 30,
			want:      []string{"o First o item that is long", "  enough to wrap"},
		},
		{
			name:      "indented bullet preserves leading spaces",
			text:      "  - Indented bullet that is long enough to wrap",
			maxLength: 30,
			want:      []string{"  - Indented bullet that is", "    long enough to wrap"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := wrapText(tt.text, tt.maxLength)
			assert.Equal(t, tt.want, got)
		})
	}
}

func TestWrapTextNumberedLists(t *testing.T) {
	tests := []struct {
		name      string
		text      string
		maxLength int
		want      []string
	}{
		{
			name:      "numbered dot wraps with indent",
			text:      "1. First numbered item that is long enough to wrap",
			maxLength: 30,
			want:      []string{"1. First numbered item that is", "   long enough to wrap"},
		},
		{
			name:      "numbered paren wraps with indent",
			text:      "1) First paren item that is long enough to wrap",
			maxLength: 30,
			want:      []string{"1) First paren item that is", "   long enough to wrap"},
		},
		{
			name:      "double digit number wraps with indent",
			text:      "10. Tenth item that is long enough to wrap properly",
			maxLength: 30,
			want:      []string{"10. Tenth item that is long", "    enough to wrap properly"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := wrapText(tt.text, tt.maxLength)
			assert.Equal(t, tt.want, got)
		})
	}
}

func TestParagraphDelimiter(t *testing.T) {
	tests := []struct {
		name string
		text string
		want bool
	}{
		{
			name: "empty string is delimiter",
			text: "",
			want: true,
		},
		{
			name: "whitespace only is delimiter",
			text: "   ",
			want: true,
		},
		{
			name: "dash bullet is delimiter",
			text: "- item",
			want: true,
		},
		{
			name: "asterisk bullet is delimiter",
			text: "* item",
			want: true,
		},
		{
			name: "plus bullet is delimiter",
			text: "+ item",
			want: true,
		},
		{
			name: "letter o bullet is delimiter",
			text: "o item",
			want: true,
		},
		{
			name: "numbered dot is delimiter",
			text: "1. item",
			want: true,
		},
		{
			name: "numbered paren is delimiter",
			text: "1) item",
			want: true,
		},
		{
			name: "regular text is not delimiter",
			text: "This is regular text",
			want: false,
		},
		{
			name: "text starting with number but no list marker",
			text: "1st place",
			want: false,
		},
		{
			name: "indented bullet is delimiter",
			text: "  - indented item",
			want: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := paragraphDelimiter(tt.text)
			assert.Equal(t, tt.want, got)
		})
	}
}
