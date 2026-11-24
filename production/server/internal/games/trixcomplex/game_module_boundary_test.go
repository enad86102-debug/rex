package trixcomplex

import (
	"go/parser"
	"go/token"
	"os"
	"strconv"
	"strings"
	"testing"
)

// No game engine may import another game's engine, even indirectly through
// "convenient" code reuse. Shared cards and matchcore are game-neutral.
func TestTrixComplexSourceDoesNotImportAnotherGame(t *testing.T) {
	files, err := os.ReadDir(".")
	if err != nil {
		t.Fatal(err)
	}
	checked := 0
	for _, file := range files {
		if file.IsDir() || !strings.HasSuffix(file.Name(), ".go") {
			continue
		}
		parsed, err := parser.ParseFile(token.NewFileSet(), file.Name(), nil, parser.ImportsOnly)
		if err != nil {
			t.Fatalf("cannot examine import boundaries in %s: %v", file.Name(), err)
		}
		checked++
		for _, item := range parsed.Imports {
			path, err := strconv.Unquote(item.Path.Value)
			if err != nil {
				t.Fatal(err)
			}
			if strings.Contains(path, "/internal/games/") &&
				!strings.Contains(path, "/internal/games/trixcomplex") {
				t.Fatalf("game engine %s illegally imports another game's code: %s", file.Name(), path)
			}
		}
	}
	if checked < 5 {
		t.Fatal("game import-boundary test was not run against actual source files")
	}
}
