package main

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
