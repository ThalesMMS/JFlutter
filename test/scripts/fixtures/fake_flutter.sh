#!/bin/bash

case "${1:-}" in
    --version)
        echo "Flutter fake 1.0"
        exit 0
        ;;
    pub)
        [ "${2:-}" = "get" ] || exit 64
        exit "${FAKE_PUB_EXIT:-0}"
        ;;
    analyze)
        exit "${FAKE_ANALYZE_EXIT:-0}"
        ;;
    test)
        exit "${FAKE_TEST_EXIT:-0}"
        ;;
    *)
        exit 64
        ;;
esac
