package main

import (
	"go/ast"
	"go/token"
	"log"
	"os"

	"golang.org/x/tools/go/packages"
)

func main() {
	if len(os.Args) != 5 {
		log.Fatal("Please provide four arguments.")
		return
	}
	module_root := os.Args[1]
	notify_service_pkg_path := os.Args[2]
	register_notify_func_name := os.Args[3]
	notifier_interface_path := os.Args[4]

	cfg := &packages.Config{
		Mode: packages.NeedName | packages.NeedFiles | packages.NeedSyntax | packages.NeedTypes | packages.NeedTypesInfo | packages.NeedImports,
		Dir:  module_root,
	}

	// match any package as a path
	pkgs, err := packages.Load(cfg, "./...")
	if err != nil {
		log.Fatal("Failed to load packages")
	}
	for _, pkg := range pkgs {
		// log.Println("Analyzing Package: ", pkg.PkgPath)
		var notifier_struct *string = nil

		for _, file := range pkg.Syntax {
			ast.Inspect(file, func(node ast.Node) bool {
				switch n := node.(type) {
				case *ast.CallExpr:
					switch f := n.Fun.(type) {
					case *ast.SelectorExpr:
						if pkg.TypesInfo.Uses[f.Sel].Pkg() != nil && pkg.TypesInfo.Uses[f.Sel].Pkg().Path() == notify_service_pkg_path {
							if pkg.TypesInfo.Uses[f.Sel].Name() == register_notify_func_name {
								// skip
								// log.Println(pkg.PkgPath, ": ", n.Args[0], pkg.TypesInfo.TypeOf(n.Args[0]).Underlying())
							} else {
								log.Println(pkg.PkgPath, "notifies", f.Sel)
							}
						}
					}

				case *ast.GenDecl:
					if n.Tok == token.VAR {
						for _, spec := range n.Specs {
							if value_spec, ok := spec.(*ast.ValueSpec); ok {
								if pkg.TypesInfo.TypeOf(value_spec.Type) != nil && pkg.TypesInfo.TypeOf(value_spec.Type).String() == notifier_interface_path {
									if len(value_spec.Values) != 1 {
										log.Fatal("can't have two values in interface declaration")
									}
									if notifier_struct != nil {
										log.Fatal("can't have more than one notifier in a package")
									}
									notifier_struct_copy := pkg.TypesInfo.TypeOf(value_spec.Values[0]).String()
									notifier_struct = &notifier_struct_copy
									// log.Println(notifier_struct)
								}
							}
						}
						// log.Println(pkg.TypesInfo.TypeOf(n.Specs[0]))
					}
				}
				return true
			})
		}

		if notifier_struct == nil {
			continue
		}

		for _, file := range pkg.Syntax {
			ast.Inspect(file, func(node ast.Node) bool {
				switch n := node.(type) {
				case *ast.FuncDecl:
					if n.Recv != nil && len(n.Recv.List) == 1 && pkg.TypesInfo.TypeOf(n.Recv.List[0].Type).String() == *notifier_struct {
						log.Println(pkg.PkgPath, "listenes to", n.Name.String())
					}
				}
				return true
			})
		}
	}
}
