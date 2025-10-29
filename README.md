# Go Observer Pattern Visualizer

This script creates a visualization for Forgejo's observer pattern.
It works with all Go projects that use the same pattern.

```go
type actionsNotifier struct {
	notify_service.NullNotifier
}

var _ notify_service.Notifier = &actionsNotifier{}
```

```go
notify_service.RegisterNotifier(NewNotifier())
```

```go
func (n *actionsNotifier) NewIssue(ctx context.Context, issue *issues_model.Issue, _ []*user_model.User) {
// --snip--
```

```go
notify_service.PullReviewDismiss(ctx, doer, review, comment)
```

- rename from code.gitea.io/gitea to forgejo.org at 2457f5ff2293f69e6de5cc7d608dd210f6b8e27a
- move notifier from code.gitea.io/gitea/modules/notification/base.Notifier to code.gitea.io/gitea/services/notify.Notifier at 540bf9fa6d0d86297c9d575640798b718767bd9f
- move notifier from modules/notification/base/base.go to modules/notification/base/notifier.go at beab2df1227f9b7e556aa5716d94feb3a3e2088e (this doesn't require any change to this script)
- not using some queue for notifications any more but the observer pattern at ea619b39b2f2a3c1fb5ad28ebd4a269b2f822111

Use it like this: `go run . ~/forgejo/ forgejo.org/services/notify,code.gitea.io/gitea/services/notify,code.gitea.io/gitea/modules/notification/base RegisterNotifier forgejo.org/services/notify.Notifier,code.gitea.io/gitea/services/notify.Notifier,code.gitea.io/gitea/modules/notification/base.Notifier > out.json`

# This doesn't quite work yet
`for f in *; do cat $f | jq 'walk(if type == "array" then sort else . end)' --sort-keys > $f.2; done`
