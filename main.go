package main

import (
	"flag"
	"fmt"
	"os"
)

type options struct {
	write     bool
	diff      bool
	list      bool
	tabLength int
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
	if len(paths) == 0 {
		flag.Usage()
		os.Exit(1)
	}

	opts := options{
		write:     *write,
		diff:      *diff,
		list:      *list,
		tabLength: *tabLength,
	}

	hasChanges := false
	for _, path := range paths {
		changed, err := walkPath(path, *lineLength, opts)
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
