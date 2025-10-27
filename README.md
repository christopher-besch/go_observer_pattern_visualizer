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

Use it like this: `go run . ~/forgejo/ forgejo.org/services/notify RegisterNotifier forgejo.org/services/notify.Notifier`
