package main

import (
	"flag"
	"fmt"
	"os"
)

type options struct {
	write      bool
	diff       bool
	list       bool
	tabLength  int
	lineLength int
}

func main() {
	flag.Usage = func() {
		fmt.Println("usage: gocomments [flags] [paths...]")
		fmt.Println("  gocomments reformat's comments in Go files. By default, it only prints")
		fmt.Println("  the reformatted contents of each file.")
		fmt.Println()
		fmt.Println("flags:")
		flag.PrintDefaults()
	}

	lineLength := flag.Int("llen", 78, "maximum line length for comments")
	tabLength := flag.Int("tlen", 4, "number of spaces that tabs count for")
	write := flag.Bool("w", false, "write changes back to source files instead of stdout")
	diff := flag.Bool("d", false, "display unified diffs of changes rather than whole files")
	list := flag.Bool("l", false, "list files whose formatting would change")

	flag.Parse()

	paths := flag.Args()

	opts := options{
		write:      *write,
		diff:       *diff,
		list:       *list,
		tabLength:  *tabLength,
		lineLength: *lineLength,
	}

	// If no paths provided, check if stdin has data
	if len(paths) == 0 {
		stat, err := os.Stdin.Stat()
		if err != nil {
			fmt.Fprintf(os.Stderr, "error checking stdin: %v\n", err)
			os.Exit(1)
		}

		// If stdin is a pipe or file (not a terminal), read from it
		if (stat.Mode() & os.ModeCharDevice) == 0 {
			if err := formatStdin(opts); err != nil {
				fmt.Fprintf(os.Stderr, "error processing stdin: %v\n", err)
				os.Exit(1)
			}
			return
		}

		// No paths and no stdin data, show usage
		flag.Usage()
		os.Exit(1)
	}

	hasChanges := false
	for _, path := range paths {
		changed, err := walkPath(path, opts)
		if err != nil {
			fmt.Fprintf(os.Stderr, "error walking %s: %v\n", path, err)
			os.Exit(1)
		}
		if changed {
			hasChanges = true
		}
	}

	if hasChanges {
		os.Exit(1)
	}
}
