package main

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"io"
	"os"
	"strings"
)

// reformatComments accepts some text content that is associated with a given
// file and fileset, and using the provided line length, reformats all block
// comments to fit that length.
func reformatComments(
	content string,
	file *ast.File,
	fset *token.FileSet,
	opts options,
) string {
	// If this looks like a generated source file (e.g. `go generate ...`),
	// ignore it.
	for _, commentGroup := range file.Comments {
		for _, comment := range commentGroup.List {
			text := comment.Text
			if strings.Contains(text, "Code generated") && strings.Contains(text, "DO NOT EDIT") {
				return content
			}
		}
	}

	lines := strings.Split(content, "\n")

	type commentToReformat struct {
		comments []*ast.Comment
		lineIdx  int
	}
	var toReformat []commentToReformat

	for _, commentGroup := range file.Comments {
		comments := commentGroup.List
		if len(comments) == 0 {
			continue
		}

		// Check if this is a block of comments at the beginning of a line
		firstComment := comments[0]
		pos := fset.Position(firstComment.Pos())
		lineIdx := pos.Line - 1

		if lineIdx < 0 || lineIdx >= len(lines) {
			continue
		}

		line := lines[lineIdx]
		beforeComment := line[:pos.Column-1]

		// Only handle if the comment is at the beginning or only has
		// whitespace before it
		if strings.TrimSpace(beforeComment) != "" {
			continue
		}

		// Always reformat comment blocks to optimally wrap them
		toReformat = append(toReformat, commentToReformat{
			comments: comments,
			lineIdx:  lineIdx,
		})
	}

	// Process comments in reverse order to avoid index issues
	for i := len(toReformat) - 1; i >= 0; i-- {
		lines = reformatCommentGroup(lines, toReformat[i].comments, fset, opts)
	}

	return strings.Join(lines, "\n")
}

// isCommentedCode returns true if a comment block contains only valid Go code
func isCommentedCode(comments []*ast.Comment, commentPrefix string) bool {
	// Extract the text from all comments
	var textLines []string
	for _, comment := range comments {
		text := comment.Text
		// Remove the comment prefix
		text = strings.TrimPrefix(text, commentPrefix)
		text = strings.TrimPrefix(text, " ")
		textLines = append(textLines, text)
	}

	fullText := strings.Join(textLines, "\n")

	// Try to parse as a complete Go file
	fset := token.NewFileSet()
	_, err := parser.ParseFile(fset, "", fullText, parser.AllErrors)
	if err == nil {
		return true
	}

	// Try wrapping in a function and parsing
	wrappedText := "package main\nfunc _() {\n" + fullText + "\n}"
	_, err = parser.ParseFile(fset, "", wrappedText, parser.AllErrors)
	if err == nil {
		return true
	}

	// Try wrapping as top-level declarations
	wrappedText = "package main\n" + fullText
	_, err = parser.ParseFile(fset, "", wrappedText, parser.AllErrors)
	if err == nil {
		return true
	}

	return false
}

// detectBlockCommentPattern analyzes the interior of a block comment to
// determine what prefix pattern is used for interior lines. Returns the
// prefix (e.g., " *", " ", "") and whether there's a space after it.
func detectBlockCommentPattern(commentText string) (prefix string, hasSpaceAfter bool) {
	// Remove /* and */ delimiters
	text := strings.TrimPrefix(commentText, "/*")
	text = strings.TrimSuffix(text, "*/")
	lines := strings.Split(text, "\n")

	// Single-line comment has no pattern
	if len(lines) <= 1 {
		// Check if there's a space after /*
		if len(text) > 0 && (text[0] == ' ' || text[0] == '\t') {
			return "", true
		}

		return "", false
	}

	// Collect interior lines (exclude first and last)
	var interiorLines []string
	for i := 1; i < len(lines)-1; i++ {
		interiorLines = append(interiorLines, lines[i])
	}

	if len(interiorLines) == 0 {
		return "", true
	}

	// Check first interior line for pattern
	firstLine := interiorLines[0]

	// Look for " * " pattern
	if strings.HasPrefix(firstLine, " *") {
		if len(firstLine) > 2 && firstLine[2] == ' ' {
			return " *", true
		}

		return " *", false
	}

	// Look for just spaces
	spaceCount := 0
	for i := 0; i < len(firstLine); i++ {
		if firstLine[i] == ' ' {
			spaceCount++
		} else {
			break
		}
	}

	if spaceCount > 0 {
		return strings.Repeat(" ", spaceCount), false
	}

	// No pattern detected
	return "", false
}

