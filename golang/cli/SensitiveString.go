package main

import (
	"fmt"
	"os"

	sensitivestring "github.com/earlye/sensitive-strings/golang"
)

func main() {
	for _, arg := range os.Args[1:] {
		ss := sensitivestring.New(arg)
		fmt.Println(ss.String())
	}
}
