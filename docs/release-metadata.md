# Release Metadata

Every release created by the deployment script contains a release-metadata.json file.

The metadata records the identity and lifecycle state of the release.

Fields:

schema_version
release_id
created_at
updated_at
application
source_commit
artifact
artifact_sha256
deployed_by
previous_release
status
validation
rollback

A successful release is only marked as:

status = active
validation = passed

after post-deployment validation succeeds.

The artifact_sha256 field records the SHA-256 checksum of the original deployment archive.

SOURCE_COMMIT can be provided by CI:

SOURCE_COMMIT=<git-sha>

If SOURCE_COMMIT is not provided, the value is recorded as unknown.

Typical status values:

preparing
prepared
activating
active
inactive
failed
rollback_failed

Typical validation values:

pending
not_started
passed
failed

Typical rollback values:

not_required
pending
successful
failed
activated
unavailable

Failed releases remain recorded as failed even when automatic rollback successfully restores the previous release.