#!/bin/bash

# Git Helper - Wrapper for GitHub operations requiring authentication
# This script ensures commands run outside sandbox with proper credentials access
#
# Usage: ./git-helper.sh [command] [options]

exec ./.github/scripts/github-workflow.sh "$@"

