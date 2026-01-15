package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestWalkPath(t *testing.T) {
	// Create a temporary directory structure
	tmpDir := t.TempDir()

	// Create test files
	mainGo := filepath.Join(tmpDir, "main.go")
	visibleDir := filepath.Join(tmpDir, "visible")
	hiddenDir := filepath.Join(tmpDir, ".hidden")

	os.Mkdir(visibleDir, 0o755)
	os.Mkdir(hiddenDir, 0o755)

	mainContent := `package main

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func Main() {}
`
	visibleContent := `package visible

// This is another very long comment that exceeds the default line length of 78 characters and should be wrapped
func Visible() {}
`
	hiddenContent := `package hidden

// This is a hidden directory comment that exceeds the default line length of 78 characters and should be wrapped
func Hidden() {}
`

	os.WriteFile(mainGo, []byte(mainContent), 0o644)
	os.WriteFile(filepath.Join(visibleDir, "visible.go"), []byte(visibleContent), 0o644)
	os.WriteFile(filepath.Join(hiddenDir, "hidden.go"), []byte(hiddenContent), 0o644)

	tests := []struct {
		name           string
		path           string
		expectPackages []string // packages we expect to see in output
	}{
		{
			name:           "single file",
			path:           mainGo,
			expectPackages: []string{"package main"},
		},
		{
			name:           "directory includes hidden",
			path:           tmpDir,
			expectPackages: []string{"package main", "package visible", "package hidden"},
		},
		{
			name:           "ellipsis pattern skips hidden",
			path:           tmpDir + "/...",
			expectPackages: []string{"package main", "package visible"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Capture output by writing to a temporary file
			outputFile := filepath.Join(t.TempDir(), "output.txt")
			oldStdout := os.Stdout
			f, err := os.Create(outputFile)
			assert.NoError(t, err, "failed to create output file")
			os.Stdout = f

			// Process the path
			_, err = walkPath(tt.path, 78, options{})

			// Restore stdout
			f.Close()
			os.Stdout = oldStdout

			assert.NoError(t, err, "walkPath() failed")

			// Read the output
			output, err := os.ReadFile(outputFile)
			assert.NoError(t, err, "failed to read output")

			outputStr := string(output)

			// Check that all expected packages are present
			for _, pkg := range tt.expectPackages {
				assert.Contains(t, outputStr, pkg, "expected package not found in output")
			}

			// For ellipsis pattern, verify hidden package is NOT present
			if strings.HasSuffix(tt.path, "/...") {
				assert.NotContains(t, outputStr, "package hidden",
					"ellipsis pattern should skip hidden directories")
			}
		})
	}
}

func TestWalkDirectory(t *testing.T) {
	tmpDir := t.TempDir()

	// Create nested directory structure
	subDir := filepath.Join(tmpDir, "subdir")
	hiddenDir := filepath.Join(tmpDir, ".git")

	os.Mkdir(subDir, 0o755)
	os.Mkdir(hiddenDir, 0o755)

	// Create Go files with comments that need reformatting
	rootContent := `package root

// This is a very long comment in root that exceeds the default line length of 78 characters and should be wrapped
func Root() {}
`
	subContent := `package sub

// This is a very long comment in sub that exceeds the default line length of 78 characters and should be wrapped
func Sub() {}
`
	gitContent := `package git

// This is a very long comment in git that exceeds the default line length of 78 characters and should be wrapped
func Git() {}
`
	os.WriteFile(filepath.Join(tmpDir, "root.go"), []byte(rootContent), 0o644)
	os.WriteFile(filepath.Join(subDir, "sub.go"), []byte(subContent), 0o644)
	os.WriteFile(filepath.Join(hiddenDir, "git.go"), []byte(gitContent), 0o644)

	// Create a non-Go file that should be skipped
	os.WriteFile(filepath.Join(tmpDir, "readme.txt"), []byte("not a go file"), 0o644)

	tests := []struct {
		name           string
		skipHidden     bool
		expectPackages []string
	}{
		{
			name:           "include hidden directories",
			skipHidden:     false,
			expectPackages: []string{"package root", "package sub", "package git"},
		},
		{
			name:           "skip hidden directories",
			skipHidden:     true,
			expectPackages: []string{"package root", "package sub"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Capture output
			outputFile := filepath.Join(t.TempDir(), "output.txt")
			oldStdout := os.Stdout
			f, err := os.Create(outputFile)
			assert.NoError(t, err, "failed to create output file")
			os.Stdout = f

			_, err = walkDirectory(tmpDir, 78, options{}, tt.skipHidden)

			f.Close()
			os.Stdout = oldStdout

			assert.NoError(t, err, "walkDirectory() failed")

			output, err := os.ReadFile(outputFile)
			assert.NoError(t, err, "failed to read output")

			outputStr := string(output)

			for _, pkg := range tt.expectPackages {
				assert.Contains(t, outputStr, pkg, "expected package not found")
			}

			// Verify hidden directory handling
			if tt.skipHidden {
				assert.NotContains(t, outputStr, "package git",
					"skipHidden=true should exclude hidden directories")
			}

			// Verify non-Go files are skipped
			assert.NotContains(t, outputStr, "not a go file", "non-Go files should be skipped")
		})
	}
}

