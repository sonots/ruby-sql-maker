#!/bin/bash

ruby scripts/gen_doc.rb && \
  git checkout gh-pages && \
  cp -a doc/* .
