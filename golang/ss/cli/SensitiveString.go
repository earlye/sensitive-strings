package main

/// coverage-ignore
// This file is a CLI for the SensitiveString package.
// It is not covered by tests because it is a simple CLI.

import (
	"fmt"
	"os"

	ss "github.com/earlye/sensitive-strings/golang/ss"
)

func main() {
	for _, arg := range os.Args[1:] {
		sensitive := ss.New(arg)
		fmt.Println(sensitive.String())
	}
}
