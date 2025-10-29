package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"sort"
	"strings"
)

// TODO: load from combined package
type GraphOutput struct {
	Commit    string   `json:"commit"`
	TimeStamp string   `json:"timestamp"`
	Packages  []string `json:"packages"`
	Channels  []string `json:"channels"`
	// This may only contain two strings each.
	// The first element notifies the second.
	Notifies [][]string `json:"notifies"`
}

// same as GraphOutput but without commit and timestamp
type PartGraphOutput struct {
	Packages []string `json:"packages"`
	Channels []string `json:"channels"`
	// This may only contain two strings each.
	// The first element notifies the second.
	Notifies [][]string `json:"notifies"`
}

func main() {
	if len(os.Args) != 2 {
		log.Fatal("Please provide one argument: the path to the directory where all the json files are and where the output should be placed")
		return
	}
	dir_path := os.Args[1]
	files, err := os.ReadDir(dir_path)
	if err != nil {
		log.Fatal(err)
	}
	full_output := []GraphOutput{}
	last_full_output_string := ""
	for _, file := range files {
		file_path := dir_path + "/" + file.Name()
		json_bytes, err := os.ReadFile(file_path)
		if err != nil {
			log.Fatal(err)
		}
		// somehow some json files are empty, skip them
		if len(json_bytes) == 0 {
			continue
		}
		// log.Println(file_path)
		// log.Println(len(json_bytes))
		var graph_output GraphOutput
		err = json.Unmarshal(json_bytes, &graph_output)
		if err != nil {
			log.Fatal(err)
		}
		// These are already unique.
		sort.Strings(graph_output.Packages)
		sort.Strings(graph_output.Channels)

		// convert to map -> unique
		to_sort_notifies_map := map[string]bool{}
		for _, notify := range graph_output.Notifies {
			comb_notify := notify[0] + "," + notify[1]
			to_sort_notifies_map[comb_notify] = true
		}
		// back to array
		to_sort_notifies := []string{}
		for notify := range to_sort_notifies_map {
			to_sort_notifies = append(to_sort_notifies, notify)
		}
		// sort
		sort.Strings(to_sort_notifies)
		// back to original data format
		graph_output.Notifies = [][]string{}
		for _, notify := range to_sort_notifies {
			graph_output.Notifies = append(graph_output.Notifies, strings.Split(notify, ","))
		}

		// place in output
		part_graph_output := PartGraphOutput{
			Packages: graph_output.Packages,
			Channels: graph_output.Channels,
			Notifies: graph_output.Notifies,
		}
		json_data, err := json.Marshal(part_graph_output)
		if err != nil {
			log.Fatal(err)
		}
		// Did something change since we last checked?
		// Always use the first element we find.
		if string(json_data) != last_full_output_string {
			full_output = append(full_output, graph_output)
			last_full_output_string = string(json_data)
		}
	}

	log.Printf("Number of outputs: %v\n", len(full_output))

	json_data, err := json.Marshal(full_output)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(string(json_data))
}