func TestVisitFileWriteMode(t *testing.T) {
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test.go")

	original := `package test

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func Test() {}
`
	expected := `package test

// This is a very long comment that exceeds the default line length of 78
// characters and should be wrapped
func Test() {}
`

	os.WriteFile(testFile, []byte(original), 0o644)

	// Process with write mode
	changed, err := visitFile(testFile, 78, options{write: true})
	assert.NoError(t, err, "visitFile() failed")
	assert.True(t, changed, "visitFile() should detect changes")

	// Read the file back
	result, err := os.ReadFile(testFile)
	assert.NoError(t, err, "failed to read file")

	assert.Equal(t, expected, string(result), "visitFile() write mode output mismatch")
}

func TestNoChangesNeeded(t *testing.T) {
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test.go")

	alreadyFormatted := `package test

// This is a short comment
func Test() {}
`

	os.WriteFile(testFile, []byte(alreadyFormatted), 0o644)

	// Process file that doesn't need changes
	changed, err := visitFile(testFile, 78, options{})
	assert.NoError(t, err, "visitFile() failed")
	assert.False(t, changed, "visitFile() should not detect changes")

	// Verify file wasn't modified
	result, err := os.ReadFile(testFile)
	assert.NoError(t, err, "failed to read file")
	assert.Equal(t, alreadyFormatted, string(result), "file should remain unchanged")
}

func TestDiffMode(t *testing.T) {
	tmpDir := t.TempDir()

	t.Run("diff mode with changes", func(t *testing.T) {
		testFile := filepath.Join(tmpDir, "needs_formatting.go")
		needsFormatting := `package test

// This is a very long comment that exceeds the default line length of 78 characters and should be wrapped
func Test() {}
`
		os.WriteFile(testFile, []byte(needsFormatting), 0o644)

		// Capture output
		outputFile := filepath.Join(t.TempDir(), "output.txt")
		oldStdout := os.Stdout
		f, err := os.Create(outputFile)
		assert.NoError(t, err)
		os.Stdout = f

		// Process with diff mode
		changed, err := visitFile(testFile, 78, options{diff: true})

		f.Close()
		os.Stdout = oldStdout

		assert.NoError(t, err, "visitFile() failed")
		assert.True(t, changed, "should detect changes")

		// Should print output when changes are needed
		output, _ := os.ReadFile(outputFile)
		assert.Contains(t, string(output), "package test", "should print formatted output in diff mode when changes needed")
	})

	t.Run("diff mode without changes", func(t *testing.T) {
		testFile := filepath.Join(tmpDir, "already_formatted.go")
		alreadyFormatted := `package test

// Short comment
func Test() {}
`
		os.WriteFile(testFile, []byte(alreadyFormatted), 0o644)

		// Capture output
		outputFile := filepath.Join(t.TempDir(), "output.txt")
		oldStdout := os.Stdout
		f, err := os.Create(outputFile)
		assert.NoError(t, err)
		os.Stdout = f

		// Process with diff mode
		changed, err := visitFile(testFile, 78, options{diff: true})

		f.Close()
		os.Stdout = oldStdout

		assert.NoError(t, err, "visitFile() failed")
		assert.False(t, changed, "should not detect changes")

		// Should NOT print output when no changes are needed
		output, _ := os.ReadFile(outputFile)
		assert.Empty(t, string(output), "should not print in diff mode when no changes needed")
	})

	t.Run("normal mode always prints", func(t *testing.T) {
		testFile := filepath.Join(tmpDir, "normal_mode.go")
		alreadyFormatted := `package test

// Short comment
func Test() {}
`
		os.WriteFile(testFile, []byte(alreadyFormatted), 0o644)

		// Capture output
		outputFile := filepath.Join(t.TempDir(), "output.txt")
		oldStdout := os.Stdout
		f, err := os.Create(outputFile)
		assert.NoError(t, err)
		os.Stdout = f

		// Process with normal mode (diff=false)
		changed, err := visitFile(testFile, 78, options{})

		f.Close()
		os.Stdout = oldStdout

		assert.NoError(t, err, "visitFile() failed")
		assert.False(t, changed, "should not detect changes")

		// Should print output even when no changes are needed
		output, _ := os.ReadFile(outputFile)
		assert.Contains(t, string(output), "package test", "should always print in normal mode")
	})
}
