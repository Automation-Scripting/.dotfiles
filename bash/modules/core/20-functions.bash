lock() {
    chmod -R a-w "$1"
    echo "Locked: $1"
}

unlock() {
    chmod -R u+w "$1"
    echo "Unlocked: $1"
}