// reformatBlockComment reformats a single block comment (/* ... */)
func reformatBlockComment(
	lines []string,
	comment *ast.Comment,
	fset *token.FileSet,
	opts options,
) []string {
	pos := fset.Position(comment.Pos())
	lineIdx := pos.Line - 1

	if lineIdx < 0 || lineIdx >= len(lines) {
		return lines
	}

	line := lines[lineIdx]
	indent := line[:pos.Column-1]
	indentWithSpaces := strings.ReplaceAll(indent, "\t", strings.Repeat(" ", opts.tabLength))

	// Check for noformat directive
	if strings.Contains(comment.Text, "gocomments:noformat") {
		return lines
	}

	// Detect the pattern used in the comment
	prefix, hasSpaceAfter := detectBlockCommentPattern(comment.Text)

	// Extract text content from the block comment and group into paragraphs
	text := strings.TrimPrefix(comment.Text, "/*")
	text = strings.TrimSuffix(text, "*/")

	// Split into lines
	textLines := strings.Split(text, "\n")

	// For single-line comments, check if it contains code
	if len(textLines) <= 1 {
		// Skip code detection for single-line -- just reformat
	} else {
		// Check if this is commented-out code
		var codeLines []string
		for i, line := range textLines {
			// Skip first and last line (they're typically empty or just
			// delimiters)
			if i == 0 || i == len(textLines)-1 {
				continue
			}

			// Remove the prefix pattern if present
			if prefix != "" && strings.HasPrefix(line, prefix) {
				line = strings.TrimPrefix(line, prefix)
				if hasSpaceAfter && len(line) > 0 && line[0] == ' ' {
					line = line[1:]
				}
			} else {
				line = strings.TrimLeft(line, " \t")
			}

			codeLines = append(codeLines, line)
		}

		// Try to parse as code
		fullText := strings.Join(codeLines, "\n")
		fset := token.NewFileSet()

		// Try parsing as statements
		wrappedText := "package main\nfunc _() {\n" + fullText + "\n}"
		_, err := parser.ParseFile(fset, "", wrappedText, parser.AllErrors)
		if err == nil {
			// This is code, don't reformat
			return lines
		}
	}

	// Extract content and group into paragraphs
	type paragraph struct {
		lines []string
	}
	var paragraphs []paragraph
	var currentParagraph paragraph

	for i, line := range textLines {
		// Skip first line if multi-line (typically empty after /*)
		if len(textLines) > 1 && i == 0 {
			if strings.TrimSpace(line) != "" {
				// First line has content, include it
				currentParagraph.lines = append(currentParagraph.lines, strings.TrimSpace(line))
			}
			continue
		}

		// Skip last line if multi-line (typically empty before */)
		if len(textLines) > 1 && i == len(textLines)-1 {
			continue
		}

		// Remove the prefix pattern if present
		var contentLine string
		if prefix != "" && strings.HasPrefix(line, prefix) {
			line = strings.TrimPrefix(line, prefix)
			if hasSpaceAfter && len(line) > 0 && line[0] == ' ' {
				line = line[1:]
			}
			contentLine = line
		} else {
			contentLine = strings.TrimLeft(line, " \t")
		}

		// Check if this is a paragraph delimiter (empty line)
		if strings.TrimSpace(contentLine) == "" {
			// Save current paragraph if it has content
			if len(currentParagraph.lines) > 0 {
				paragraphs = append(paragraphs, currentParagraph)
				currentParagraph = paragraph{}
			}
			// Add empty paragraph marker
			paragraphs = append(paragraphs, paragraph{lines: []string{""}})
		} else {
			currentParagraph.lines = append(currentParagraph.lines, contentLine)
		}
	}

	// Don't forget the last paragraph
	if len(currentParagraph.lines) > 0 {
		paragraphs = append(paragraphs, currentParagraph)
	}

	// Calculate available space for text For block comments, the line format
	// is: indent + " * " + text We account for " *" (2 chars) + space (1
	// char) + a margin (2 chars)
	availableLength := opts.lineLength - len(indentWithSpaces) - 5
	if availableLength <= 0 {
		availableLength = max(opts.lineLength-5, 40)
	}

	// Build the new block comment
	var newCommentLines []string
	newCommentLines = append(newCommentLines, indent+"/*")

	for _, para := range paragraphs {
		// Empty paragraph means blank line
		if len(para.lines) == 1 && para.lines[0] == "" {
			newCommentLines = append(newCommentLines, indent+" *")
			continue
		}

		// Join paragraph text and wrap it
		fullText := strings.Join(para.lines, " ")
		wrappedLines := wrapText(fullText, availableLength)

		// Add wrapped lines
		for _, wrappedLine := range wrappedLines {
			newCommentLines = append(newCommentLines, indent+" * "+wrappedLine)
		}
	}

	newCommentLines = append(newCommentLines, indent+" */")

	// Find the end line of the comment
	endPos := fset.Position(comment.End())
	lastLineIdx := endPos.Line - 1

	// Rebuild lines array
	newLines := make([]string, 0, len(lines)-(lastLineIdx-lineIdx)+len(newCommentLines))
	newLines = append(newLines, lines[:lineIdx]...)
	newLines = append(newLines, newCommentLines...)
	if lastLineIdx+1 < len(lines) {
		newLines = append(newLines, lines[lastLineIdx+1:]...)
	}

	return newLines
}

