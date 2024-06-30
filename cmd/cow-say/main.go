package main

import (
	"fmt"
	cowsay "github.com/Code-Hex/Neo-cowsay/v2"
	"os"
)

func main() {
	var text string

	if len(os.Args) > 1 {
		text = os.Args[1]
	} else {
		text = "Next time, add some text."
	}

	say, err := cowsay.Say(
		text,
		cowsay.Random(),
		cowsay.BallonWidth(40),
	)

	if err != nil {
		panic(err)
	}
	fmt.Println(say)
}
