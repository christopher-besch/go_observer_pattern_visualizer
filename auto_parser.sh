#!/bin/bash
set -euo pipefail
IFS=$' \n\t'
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

while true; do
    commit_name="$(git show --no-patch '--format=%at_%H' HEAD)"
    echo "$commit_name"

    if git diff HEAD HEAD~ --name-only | grep -P '.go$' > /dev/null; then
        /home/chris/go_observer_pattern_visualizer/parser/parser \
            /home/chris/forgejo/ \
            forgejo.org/services/notify,code.gitea.io/gitea/services/notify,code.gitea.io/git/services/notify,code.gitea.io/gitea/modules/notification/base,code.gitea.io/git/modules/notification/base \
            RegisterNotifier \
            forgejo.org/services/notify.Notifier,code.gitea.io/gitea/services/notify.Notifier,code.gitea.io/git/services/notify.Notifier,code.gitea.io/gitea/modules/notification/base.Notifier,code.gitea.io/git/modules/notification/base.Notifier \
            > ../out/"$commit_name.json"
    else
        echo "skipping as this commit doesn't change any .go files"
    fi

    # The go.mod file was added in d77176912bccf1dc0ad93366df55f00fee23b498
    if [ ! -f go.mod ]; then
        # Use the modern go because the old one doesn't produce a go.mod that can be read without running go mod tidy afterwards.
        # Running go mod tidy afterwards doesn't work because of some strange error.
        # go: github.com/mvdan/xurls@v0.0.0-20181021210231-e52e821cbfe8: go.mod has post-v0 module path "mvdan.cc/xurls/v2" at revision e52e821cbfe8
        go mod init
    else
        # 5efd3630bc21d4b0ba6ff492d16d4c7e2814dd1f updates to xorm v0.7.4
        # Before `go mod tidy` didn't work.
        sed -i 's#github.com/go-xorm/xorm v0.7.3-0.20190620151208-f1b4f8368459#github.com/go-xorm/xorm v0.7.3#' go.mod

        # We need to download the old tools because at some point the new tools fail to work with the old repo. (somewhere at go1.12)
        go install "golang.org/dl/go$(cat go.mod | grep -P '^go ' | cut -d ' ' -f2)@latest"
        "go$(cat go.mod | grep -P '^go ' | cut -d ' ' -f2)" download
        # ed1d95c55dfa91d1c9a486bfb8e00375d4038e29 repairs something that makes loading fail otherwise, solution: go mod tidy
        "go$(cat go.mod | grep -P '^go ' | cut -d ' ' -f2)" mod tidy
    fi

    # Apparently the go dir can grow to absurd sizes; prevent that.
    if [ "$(du -bs /root/go | cut -f1)" -ge "1346239233" ]; then
            rm -vr /root/go
    fi

    git restore go.mod go.sum
    git checkout HEAD~
done