// reformatCommentGroup reformats one specific group of comments.
func reformatCommentGroup(
	lines []string,
	comments []*ast.Comment,
	fset *token.FileSet,
	opts options,
) []string {
	if len(comments) == 0 {
		return lines
	}

	// Get the indentation and slash count from the first comment
	firstPos := fset.Position(comments[0].Pos())
	firstLineIdx := firstPos.Line - 1
	firstLine := lines[firstLineIdx]

	indent := firstLine[:firstPos.Column-1]
	indentWithSpaces := strings.ReplaceAll(indent, "\t", strings.Repeat(" ", opts.tabLength))

	// Determine comment type and handle accordingly
	firstCommentText := comments[0].Text

	// Check if this is a block comment (/* ... */)
	if strings.HasPrefix(firstCommentText, "/*") {
		// Only reformat if it's a single block comment in this group
		if len(comments) != 1 {
			return lines
		}
		return reformatBlockComment(lines, comments[0], fset, opts)
	}

	// Handle line comments Determine the number of slashes
	slashCount := 2 // default to commenting with "//" as the leader

	// If there's more slashes in this block, keep them
	for i := 0; i < len(firstCommentText) && firstCommentText[i] == '/'; i++ {
		slashCount = i + 1
	}

	commentPrefix := strings.Repeat("/", slashCount)

	// Don't reformat Go directive comments (e.g., //go:embed, //go:build)
	// Only skip if there's NO space after the slashes and it starts with
	// "go:"
	firstCommentWithoutPrefix := strings.TrimPrefix(firstCommentText, commentPrefix)
	hasLeadingSpace := len(firstCommentWithoutPrefix) > 0 &&
		(firstCommentWithoutPrefix[0] == ' ' || firstCommentWithoutPrefix[0] == '\t')
	if !hasLeadingSpace && strings.HasPrefix(firstCommentWithoutPrefix, "go:") {
		return lines
	}

	// Don't reformat if the comment block contains valid Go code
	if isCommentedCode(comments, commentPrefix) {
		return lines
	}

	// Check for noformat directive in the first comment According to RFC 1,
	// the directive should be at the end of the first line
	if strings.Contains(comments[0].Text, "gocomments:noformat") {
		return lines
	}

	// Calculate available space for text. If we're running really low on
	// available space, we'll push out the width of the comment to 40
	availableLength := opts.lineLength - len(indentWithSpaces) - len(commentPrefix) - 1
	if availableLength <= 0 {
		availableLength = max(opts.lineLength-len(commentPrefix)-1, 40)
	}

	// Group comments into paragraphs (separated by empty comment lines)
	type paragraph struct {
		texts           []string
		hasLeadingSpace bool
		originalLines   []string // preserve original lines for noformat directive
	}
	var paragraphs []paragraph
	currentParagraph := paragraph{hasLeadingSpace: true}

	for _, comment := range comments {
		text := comment.Text
		originalLine := comment.Text // save original before modifications

		// Remove the leading slashes and any space after them
		text = strings.TrimPrefix(text, commentPrefix)
		hasLeadingSpace := len(text) > 0 && (text[0] == ' ' || text[0] == '\t')
		text = strings.TrimPrefix(text, " ")

		if paragraphDelimiter(text) {
			// Save current paragraph if it has content
			if len(currentParagraph.texts) > 0 {
				paragraphs = append(paragraphs, currentParagraph)
				currentParagraph = paragraph{}
			}

			// Add a new paragraph to represent the next paragraph. If text
			// was blank (e.g. it's just a blank line comment), then that's
			// what gets added. But if it's a list item, then it'll contain
			// that.
			currentParagraph.hasLeadingSpace = hasLeadingSpace
			paragraphs = append(paragraphs, paragraph{
				texts:           []string{text},
				hasLeadingSpace: hasLeadingSpace,
				originalLines:   []string{originalLine},
			})
		} else {
			if len(currentParagraph.texts) == 0 {
				currentParagraph.hasLeadingSpace = hasLeadingSpace
			}
			currentParagraph.texts = append(currentParagraph.texts, text)
			currentParagraph.originalLines = append(currentParagraph.originalLines, originalLine)
		}
	}

	// Don't forget the last paragraph
	if len(currentParagraph.texts) > 0 {
		paragraphs = append(paragraphs, currentParagraph)
	}

	// Wrap each paragraph independently
	var newCommentLines []string
	for _, para := range paragraphs {
		// Empty paragraph means blank line
		if len(para.texts) == 1 && para.texts[0] == "" {
			newCommentLines = append(newCommentLines, indent+commentPrefix)
			continue
		}

		// Check if first line has the noformat directive
		if len(para.texts) > 0 && strings.HasSuffix(strings.TrimSpace(para.texts[0]), "gocomments:noformat") {
			// Preserve original formatting
			for _, originalLine := range para.originalLines {
				newCommentLines = append(newCommentLines, indent+originalLine)
			}
			continue
		}

		// Join the paragraph text and wrap it
		fullText := strings.Join(para.texts, " ")
		wrappedLines := wrapText(fullText, availableLength)

		// Build the comment lines for this paragraph
		for _, wrappedLine := range wrappedLines {
			sep := " "
			if !para.hasLeadingSpace {
				sep = ""
			}

			newCommentLines = append(newCommentLines, indent+commentPrefix+sep+wrappedLine)
		}
	}

	// Replace the old comment lines with new ones
	lastLineIdx := fset.Position(comments[len(comments)-1].End()).Line - 1

	// Rebuild lines array
	newLines := make([]string, 0, len(lines)-(lastLineIdx-firstLineIdx)+len(newCommentLines))
	newLines = append(newLines, lines[:firstLineIdx]...)
	newLines = append(newLines, newCommentLines...)
	if lastLineIdx+1 < len(lines) {
		newLines = append(newLines, lines[lastLineIdx+1:]...)
	}

	return newLines
}

// formatStdin is a wrapper that takes data from stdin and gives it to the
// reformatComments function to update. As an outcome, it prints its data back
// to stdout.
func formatStdin(opts options) error {
	content, err := io.ReadAll(os.Stdin)
	if err != nil {
		return err
	}

	fset := token.NewFileSet()
	file, err := parser.ParseFile(fset, "<stdin>", content, parser.ParseComments)
	if err != nil {
		return err
	}

	result := reformatComments(string(content), file, fset, opts)

	fmt.Print(result)

	return nil
}
