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
func walkPath(path string, opts options) (bool, error) {
	// Recurse through all subdirectories of the provided path, but exclude
	// hidden directories found therein.
	if strings.HasSuffix(path, "/...") {
		baseDir := strings.TrimSuffix(path, "/...")
		return walkDirectory(baseDir, opts, true)
	}

	info, err := os.Stat(path)
	if err != nil {
		return false, err
	}

	if info.IsDir() {
		return walkDirectory(path, opts, false)
	}

	return visitFile(path, opts)
}

func walkDirectory(dir string, opts options, skipHidden bool) (bool, error) {
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
		changed, err := visitFile(path, opts)
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
// functions indicated in the provided options. The flags -l, -d, and -w can
// be combined and will execute in order:
//
// 1. list the file if it would change (-l)
// 2. print a diff of what would change (-d)
// 3. write the changes back to the file (-w)
//
// If none of these flags are set, print the reformatted file to stdout.
func visitFile(filename string, opts options) (bool, error) {
	content, err := os.ReadFile(filename)
	if err != nil {
		return false, err
	}

	fset := token.NewFileSet()
	file, err := parser.ParseFile(fset, filename, content, parser.ParseComments)
	if err != nil {
		return false, err
	}

	result := reformatComments(string(content), file, fset, opts)

	// Are there any changes?
	original := string(content)
	hasChanges := result != original

	// If any of the action flags are set, perform them in order
	if opts.list || opts.diff || opts.write {
		// First: list files that would change
		if opts.list && hasChanges {
			fmt.Println(filename)
		}

		// Second: print unified diff
		if opts.diff && hasChanges {
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

		// Third: write changes back to file
		if opts.write && hasChanges {
			if err := os.WriteFile(filename, []byte(result), 0o644); err != nil {
				return hasChanges, err
			}
		}

		return hasChanges, nil
	}

	// If no flags are set, print the reformatted file to stdout
	fmt.Print(result)

	return hasChanges, nil
}
