#!/bin/bash

# GitHub Workflow Helper Script
# Handles authentication-required GitHub operations outside sandbox
# Usage: ./.github/scripts/github-workflow.sh [commit|push|pr|merge|full]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if on master branch
check_not_on_master() {
    local branch=$(git branch --show-current)
    if [ "$branch" = "master" ] || [ "$branch" = "main" ]; then
        print_error "Cannot commit directly to master/main branch"
        print_info "Create a feature branch first: git checkout -b feature/your-feature-name"
        exit 1
    fi
}

# Create feature branch
create_branch() {
    local branch_name="$1"
    
    if [ -z "$branch_name" ]; then
        read -p "Enter feature branch name (e.g., feature/my-feature): " branch_name
    fi
    
    git checkout -b "$branch_name"
    print_success "Created and switched to branch: $branch_name"
}

# Commit changes
commit_changes() {
    check_not_on_master
    
    git add -A
    
    local changes=$(git status --short | wc -l)
    if [ "$changes" -eq 0 ]; then
        print_warning "No changes to commit"
        return 0
    fi
    
    print_info "Files changed: $changes"
    
    read -p "Enter commit message: " commit_msg
    
    if [ -z "$commit_msg" ]; then
        print_error "Commit message cannot be empty"
        exit 1
    fi
    
    git commit --no-verify -m "$commit_msg"
    print_success "Changes committed"
}

# Push to GitHub
push_to_github() {
    check_not_on_master
    
    local branch=$(git branch --show-current)
    
    print_info "Pushing branch: $branch"
    
    # Check if remote branch exists
    if git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
        git push
        print_success "Pushed to existing remote branch"
    else
        git push -u origin "$branch"
        print_success "Pushed and set up tracking for new branch"
    fi
}

# Create pull request
create_pr() {
    check_not_on_master
    
    local branch=$(git branch --show-current)
    
    # Check if already pushed
    if ! git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
        print_warning "Branch not pushed to remote. Pushing first..."
        push_to_github
    fi
    
    # Check gh authentication
    if ! gh auth status >/dev/null 2>&1; then
        print_error "GitHub CLI not authenticated"
        print_info "Run: gh auth login"
        exit 1
    fi
    
    read -p "Enter PR title: " pr_title
    read -p "Enter PR description (optional): " pr_description
    
    if [ -z "$pr_title" ]; then
        pr_title="$branch"
    fi
    
    if [ -z "$pr_description" ]; then
        pr_description="Automated PR from $branch"
    fi
    
    local pr_url=$(gh pr create --title "$pr_title" --body "$pr_description" --base master)
    print_success "Pull request created: $pr_url"
    echo "$pr_url"
}

# Merge pull request
merge_pr() {
    # Get current PR number
    local pr_number=$(gh pr list --state open --json number --jq '.[0].number')
    
    if [ -z "$pr_number" ]; then
        print_error "No open pull request found"
        exit 1
    fi
    
    print_info "Merging PR #$pr_number"
    
    gh pr merge "$pr_number" --squash --delete-branch
    print_success "Pull request merged and branch deleted"
    
    # Switch back to master
    git checkout master
    git pull
    print_success "Switched to master and updated"
}

# Full workflow: commit -> push -> PR -> merge
full_workflow() {
    print_info "Starting full GitHub workflow..."
    
    # Check if on feature branch
    local branch=$(git branch --show-current)
    if [ "$branch" = "master" ] || [ "$branch" = "main" ]; then
        print_warning "Not on a feature branch"
        create_branch ""
    fi
    
    # Commit
    commit_changes
    
    # Push
    push_to_github
    
    # Create PR
    create_pr
    
    # Ask for merge
    read -p "Merge PR now? (y/n): " should_merge
    if [ "$should_merge" = "y" ]; then
        merge_pr
    else
        print_info "PR created but not merged. Merge manually when ready."
    fi
}

# Main script
case "${1:-help}" in
    commit)
        commit_changes
        ;;
    push)
        push_to_github
        ;;
    pr|pull-request)
        create_pr
        ;;
    merge)
        merge_pr
        ;;
    full|workflow)
        full_workflow
        ;;
    branch|create-branch)
        create_branch "$2"
        ;;
    help|--help|-h)
        echo "GitHub Workflow Helper Script"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  commit          - Stage and commit changes"
        echo "  push            - Push current branch to GitHub"
        echo "  pr              - Create pull request"
        echo "  merge           - Merge current PR"
        echo "  full            - Complete workflow (commit → push → PR → merge)"
        echo "  branch [name]   - Create new feature branch"
        echo "  help            - Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 full                           # Complete workflow"
        echo "  $0 branch feature/my-feature      # Create feature branch"
        echo "  $0 commit                         # Just commit"
        echo "  $0 push                           # Just push"
        echo ""
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac

