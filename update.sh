#!/bin/sh
ls -1 . | grep -v -E "content|other|update.sh|CNAME" | xargs rm -rf && cyrax content && mv content/_build/* .

