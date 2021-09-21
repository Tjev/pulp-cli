#!/bin/bash

# shellcheck source=tests/scripts/config.source
. "$(dirname "$(dirname "$(realpath "$0")")")"/config.source

pulp debug has-plugin --name "rpm" || exit 3

cleanup() {
  pulp rpm distribution destroy --name "cli_test_rpm_distro" || true
  pulp rpm repository destroy --name "cli_test_rpm_repository" || true
  pulp rpm remote destroy --name "cli_test_rpm_remote" || true
}
trap cleanup EXIT

# Test rpm package upload

wget https://fixtures.pulpproject.org/rpm-modules-static-context/bear-4.1-1.noarch.rpm
expect_succ pulp rpm content upload --file "bear-4.1-1.noarch.rpm" --relative-path "bear-4.1-1.noarch.rpm"
PACKAGE_HREF=$(echo "$OUTPUT" | jq -r .pulp_href)
expect_succ pulp rpm content show 

expect_succ pulp rpm remote create --name "cli_test_rpm_remote" --url "$RPM_REMOTE_URL"
expect_succ pulp rpm remote show --name "cli_test_rpm_remote"
expect_succ pulp rpm repository update --name "cli_test_rpm_repository" --description ""
expect_succ pulp rpm repository create --name "cli_test_rpm_repository"
expect_succ pulp rpm repository show --name "cli_test_rpm_repository"

expect_succ pulp rpm repository content modify \
--repository "cli_test_rpm_repository" \
--add-content "[{\"pulp_href\": \"$PACKAGE_HREF\"}]"

expect_succ pulp rpm repository content list --repository "cli_test_rpm_repository"
test "(echo \"$OUTPUT\" | jq -r '.pulp_href')" = "$PACKAGE_HREF"

expect_succ pulp rpm publication create --repository "cli_test_rpm_repository"
PUBLICATION_HREF=$(echo "$OUTPUT" | jq -r .pulp_href)

expect_succ pulp rpm distribution create --name "cli_test_rpm_distro" \
  --base-path "cli_test_rpm_distro" \
  --publication "$PUBLICATION_HREF"

expect_succ pulp rpm repository content modify \
--repository "cli_test_rpm_repository" \
--remove-content "[{\"pulp_href\": \"$PACKAGE_HREF\"}]"
expect_succ pulp rpm publication destroy --href "$PUBLICATION_HREF"
expect_succ pulp rpm repository destroy --name "cli_test_rpm_repository"
expect_succ pulp rpm remote destroy --name "cli_test_rpm_remote"