#!/bin/bash
set -euo pipefail
IFS=$' \n\t'
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

while true; do
    commit_name="$(git show --no-patch '--format=%at_%H' HEAD)"
    echo "$commit_name"

    if git diff HEAD HEAD~ --name-only | grep -P '.go$' > /dev/null; then
        /home/chris/go_observer_pattern_visualizer/go_observer_pattern_visualizer /home/chris/forgejo/ forgejo.org/services/notify,code.gitea.io/gitea/services/notify,code.gitea.io/gitea/modules/notification/base RegisterNotifier forgejo.org/services/notify.Notifier,code.gitea.io/gitea/services/notify.Notifier,code.gitea.io/gitea/modules/notification/base.Notifier > ../out/"$commit_name.json"
    else
        echo "skipping as this commit doesn't change any .go files"
    fi

    # We need to download the old tools.
    go install "golang.org/dl/go$(cat go.mod | grep -P '^go ' | cut -d ' ' -f2)@latest"
    "go$(cat go.mod | grep -P '^go ' | cut -d ' ' -f2)" download
    # ed1d95c55dfa91d1c9a486bfb8e00375d4038e29 repairs something that makes loading fail otherwise, solution:
    "go$(cat go.mod | grep -P '^go ' | cut -d ' ' -f2)" mod tidy

    # Apparently the go dir can grow to absurd sizes; prevent that.
    if [ "$(du -bs /root/go | cut -f1)" -ge "1346239233" ]; then
            rm -vr /root/go
    fi

    git restore go.mod
    git checkout HEAD~
done
