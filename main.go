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
		log.Fatal("Please provide four arguments: the module root path, the notify service package path, the name of the function that registers a notifier and the path of the notifier struct")
		return
	}
	module_root := os.Args[1]
	notify_service_pkg_path := os.Args[2]
	register_notify_func_name := os.Args[3]
	notifier_interface_path := os.Args[4]

	// We use the golang.org/x/tools/go/packages package to parse not just a single file but the entire module.
	cfg := &packages.Config{
		Mode: packages.NeedName | packages.NeedFiles | packages.NeedSyntax | packages.NeedTypes | packages.NeedTypesInfo | packages.NeedImports,
		Dir:  module_root,
	}

	// Match all packages inside the module root
	pkgs, err := packages.Load(cfg, "./...")
	if err != nil {
		log.Fatal("Failed to load packages")
	}
	for _, pkg := range pkgs {
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
						// Is this a call to a function from the notify package?
						pkg.TypesInfo.Uses[f.Sel].Pkg() != nil && pkg.TypesInfo.Uses[f.Sel].Pkg().Path() == notify_service_pkg_path &&
						// The notify package has two types of functions:
						// Calls to notify channels or registering a new notifier.
						// We filter the notifier register calls out.
						pkg.TypesInfo.Uses[f.Sel].Name() != register_notify_func_name {
						log.Println(pkg.PkgPath, "notifies", f.Sel)
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
								pkg.TypesInfo.TypeOf(value_spec.Type) != nil && pkg.TypesInfo.TypeOf(value_spec.Type).String() == notifier_interface_path {
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
					if n.Recv != nil && len(n.Recv.List) == 1 && pkg.TypesInfo.TypeOf(n.Recv.List[0].Type).String() == *notifier_struct {
						log.Println(pkg.PkgPath, "listenes to", n.Name.String())
					}
				}
				return true
			})
		}
	}
}
