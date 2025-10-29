package main

import (
	"encoding/json"
	"fmt"
	"go/ast"
	"go/token"
	"log"
	"os"
	"os/exec"
	"strings"

	"golang.org/x/tools/go/packages"
)

type GraphOutput struct {
	Commit    string   `json:"commit"`
	TimeStamp string   `json:"timestamp"`
	Packages  []string `json:"packages"`
	Channels  []string `json:"channels"`
	// This may only contain two strings each.
	// The first element notifies the second.
	Notifies [][]string `json:"notifies"`
}

func main() {
	if len(os.Args) != 5 {
		log.Fatal("Please provide four arguments: the module root path, the notify service package path, the name of the function that registers a notifier and the path of the notifier struct")
		return
	}
	module_root := os.Args[1]
	notify_service_pkg_paths := strings.Split(os.Args[2], ",")
	register_notify_func_names := strings.Split(os.Args[3], ",")
	notifier_interface_paths := strings.Split(os.Args[4], ",")

	notify_service_pkg_path_set := map[string]bool{}
	for _, item := range notify_service_pkg_paths {
		notify_service_pkg_path_set[item] = true
	}
	register_notify_func_name_set := map[string]bool{}
	for _, item := range register_notify_func_names {
		register_notify_func_name_set[item] = true
	}
	notifier_interface_path_set := map[string]bool{}
	for _, item := range notifier_interface_paths {
		notifier_interface_path_set[item] = true
	}

	// We use the golang.org/x/tools/go/packages package to parse not just a single file but the entire module.
	cfg := &packages.Config{
		Mode: packages.NeedName | packages.NeedSyntax | packages.NeedTypesInfo,
		Dir:  module_root,
	}

	log.Println("Loading packages...")
	// Match all packages inside the module root
	pkgs, err := packages.Load(cfg, "./...")
	if err != nil {
		log.Fatal("Failed to load packages", err)
	}

	log.Println("Analyzing packages...")
	out_packages := map[string]bool{}
	out_channels := map[string]bool{}
	out_notifies := [][]string{}
	for _, pkg := range pkgs {
		// skip the notify package itself
		if notify_service_pkg_path_set[pkg.PkgPath] {
			continue
		}

		// We loop over all nodes in the package twice:
		// In the first pass we find all notification channels the package calls and the name of the packages local notifier.
		// We assume that every package has no or a single notifier.
		// Once we know the name of the struct notifier_struct is not nil anymore.
		var notifier_struct *string = nil

		for _, file := range pkg.Syntax {
			ast.Inspect(file, func(node ast.Node) bool {
				switch n := node.(type) {
				// Is this a call a notifier channel?
				case *ast.CallExpr:
					// Is this a call like `something.someFunction()`?
					if f, ok := n.Fun.(*ast.SelectorExpr); ok &&
						// Somehow this can be nil in
						// 16dbc0efd350cdc15760c2e40346c1e9fbb0bd01 works
						// 3a986d282fcb27a094a3e6e076e3bf9b0e6c09cd doesn't
						pkg.TypesInfo.Uses[f.Sel] != nil &&
						// Is this a call to a function from the notify package?
						pkg.TypesInfo.Uses[f.Sel].Pkg() != nil && notify_service_pkg_path_set[pkg.TypesInfo.Uses[f.Sel].Pkg().Path()] &&
						// The notify package has two types of functions:
						// Calls to notify channels or registering a new notifier.
						// We filter the notifier register calls out.
						!register_notify_func_name_set[pkg.TypesInfo.Uses[f.Sel].Name()] &&
						// Only exported functions can be channels.
						f.Sel.IsExported() {

						// log.Println(pkg.PkgPath, "notifies", f.Sel)
						out_packages[pkg.PkgPath] = true
						out_channels[f.Sel.String()] = true
						out_notifies = append(out_notifies, []string{pkg.PkgPath, f.Sel.String()})
					}

				// Is this a declaration?
				case *ast.GenDecl:
					// Is this a var declaration?
					if n.Tok == token.VAR {
						// We only allow one ValueSpec to exist.
						// We check that later.
						for _, spec := range n.Specs {
							// Only look at ValueSpec
							if value_spec, ok := spec.(*ast.ValueSpec); ok &&
								// Is this a declaration that declares something a notifier struct?
								pkg.TypesInfo.TypeOf(value_spec.Type) != nil && notifier_interface_path_set[pkg.TypesInfo.TypeOf(value_spec.Type).String()] {
								if len(value_spec.Values) != 1 {
									log.Fatal("can't have two values in interface declaration")
								}
								if len(n.Specs) != 1 {
									log.Fatal("can't have two specs in interface declaration")
								}
								if notifier_struct != nil {
									log.Fatal("can't have more than one notifier in a package")
								}
								notifier_struct_copy := pkg.TypesInfo.TypeOf(value_spec.Values[0]).String()
								notifier_struct = &notifier_struct_copy
							}
						}
					}
				}
				return true
			})
		}

		// Some packages don't declare a notfier.
		if notifier_struct == nil {
			continue
		}

		for _, file := range pkg.Syntax {
			ast.Inspect(file, func(node ast.Node) bool {
				switch n := node.(type) {
				// Is this a function?
				case *ast.FuncDecl:
					// Is this a method for the notifier struct of this package?
					if n.Recv != nil && len(n.Recv.List) == 1 && pkg.TypesInfo.TypeOf(n.Recv.List[0].Type).String() == *notifier_struct &&
						// Only exported functions can be channels.
						n.Name.IsExported() {

						// log.Println(pkg.PkgPath, "listenes to", n.Name.String())
						out_packages[pkg.PkgPath] = true
						out_channels[n.Name.String()] = true
						out_notifies = append(out_notifies, []string{n.Name.String(), pkg.PkgPath})
					}
				}
				return true
			})
		}
	}

	log.Println("Getting Git Stats...")
	// get git stats
	commit_cmd := exec.Command("git", "show", "--no-patch", "--format=%H", "HEAD")
	commit_cmd.Dir = module_root
	commit_stdout, err := commit_cmd.Output()
	if err != nil {
		log.Fatal(err)
	}
	timestamp_cmd := exec.Command("git", "show", "--no-patch", "--format=%at", "HEAD")
	timestamp_cmd.Dir = module_root
	timestamp_stdout, err := timestamp_cmd.Output()
	if err != nil {
		log.Fatal(err)
	}

	log.Println("Producing Output...")
	// print output as json
	graph_out := GraphOutput{
		Commit:    strings.Trim(string(commit_stdout), "\n\t "),
		TimeStamp: strings.Trim(string(timestamp_stdout), "\n\t "),
		Packages:  []string{},
		Channels:  []string{},
		Notifies:  [][]string{},
	}
	graph_out.Notifies = out_notifies
	for pkg := range out_packages {
		graph_out.Packages = append(graph_out.Packages, pkg)
	}
	for channel := range out_channels {
		graph_out.Channels = append(graph_out.Channels, channel)
	}
	if len(graph_out.Channels) == 0 || len(graph_out.Packages) == 0 {
		log.Fatal("failed to find any channels or packages")
	}

	json_data, err := json.Marshal(graph_out)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(string(json_data))
}
