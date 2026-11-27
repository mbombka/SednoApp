// Package prompts embeds the same prompt files used by the .NET model and benchmarks.
package prompts

import "embed"

//go:embed *.txt
var files embed.FS

func Read(mode, variant string) (string, error) {
	data, err := files.ReadFile(mode + "." + variant + ".txt")
	return string(data), err
}
