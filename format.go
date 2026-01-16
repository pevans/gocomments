package main

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"io"
	"os"
	"regexp"
	"strings"
)

var listItemPattern = regexp.MustCompile(`^\s*[-+*o] |^\s*\d+[.)] `)

// reformatComments accepts some text content that is associated with a given
// file and fileset, and using the provided line length, reformats all block
// comments to fit that length.
func reformatComments(
	content string,
	file *ast.File,
	fset *token.FileSet,
	lineLength int,
	tabLength int,
) string {
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
		lines = reformatCommentGroup(lines, toReformat[i].comments, fset, lineLength, tabLength)
	}

	return strings.Join(lines, "\n")
}

// reformatCommentGroup reformats one specific group of comments.
func reformatCommentGroup(
	lines []string,
	comments []*ast.Comment,
	fset *token.FileSet,
	lineLength int,
	tabLength int,
) []string {
	if len(comments) == 0 {
		return lines
	}

	// Get the indentation and slash count from the first comment
	firstPos := fset.Position(comments[0].Pos())
	firstLineIdx := firstPos.Line - 1
	firstLine := lines[firstLineIdx]

	indent := firstLine[:firstPos.Column-1]
	indentWithSpaces := strings.ReplaceAll(indent, "\t", strings.Repeat(" ", tabLength))

	// Determine the number of slashes
	slashCount := 2 // default to commenting with "//" as the leader

	// If there's more slashes in this block, keep them
	firstCommentText := comments[0].Text
	for i := 0; i < len(firstCommentText) && firstCommentText[i] == '/'; i++ {
		slashCount = i + 1
	}

	commentPrefix := strings.Repeat("/", slashCount)

	// Calculate available space for text. If we're running really low on
	// available space, we'll push out the width of the comment to 40
	availableLength := lineLength - len(indentWithSpaces) - len(commentPrefix) - 1
	if availableLength <= 0 {
		availableLength = max(lineLength-len(commentPrefix)-1, 40)
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
func formatStdin(lineLength, tabLength int) error {
	content, err := io.ReadAll(os.Stdin)
	if err != nil {
		return err
	}

	fset := token.NewFileSet()
	file, err := parser.ParseFile(fset, "<stdin>", content, parser.ParseComments)
	if err != nil {
		return err
	}

	result := reformatComments(string(content), file, fset, lineLength, tabLength)

	fmt.Print(result)

	return nil
}

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
