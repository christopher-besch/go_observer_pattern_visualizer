# Go Observer Pattern Visualizer

This script creates a visualization for Forgejo's pub-sub pattern.
I wrote an article about how this works: [The History of Forgejo's Pub-Sub Pattern](https://chris-besch.com/articles/forgejo_pub_sub_pattern_history).
These tools work with all Go projects that use the same pattern:

```go
// Define the notifier.
type actionsNotifier struct {
	notify_service.NullNotifier
}

// Ensure that this struct fulfills the Notifier interface.
var _ notify_service.Notifier = &actionsNotifier{}

// Declare functions for all topics the package is interested in.
func (n *actionsNotifier) NewIssue(/* --snip-- */) {
// --snip--

// Tell the broker there's a new notifier to be notified.
notify_service.RegisterNotifier(&actionsNotifier{})

// send a message to some topic
notify_service.PullReviewDismiss(ctx, doer, review, comment)
```

Use it like this: `go run . ~/forgejo/ forgejo.org/services/notify,code.gitea.io/gitea/services/notify,code.gitea.io/gitea/modules/notification/base RegisterNotifier forgejo.org/services/notify.Notifier,code.gitea.io/gitea/services/notify.Notifier,code.gitea.io/gitea/modules/notification/base.Notifier > out.json`
