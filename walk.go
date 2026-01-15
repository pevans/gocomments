package main

import (
	"fmt"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strings"

	"github.com/pmezard/go-difflib/difflib"
)

// walkPath will walk through some unknown path and reformat any comments it
// finds, using the provided line length as its ruler.
func walkPath(path string, lineLength int, opts options) (bool, error) {
	// Recurse through all subdirectories of the provided path, but exclude
	// hidden directories found therein.
	if strings.HasSuffix(path, "/...") {
		baseDir := strings.TrimSuffix(path, "/...")
		return walkDirectory(baseDir, lineLength, opts, true)
	}

	info, err := os.Stat(path)
	if err != nil {
		return false, err
	}

	if info.IsDir() {
		return walkDirectory(path, lineLength, opts, false)
	}

	return visitFile(path, lineLength, opts)
}

func walkDirectory(dir string, lineLength int, opts options, skipHidden bool) (bool, error) {
	hasChanges := false

	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip hidden directories if requested; otherwise, returning nil will
		// signal that we want to recurse
		if info.IsDir() {
			if skipHidden && strings.HasPrefix(info.Name(), ".") && path != dir {
				return filepath.SkipDir
			}

			return nil
		}

		// If this isn't a Go file, return early with nil
		if !strings.HasSuffix(path, ".go") {
			return nil
		}

		// If we get here, then we actually want to visit the file we found
		changed, err := visitFile(path, lineLength, opts)
		if err != nil {
			return err
		}

		if changed {
			hasChanges = true
		}

		return nil
	})

	return hasChanges, err
}

// visitFile reads Go comments in an file and will perform one of several
// functions indicated in the provided options. It will, check to, in order:
// - write the changes back to the file
// - print a diff of what would change
// - list the file as something that might change
// - if nothing else, print the reformatted file to stdout
func visitFile(filename string, lineLength int, opts options) (bool, error) {
	content, err := os.ReadFile(filename)
	if err != nil {
		return false, err
	}

	fset := token.NewFileSet()
	file, err := parser.ParseFile(fset, filename, content, parser.ParseComments)
	if err != nil {
		return false, err
	}

	result := reformatComments(string(content), file, fset, lineLength, opts.tabLength)

	// Are there any changes?
	original := string(content)
	hasChanges := result != original

	// Are we being asked to write the resultant change back to the file?
	if opts.write {
		if hasChanges {
			return true, os.WriteFile(filename, []byte(result), 0o644)
		}
		return false, nil
	}

	// Or are we being asked to print a unified diff what would be changed?
	if opts.diff {
		if hasChanges {
			unified := difflib.UnifiedDiff{
				A:        difflib.SplitLines(original),
				B:        difflib.SplitLines(result),
				FromFile: filename,
				ToFile:   filename,
				Context:  3,
			}
			diffText, err := difflib.GetUnifiedDiffString(unified)
			if err != nil {
				return hasChanges, err
			}
			fmt.Print(diffText)
		}
		return hasChanges, nil
	}

	// Or are we being asked to print files that have changes?
	if opts.list {
		if hasChanges {
			fmt.Println(filename)
		}
		return hasChanges, nil
	}

	// Hey, if we get here, we'll just print what we would do
	fmt.Print(result)

	return hasChanges, nil
}
