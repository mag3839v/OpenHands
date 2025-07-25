#!/bin/bash

echo "Running OpenHands pre-commit hook..."
echo "This hook runs 'make lint' to ensure code quality before committing."

# Store the exit code to return at the end
# This allows us to be additive to existing pre-commit hooks
EXIT_CODE=0

# Run make lint to check both frontend and backend code
echo "Running linting checks with 'make lint'..."
make lint
if [ $? -ne 0 ]; then
    echo "Linting failed. Please fix the issues before committing."
    EXIT_CODE=1
else
    echo "Linting checks passed!"
fi

# Check if frontend directory has changed
frontend_changes=$(git diff --cached --name-only | grep "^frontend/")
if [ -n "$frontend_changes" ]; then
    echo "Frontend changes detected. Running additional frontend checks..."

    # Check if frontend directory exists
    if [ -d "frontend" ]; then
        # Change to frontend directory
        cd frontend || exit 1

        # Run build
        echo "Running npm build..."
        npm run build
        if [ $? -ne 0 ]; then
            echo "Frontend build failed. Please fix the issues before committing."
            EXIT_CODE=1
        fi

        # Run tests
        echo "Running npm test..."
        npm test
        if [ $? -ne 0 ]; then
            echo "Frontend tests failed. Please fix the failing tests before committing."
            EXIT_CODE=1
        fi

        # Return to the original directory
        cd ..

        if [ $EXIT_CODE -eq 0 ]; then
            echo "Frontend checks passed!"
        fi
    else
        echo "Frontend directory not found. Skipping frontend checks."
    fi
else
    echo "No frontend changes detected. Skipping additional frontend checks."
fi

# Run any existing pre-commit hooks that might have been installed by the user
# This makes our hook additive rather than replacing existing hooks
if [ -f ".git/hooks/pre-commit.local" ]; then
    echo "Running existing pre-commit hooks..."
    bash .git/hooks/pre-commit.local
    if [ $? -ne 0 ]; then
        echo "Existing pre-commit hooks failed."
        EXIT_CODE=1
    fi
fi

if [ $EXIT_CODE -eq 0 ]; then
    echo "All pre-commit checks passed!"
else
    echo "Some pre-commit checks failed. Please fix the issues before committing."
fi

exit $EXIT_CODE
