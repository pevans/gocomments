package main

import (
	"go/parser"
	"go/token"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestCommentReformatting(t *testing.T) {
	tests := []struct {
		name       string
		input      string
		lineLength int
		tabLength  int
		want       string
	}{
		{
			name:       "long comment wrapped at 78 chars",
			lineLength: 78,
			tabLength:  4,
			input: `package main

// This is a very long comment that exceeds the default line length of 78 characters and should be reformatted into multiple lines
func example() {}
`,
			want: `package main

// This is a very long comment that exceeds the default line length of 78
// characters and should be reformatted into multiple lines
func example() {}
`,
		},
		{
			name:       "triple slash preserved",
			lineLength: 78,
			tabLength:  4,
			input: `package main

/// This is a very long comment with three slashes that also exceeds the line length and needs to be wrapped properly
func example() {}
`,
			want: `package main

/// This is a very long comment with three slashes that also exceeds the line
/// length and needs to be wrapped properly
func example() {}
`,
		},
		{
			name:       "indented comment preserved",
			lineLength: 78,
			tabLength:  4,
			input: `package main

func example() {
	// This comment is indented and is also very long, exceeding the maximum line length, so it should be reformatted as well
	println("test")
}
`,
			want: `package main

func example() {
	// This comment is indented and is also very long, exceeding the maximum
	// line length, so it should be reformatted as well
	println("test")
}
`,
		},
		{
			name:       "short comment not reformatted",
			lineLength: 78,
			tabLength:  4,
			input: `package main

// Short comment
func example() {}
`,
			want: `package main

// Short comment
func example() {}
`,
		},
		{
			name:       "custom line length respected",
			lineLength: 50,
			tabLength:  4,
			input: `package main

// This is a longer comment that will be wrapped at 50 characters
func example() {}
`,
			want: `package main

// This is a longer comment that will be wrapped
// at 50 characters
func example() {}
`,
		},
		{
			name:       "multiple comment blocks",
			lineLength: 60,
			tabLength:  4,
			input: `package main

// First long comment that needs to be wrapped because it exceeds the limit
func example1() {}

// Second long comment that also needs to be wrapped because it is too long
func example2() {}
`,
			want: `package main

// First long comment that needs to be wrapped because it
// exceeds the limit
func example1() {}

// Second long comment that also needs to be wrapped because
// it is too long
func example2() {}
`,
		},
		{
			name:       "inline comments not reformatted",
			lineLength: 50,
			tabLength:  4,
			input: `package main

func example() {
	x := 42 // This is a very long inline comment that exceeds the line length but should not be reformatted
	y := 100 // Another long comment at the end of a line that also exceeds the maximum length
	return x + y
}
`,
			want: `package main

func example() {
	x := 42 // This is a very long inline comment that exceeds the line length but should not be reformatted
	y := 100 // Another long comment at the end of a line that also exceeds the maximum length
	return x + y
}
`,
		},
		{
			name:       "comment without leading space preserved",
			lineLength: 78,
			tabLength:  4,
			input: `package main

//This is a comment without a leading space
func example() {}
`,
			want: `package main

//This is a comment without a leading space
func example() {}
`,
		},
		{
			name:       "long comment without leading space wrapped correctly",
			lineLength: 50,
			tabLength:  4,
			input: `package main

//This is a very long comment without a leading space that needs to be wrapped
func example() {}
`,
			want: `package main

//This is a very long comment without a leading
//space that needs to be wrapped
func example() {}
`,
		},
		{
			name:       "triple slash without leading space preserved",
			lineLength: 60,
			tabLength:  4,
			input: `package main

///Documentation comment without leading space
func example() {}
`,
			want: `package main

///Documentation comment without leading space
func example() {}
`,
		},
		{
			name:       "long triple slash without leading space wrapped correctly",
			lineLength: 50,
			tabLength:  4,
			input: `package main

///This is a long documentation comment without leading space that needs wrapping
func example() {}
`,
			want: `package main

///This is a long documentation comment without
///leading space that needs wrapping
func example() {}
`,
		},
		{
			name:       "mixed spacing in paragraph uses first line's spacing",
			lineLength: 80,
			tabLength:  4,
			input: `package main

//First line without space
// Second line with space
//Third line without space
func example() {}
`,
			want: `package main

//First line without space Second line with space Third line without space
func example() {}
`,
		},
		{
			name:       "noformat directive preserves formatting",
			lineLength: 50,
			tabLength:  4,
			input: `package main

// This is a very long comment that would normally be wrapped but has gocomments:noformat
func example() {}
`,
			want: `package main

// This is a very long comment that would normally be wrapped but has gocomments:noformat
func example() {}
`,
		},
		{
			name:       "noformat directive preserves multi-line formatting",
			lineLength: 50,
			tabLength:  4,
			input: `package main

// This is a long comment gocomments:noformat
// that spans multiple lines
// and should not be reformatted
func example() {}
`,
			want: `package main

// This is a long comment gocomments:noformat
// that spans multiple lines
// and should not be reformatted
func example() {}
`,
		},
		{
			name:       "noformat directive only affects its paragraph",
			lineLength: 50,
			tabLength:  4,
			input: `package main

// This long comment should be wrapped because it has no directive and is too long
//
// But this one should not be reformatted gocomments:noformat
func example() {}
`,
			want: `package main

// This long comment should be wrapped because it
// has no directive and is too long
//
// But this one should not be reformatted gocomments:noformat
func example() {}
`,
		},
		{
			name:       "noformat with unusual spacing preserved",
			lineLength: 50,
			tabLength:  4,
			input: `package main

// Unusual    spacing     here  gocomments:noformat
//    and   here   too
func example() {}
`,
			want: `package main

// Unusual    spacing     here  gocomments:noformat
//    and   here   too
func example() {}
`,
		},
		{
			name:       "block comment not reformatted",
			lineLength: 50,
			tabLength:  4,
			input: `package main

/* This is a very long block comment that would normally be wrapped if it was a line comment but should not be reformatted */
func example() {}
`,
			want: `package main

/* This is a very long block comment that would normally be wrapped if it was a line comment but should not be reformatted */
func example() {}
`,
		},
		{
			name:       "multi-line block comment not reformatted",
			lineLength: 50,
			tabLength:  4,
			input: `package main

/*
This is a multi-line block comment
   with unusual formatting
      and indentation that should be preserved
*/
func example() {}
`,
			want: `package main

/*
This is a multi-line block comment
   with unusual formatting
      and indentation that should be preserved
*/
func example() {}
`,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Parse the input
			fset := token.NewFileSet()
			file, err := parser.ParseFile(fset, "test.go", tt.input, parser.ParseComments)
			assert.NoError(t, err, "failed to parse input")

			// Reformat
			got := reformatComments(tt.input, file, fset, tt.lineLength, tt.tabLength)

			assert.Equal(t, tt.want, got, "reformatComments() output mismatch")
		})
	}
}
